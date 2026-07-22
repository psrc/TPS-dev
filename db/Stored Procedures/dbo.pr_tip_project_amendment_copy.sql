SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2026-05-05
-- Description: Copies a pending project from one amendment into another
--              non-posted amendment. Unlike pr_tip_project_amendment_move
--              (which simply rebases the existing ProjectAmendment row to a
--              new AmendmentId), this procedure leaves the source untouched
--              and duplicates the entire pending graph under a new
--              ProjectAmendmentId in the target amendment.
--
--              The copy sources data from the *_Pending tables (carrying the
--              user's unposted edits), not from the base tip.Project tables.
--
-- Parameters:
--    @UserId                       (UNIQUEIDENTIFIER) - Acting user (audit trail)
--    @SourceAmendmentId            (UNIQUEIDENTIFIER) - Amendment the source pending project lives in
--    @SourceProjectPendingId       (UNIQUEIDENTIFIER) - Project_Pending.Id being copied
--    @TargetAmendmentId            (UNIQUEIDENTIFIER) - Destination amendment (must not be posted)
--    @TargetAmendmentSectionTypeId (UNIQUEIDENTIFIER) - Section type for the new ProjectAmendment row
--
-- Returns:
--    On success: a single row with column [Id] = newly created ProjectAmendmentId.
--    On validation failure: raises an error via THROW (50000) so the caller
--    receives a SqlException. User-facing validation should run in the
--    request validator; these checks are defense-in-depth.
--
-- Dependencies:
--    Tables:
--       tip.ProjectAmendment
--       tip.Project_Pending
--       tip.ProjectImprovementTypeMapping_Pending
--       tip.ProjectCountyMapping_Pending
--       tip.ProjectBudget_Pending
--       tip.ProgrammedFunding_Pending
--       tip.ProjectAmendmentReviewArea
--       tip.ProjectAmendmentReviewAreaType
--       tip.ProjectAmendmentReviewStatusType
--       tip.ProjectAmendmentReviewAreaStatusType
--       tip.Amendment, tip.AmendmentStatusType
--
-- Business Rules:
--    - Source pending project must exist within the source amendment.
--    - Target amendment must exist and not be posted.
--    - The base project must not already exist in the target amendment.
--    - Source amendment may be posted (Copy does not mutate the source, so
--      branching from history is allowed; differs intentionally from Move).
--    - ProgrammedFunding_Pending OriginRecordId chain is rewritten through a
--      translation table so origins self-reference their new Id and
--      non-origins point at the new Id of their origin.
--    - Review areas for the new ProjectAmendment are regenerated as
--      'unreviewed' for every active review area type.
-- =============================================
CREATE   PROCEDURE [dbo].[pr_tip_project_amendment_copy]
    @UserId                       UNIQUEIDENTIFIER
  , @SourceAmendmentId            UNIQUEIDENTIFIER
  , @SourceProjectPendingId       UNIQUEIDENTIFIER
  , @TargetAmendmentId            UNIQUEIDENTIFIER
  , @TargetAmendmentSectionTypeId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @SourceProjectAmendmentId UNIQUEIDENTIFIER;
    DECLARE @ProjectId                UNIQUEIDENTIFIER;
    DECLARE @NewProjectAmendmentId    UNIQUEIDENTIFIER = NEWID();
    DECLARE @NewProjectPendingId      UNIQUEIDENTIFIER = NEWID();
    DECLARE @IncompleteStatusId       UNIQUEIDENTIFIER;
    DECLARE @UnreviewedStatusId       UNIQUEIDENTIFIER;
    DECLARE @Now                      DATETIME2(7) = GETUTCDATE();

    -- Resolve the source ProjectAmendmentId (and the underlying ProjectId)
    -- from Project_Pending, scoped to the source amendment.
    SELECT @SourceProjectAmendmentId = pp.ProjectAmendmentId,
           @ProjectId                = pa.ProjectId
        FROM tip.Project_Pending AS pp
        INNER JOIN tip.ProjectAmendment AS pa ON pa.Id = pp.ProjectAmendmentId
        WHERE pp.Id = @SourceProjectPendingId
          AND pa.AmendmentId = @SourceAmendmentId;

    IF @SourceProjectAmendmentId IS NULL
        THROW 50000, 'Source pending project not found in source amendment', 1;

    -- Target amendment must exist
    IF NOT EXISTS (SELECT 1 FROM tip.Amendment WHERE Id = @TargetAmendmentId)
        THROW 50000, 'Target amendment does not exist', 1;

    -- Target amendment must not be posted
    IF EXISTS (
        SELECT 1
            FROM tip.Amendment a
            INNER JOIN tip.AmendmentStatusType ast ON ast.Id = a.AmendmentStatusTypeId
            WHERE a.Id = @TargetAmendmentId AND ast.Code = 'posted'
    )
        THROW 50000, 'Cannot copy project to a posted amendment', 1;

    -- Project must not already be in the target amendment
    IF EXISTS (
        SELECT 1
            FROM tip.ProjectAmendment
            WHERE ProjectId = @ProjectId
              AND AmendmentId = @TargetAmendmentId
    )
        THROW 50000, 'Project already exists in the target amendment', 1;

    -- Resolve status type IDs
    SELECT @IncompleteStatusId = Id
        FROM tip.ProjectAmendmentReviewStatusType
        WHERE Code = 'incomplete';

    IF @IncompleteStatusId IS NULL
        THROW 50000, 'ProjectAmendmentReviewStatusType row with Code=''incomplete'' is missing', 1;

    SELECT @UnreviewedStatusId = Id
        FROM tip.ProjectAmendmentReviewAreaStatusType
        WHERE Code = 'unreviewed';

    IF @UnreviewedStatusId IS NULL
        THROW 50000, 'ProjectAmendmentReviewAreaStatusType row with Code=''unreviewed'' is missing', 1;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- =============================================
        -- STEP 1: Create new ProjectAmendment row
        -- =============================================
        INSERT INTO tip.ProjectAmendment
            ( Id
            , ProjectId
            , AmendmentId
            , AmendmentSectionTypeId
            , ProjectAmendmentReviewStatusTypeId
            , CreatedById
            , CreatedOn)
        VALUES
            ( @NewProjectAmendmentId
            , @ProjectId
            , @TargetAmendmentId
            , @TargetAmendmentSectionTypeId
            , @IncompleteStatusId
            , @UserId
            , @Now);

        -- =============================================
        -- STEP 2: Copy Project_Pending -> Project_Pending
        -- =============================================
        INSERT INTO tip.Project_Pending
            ( Id
            , ProjectAmendmentId
            , AgencyId
            , ProjectCode
            , Title
            , ContactId
            , WsDotPin
            , DemoId
            , Location
            , LocationFrom
            , LocationTo
            , Length
            , FunctionalClassTypeId
            , PrimaryImprovementTypeId
            , Description
            , DateFullyImplemented
            , RcpStatusTypeId
            , ConstantDollarProjectYear
            , MappedTypeId
            , EnvironmentalStatusTypeId
            , RegionalSignificanceTypeId
            , YearCompPL
            , YearCompPE
            , YearCompROW
            , YearCompCN
            , YearCompOther
            , DateCompProject
            , CaSponsorAgencyId
            , CompletionStatusTypeId
            , UpwpObjective
            , UpwpTasks
            , UpwpProducts
            , UpwpPolicy
            , UpwpIsEquipmentPurchaseFlag
            , PsrcComments
            , ReportDescription
            , CreatedById
            , CreatedOn)
        SELECT
              @NewProjectPendingId
            , @NewProjectAmendmentId
            , src.AgencyId
            , src.ProjectCode
            , src.Title
            , src.ContactId
            , src.WsDotPin
            , src.DemoId
            , src.Location
            , src.LocationFrom
            , src.LocationTo
            , src.Length
            , src.FunctionalClassTypeId
            , src.PrimaryImprovementTypeId
            , src.Description
            , src.DateFullyImplemented
            , src.RcpStatusTypeId
            , src.ConstantDollarProjectYear
            , src.MappedTypeId
            , src.EnvironmentalStatusTypeId
            , src.RegionalSignificanceTypeId
            , src.YearCompPL
            , src.YearCompPE
            , src.YearCompROW
            , src.YearCompCN
            , src.YearCompOther
            , src.DateCompProject
            , src.CaSponsorAgencyId
            , src.CompletionStatusTypeId
            , src.UpwpObjective
            , src.UpwpTasks
            , src.UpwpProducts
            , src.UpwpPolicy
            , src.UpwpIsEquipmentPurchaseFlag
            , src.PsrcComments
            , src.ReportDescription
            , @UserId
            , @Now
        FROM tip.Project_Pending AS src
        WHERE src.Id = @SourceProjectPendingId;

        -- =============================================
        -- STEP 3: Copy ProjectImprovementTypeMapping_Pending
        -- =============================================
        INSERT INTO tip.ProjectImprovementTypeMapping_Pending
            ( Id
            , ProjectId
            , ImprovementTypeId
            , CreatedById
            , CreatedOn)
        SELECT
              NEWID()
            , @NewProjectPendingId
            , src.ImprovementTypeId
            , @UserId
            , @Now
        FROM tip.ProjectImprovementTypeMapping_Pending AS src
        WHERE src.ProjectId = @SourceProjectPendingId;

        -- =============================================
        -- STEP 4: Copy ProjectCountyMapping_Pending
        -- =============================================
        INSERT INTO tip.ProjectCountyMapping_Pending
            ( Id
            , ProjectId
            , CountyId
            , CreatedById
            , CreatedOn)
        SELECT
              NEWID()
            , @NewProjectPendingId
            , src.CountyId
            , @UserId
            , @Now
        FROM tip.ProjectCountyMapping_Pending AS src
        WHERE src.ProjectId = @SourceProjectPendingId;

        -- =============================================
        -- STEP 5: Copy ProjectBudget_Pending
        -- =============================================
        INSERT INTO tip.ProjectBudget_Pending
            ( Id
            , Project_PendingId
            , FundingSourceTypeId
            , PLSecuredAmount
            , PLUnsecuredAmount
            , PESecuredAmount
            , PEUnsecuredAmount
            , ROWSecuredAmount
            , ROWUnsecuredAmount
            , CNSecuredAmount
            , CNUnsecuredAmount
            , OtherSecuredAmount
            , OtherUnsecuredAmount
            , CreatedById
            , CreatedOn)
        SELECT
              NEWID()
            , @NewProjectPendingId
            , src.FundingSourceTypeId
            , src.PLSecuredAmount
            , src.PLUnsecuredAmount
            , src.PESecuredAmount
            , src.PEUnsecuredAmount
            , src.ROWSecuredAmount
            , src.ROWUnsecuredAmount
            , src.CNSecuredAmount
            , src.CNUnsecuredAmount
            , src.OtherSecuredAmount
            , src.OtherUnsecuredAmount
            , @UserId
            , @Now
        FROM tip.ProjectBudget_Pending AS src
        WHERE src.Project_PendingId = @SourceProjectPendingId;

        -- =============================================
        -- STEP 6: Copy ProgrammedFunding_Pending with OriginRecordId remap
        -- =============================================
        -- Translation table: every source pending row gets a NewId. After
        -- insert, OriginRecordId is rewritten so origins self-reference and
        -- non-origins point at the (new) origin row inside the new pending
        -- set. This preserves version-numbering invariants.
        DECLARE @FundingIdMap TABLE (
            OldId             UNIQUEIDENTIFIER NOT NULL,
            NewId             UNIQUEIDENTIFIER NOT NULL,
            OldOriginRecordId UNIQUEIDENTIFIER NOT NULL
        );

        INSERT INTO @FundingIdMap (OldId, NewId, OldOriginRecordId)
        SELECT pf.Id, NEWID(), pf.OriginRecordId
        FROM tip.ProgrammedFunding_Pending AS pf
        WHERE pf.Project_PendingId = @SourceProjectPendingId;

        -- Invariant check: every non-origin row's OriginRecordId must point at
        -- another row inside the same source pending set. If not, the chain is
        -- corrupt and a silent fallback to self-reference would mask the data
        -- problem; surface it instead.
        IF EXISTS (
            SELECT 1
                FROM @FundingIdMap m
                WHERE m.OldOriginRecordId <> m.OldId
                  AND NOT EXISTS (
                      SELECT 1 FROM @FundingIdMap m2 WHERE m2.OldId = m.OldOriginRecordId
                  )
        )
            THROW 50000, 'ProgrammedFunding_Pending OriginRecordId chain references a row outside the source pending set', 1;

        INSERT INTO tip.ProgrammedFunding_Pending
            ( Id
            , Project_PendingId
            , AwardReferenceId
            , PhaseTypeId
            , ProgrammedFundingYear
            , EstimatedObligationDate
            , FundingSourceTypeId
            , FundingAmount
            , IsObligatedFlag
            , FtaObligatedDate
            , FtaObligatedNumber
            , FhwaObligatedDate
            , FhwaObligatedNumber
            , OriginRecordId
            , IsActive
            , CreatedById
            , CreatedOn)
        SELECT
              m.NewId
            , @NewProjectPendingId
            , pf.AwardReferenceId
            , pf.PhaseTypeId
            , pf.ProgrammedFundingYear
            , pf.EstimatedObligationDate
            , pf.FundingSourceTypeId
            , pf.FundingAmount
            , pf.IsObligatedFlag
            , pf.FtaObligatedDate
            , pf.FtaObligatedNumber
            , pf.FhwaObligatedDate
            , pf.FhwaObligatedNumber
            , CASE
                WHEN pf.OriginRecordId = pf.Id THEN m.NewId          -- Origin: self-reference under new Id
                ELSE ISNULL(om.NewId, m.NewId)                        -- Non-origin: point at origin's new Id (fallback to self if origin missing)
              END
            , pf.IsActive
            , @UserId
            , pf.CreatedOn  -- Preserve original CreatedOn for version ordering
        FROM tip.ProgrammedFunding_Pending AS pf
        INNER JOIN @FundingIdMap m ON m.OldId = pf.Id
        LEFT JOIN @FundingIdMap om ON om.OldId = pf.OriginRecordId;

        -- =============================================
        -- STEP 7: Auto-create fresh ProjectAmendmentReviewArea rows
        -- =============================================
        INSERT INTO tip.ProjectAmendmentReviewArea
            ( Id
            , ProjectAmendmentId
            , ProjectAmendmentReviewAreaTypeId
            , ProjectAmendmentReviewAreaStatusTypeId
            , ReviewerComments
            , FollowUpComments
            , CreatedById
            , CreatedOn)
        SELECT
              NEWID()
            , @NewProjectAmendmentId
            , parat.Id
            , @UnreviewedStatusId
            , NULL
            , NULL
            , @UserId
            , @Now
        FROM tip.ProjectAmendmentReviewAreaType AS parat
        WHERE parat.EffectiveDate <= CAST(GETDATE() AS DATE)
          AND (parat.EndDate IS NULL OR parat.EndDate >= CAST(GETDATE() AS DATE));

        COMMIT TRANSACTION;

        -- Return the new ProjectAmendment Id (mirrors pr_tip_project_amendment_create)
        SELECT Id = @NewProjectAmendmentId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
