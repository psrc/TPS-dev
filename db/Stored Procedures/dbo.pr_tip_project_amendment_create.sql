SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create Date: 2025-07-24
-- Modified:    2025-12-18
-- Modified:    2026-02-20 - Include inactive ProgrammedFunding records and remap OriginRecordId chain
-- Modified:    2026-04-28 - Copy Project.ReportDescription into Project_Pending.ReportDescription on amendment create
-- Description: Creates a new project amendment record linking a project to an amendment
--              and copies the source project data into pending tables for modification.
--              Also auto-creates review area records for all active review area types.
--
-- Purpose:     This procedure creates a new entry in the tip.ProjectAmendment table
--              with an 'incomplete' review status, then copies the source project data
--              from the main tables into the pending tables:
--              - tip.Project -> tip.Project_Pending
--              - tip.ProjectImprovementTypeMapping -> tip.ProjectImprovementTypeMapping_Pending
--              - tip.ProjectCountyMapping -> tip.ProjectCountyMapping_Pending
--              - tip.ProjectBudget -> tip.ProjectBudget_Pending
--              - tip.ProgrammedFunding -> tip.ProgrammedFunding_Pending
--              - tip.ProjectAmendmentReviewArea (auto-created for each active review area type)
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_amendment_create]
    @UserId                 UNIQUEIDENTIFIER -- ID of the user creating the amendment
  , @AmendmentId            UNIQUEIDENTIFIER -- ID of the amendment being applied to the project
  , @ProjectId              UNIQUEIDENTIFIER -- ID of the project being amended
  , @AmendmentSectionTypeId UNIQUEIDENTIFIER -- ID of the amendment section type (category/area of amendment)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Generate new unique identifiers
    DECLARE @ProjectAmendmentId UNIQUEIDENTIFIER = NEWID();
    DECLARE @ProjectPendingId UNIQUEIDENTIFIER = NEWID();
    DECLARE @IncompleteStatusId UNIQUEIDENTIFIER;
    DECLARE @UnreviewedStatusId UNIQUEIDENTIFIER;
    DECLARE @Now DATETIME2(7) = GETUTCDATE();

    -- Retrieve the ID for the 'incomplete' review status type
    SELECT @IncompleteStatusId = Id
    FROM tip.ProjectAmendmentReviewStatusType
    WHERE Code = 'incomplete';

    -- Retrieve the ID for the 'unreviewed' review area status type
    SELECT @UnreviewedStatusId = Id
    FROM tip.ProjectAmendmentReviewAreaStatusType
    WHERE Code = 'unreviewed';

    BEGIN TRANSACTION;

    BEGIN TRY
        -- =============================================
        -- STEP 1: Create ProjectAmendment record
        -- =============================================
        INSERT INTO tip.ProjectAmendment
            (Id, ProjectId, AmendmentId, AmendmentSectionTypeId, ProjectAmendmentReviewStatusTypeId, CreatedById, CreatedOn)
        VALUES
            (@ProjectAmendmentId, @ProjectId, @AmendmentId, @AmendmentSectionTypeId, @IncompleteStatusId, @UserId, @Now);

        -- =============================================
        -- STEP 2: Copy Project to Project_Pending
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
              @ProjectPendingId
            , @ProjectAmendmentId
            , p.AgencyId
            , p.ProjectCode
            , p.Title
            , p.ContactId
            , p.WsDotPin
            , p.DemoId
            , p.Location
            , p.LocationFrom
            , p.LocationTo
            , p.Length
            , p.FunctionalClassTypeId
            , p.PrimaryImprovementTypeId
            , p.Description
            , p.DateFullyImplemented
            , p.RcpStatusTypeId
            , p.ConstantDollarProjectYear
            , p.MappedTypeId
            , p.EnvironmentalStatusTypeId
            , p.RegionalSignificanceTypeId
            , p.YearCompPL
            , p.YearCompPE
            , p.YearCompROW
            , p.YearCompCN
            , p.YearCompOther
            , p.DateCompProject
            , p.CaSponsorAgencyId
            , p.CompletionStatusTypeId
            , p.UpwpObjective
            , p.UpwpTasks
            , p.UpwpProducts
            , p.UpwpPolicy
            , p.UpwpIsEquipmentPurchaseFlag
            , p.PsrcComments
            , p.ReportDescription
            , @UserId
            , @Now
        FROM tip.Project AS p
        WHERE p.Id = @ProjectId;

        -- =============================================
        -- STEP 3: Copy ProjectImprovementTypeMapping to _Pending
        -- =============================================
        INSERT INTO tip.ProjectImprovementTypeMapping_Pending
            ( Id
            , ProjectId
            , ImprovementTypeId
            , CreatedById
            , CreatedOn)
        SELECT
              NEWID()
            , @ProjectPendingId
            , pitm.ImprovementTypeId
            , @UserId
            , @Now
        FROM tip.ProjectImprovementTypeMapping AS pitm
        WHERE pitm.ProjectId = @ProjectId;

        -- =============================================
        -- STEP 4: Copy ProjectCountyMapping to _Pending
        -- =============================================
        INSERT INTO tip.ProjectCountyMapping_Pending
            ( Id
            , ProjectId
            , CountyId
            , CreatedById
            , CreatedOn)
        SELECT
              NEWID()
            , @ProjectPendingId
            , pcm.CountyId
            , @UserId
            , @Now
        FROM tip.ProjectCountyMapping AS pcm
        WHERE pcm.ProjectId = @ProjectId;

        -- =============================================
        -- STEP 5: Copy ProjectBudget to _Pending
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
            , @ProjectPendingId
            , pb.FundingSourceTypeId
            , pb.PLSecuredAmount
            , pb.PLUnsecuredAmount
            , pb.PESecuredAmount
            , pb.PEUnsecuredAmount
            , pb.ROWSecuredAmount
            , pb.ROWUnsecuredAmount
            , pb.CNSecuredAmount
            , pb.CNUnsecuredAmount
            , pb.OtherSecuredAmount
            , pb.OtherUnsecuredAmount
            , @UserId
            , @Now
        FROM tip.ProjectBudget AS pb
        WHERE pb.ProjectId = @ProjectId;

        -- =============================================
        -- STEP 6: Copy ProgrammedFunding to _Pending
        -- =============================================
        -- Pre-generate new IDs so we can remap OriginRecordId into the pending ID space.
        -- The version numbering algorithm requires origin records to have OriginRecordId == Id.
        DECLARE @FundingIdMap TABLE (
            OldId             UNIQUEIDENTIFIER NOT NULL,
            NewId             UNIQUEIDENTIFIER NOT NULL,
            OldOriginRecordId UNIQUEIDENTIFIER NOT NULL
        );

        INSERT INTO @FundingIdMap (OldId, NewId, OldOriginRecordId)
        SELECT pf.Id, NEWID(), pf.OriginRecordId
        FROM tip.ProgrammedFunding AS pf
        WHERE pf.ProjectId = @ProjectId;

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
            , @ProjectPendingId
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
                WHEN pf.OriginRecordId = pf.Id THEN m.NewId        -- Origin: self-reference with new Id
                ELSE ISNULL(om.NewId, m.NewId)                      -- Non-origin: point to origin's new Id
              END
            , pf.IsActive
            , @UserId
            , pf.CreatedOn  -- Preserve original creation time for version ordering
        FROM tip.ProgrammedFunding AS pf
        INNER JOIN @FundingIdMap m ON m.OldId = pf.Id
        LEFT JOIN @FundingIdMap om ON om.OldId = pf.OriginRecordId;

        -- =============================================
        -- STEP 7: Auto-create ProjectAmendmentReviewArea records
        -- =============================================
        -- Create a review area record for each active review area type.
        -- Active types are those where EffectiveDate <= today AND (EndDate IS NULL OR EndDate >= today)
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
            , @ProjectAmendmentId
            , parat.Id
            , @UnreviewedStatusId
            , NULL  -- ReviewerComments
            , NULL  -- FollowUpComments
            , @UserId
            , @Now
        FROM tip.ProjectAmendmentReviewAreaType AS parat
        WHERE parat.EffectiveDate <= CAST(GETDATE() AS DATE)
          AND (parat.EndDate IS NULL OR parat.EndDate >= CAST(GETDATE() AS DATE));

        COMMIT TRANSACTION;

        -- Return the newly generated ProjectAmendment ID to the caller
        SELECT Id = @ProjectAmendmentId;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
