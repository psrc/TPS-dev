SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2025-12-17
-- Modified:    2026-02-20 - Preserve existing month/day for DateCompProject when only year changes
-- Modified:    2026-04-28 - Added Reporting tab fields (project ReportDescription, amendment ReportDescription, 4 report flags)
-- Description: Updates a pending project within a TIP amendment with all related data
--              including secondary improvement types, county mappings, budget, and programmed funding.
--              Validates that the amendment is not posted before allowing updates.
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_amendment_pending_update]
(
    -- Core identifiers
    @UserId                      UNIQUEIDENTIFIER -- User performing the update (for audit trail)
,   @AmendmentId                 UNIQUEIDENTIFIER -- Amendment containing the project
,   @ProjectPendingId            UNIQUEIDENTIFIER -- Project_Pending ID to update
,   @AgencyId                    UNIQUEIDENTIFIER -- Agency responsible for the project
,   @ContactId                   UNIQUEIDENTIFIER = NULL -- Optional contact person for the project
-- Basic information
,   @ProjectCode                 NVARCHAR(50) -- Unique project code/identifier
,   @Title                       NVARCHAR(255) = NULL -- Project title/name
,   @Description                 NVARCHAR(MAX) = NULL -- Detailed project description
,   @WsDotPin                    NVARCHAR(30) = NULL -- Washington State DOT PIN Identifier
,   @DemoId                      NVARCHAR(30) = NULL -- Demo identifier
-- Location information
,   @Location                    NVARCHAR(255) = NULL -- General project location
,   @LocationFrom                NVARCHAR(255) = NULL -- Starting location/point
,   @LocationTo                  NVARCHAR(255) = NULL -- Ending location/point
,   @Length                      INT = NULL -- Project length
,   @DateFullyImplemented        DATE = NULL -- When project was/will be fully completed
,   @DateCompProject             DATE = NULL -- Project completion date
-- Classification and status type identifiers
,   @MappedTypeId                UNIQUEIDENTIFIER = NULL -- Project mapping/classification type
,   @RcpStatusTypeId             UNIQUEIDENTIFIER = NULL -- RCP (Regional Capital Program) status
,   @EnvironmentalStatusTypeId   UNIQUEIDENTIFIER = NULL -- Environmental review status
,   @RegionalSignificanceTypeId  UNIQUEIDENTIFIER = NULL -- Regional significance level
,   @FunctionalClassTypeId       UNIQUEIDENTIFIER = NULL -- Functional classification (arterial, local, etc.)
,   @PrimaryImprovementTypeId    UNIQUEIDENTIFIER = NULL -- Primary type of improvement
,   @SecondaryImprovementTypeIds UniqueIdentifierArrayType READONLY -- Additional improvement types
,   @ConstantDollarProjectYear   SMALLINT = NULL -- Constant dollar project year
-- Year completion fields
,   @YearCompPL                  SMALLINT = NULL
,   @YearCompPE                  SMALLINT = NULL
,   @YearCompROW                 SMALLINT = NULL
,   @YearCompCN                  SMALLINT = NULL
,   @YearCompOther               SMALLINT = NULL
-- Sponsor and status
,   @CaSponsorAgencyId           UNIQUEIDENTIFIER = NULL -- CA Sponsor Agency
,   @CompletionStatusTypeId      UNIQUEIDENTIFIER = NULL -- Completion status
-- UPWP (Unified Planning Work Program) related fields
,   @UpwpObjective               NVARCHAR(MAX) = NULL -- UPWP planning objectives
,   @UpwpTasks                   NVARCHAR(MAX) = NULL -- UPWP tasks to be performed
,   @UpwpProducts                NVARCHAR(MAX) = NULL -- UPWP deliverable products
,   @UpwpPolicy                  NVARCHAR(MAX) = NULL -- UPWP policy considerations
,   @UpwpIsEquipmentPurchaseFlag BIT = NULL -- Flag indicating equipment purchase
-- Administrative fields
,   @PsrcComments                NVARCHAR(MAX) = NULL -- PSRC (Puget Sound Regional Council) project comments
,   @PsrcAmendmentComments       NVARCHAR(MAX) = NULL -- PSRC comments on the amendment for this project
,   @ReportDescription           NVARCHAR(MAX) = NULL -- Reporting tab project-level description
,   @AmendmentReportDescription  NVARCHAR(MAX) = NULL -- Reporting tab amendment-level description
,   @ReportProjectTrackingFlag   BIT = 0 -- Reporting tab: Project Tracking checkbox
,   @ReportNewProjectPhaseFlag   BIT = 0 -- Reporting tab: New Project/Phase checkbox
,   @ReportUpwpFlag              BIT = 0 -- Reporting tab: UPWP checkbox
,   @ReportOtherAmendFlag        BIT = 0 -- Reporting tab: Other Amend checkbox
,   @CountyIds                   UniqueIdentifierArrayType READONLY -- Counties where project is located
,   @ProgrammedFunds             ProgrammedFundsArrayType READONLY -- Funding information
,   @Budget                      ProjectBudgetArrayType READONLY -- Budget information
) AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- =============================================
    -- VALIDATE AMENDMENT STATUS
    -- =============================================
    -- Check that the amendment is not posted (posted amendments are read-only)
    DECLARE @AmendmentStatusCode NVARCHAR(100);

    SELECT @AmendmentStatusCode = ast.Code
    FROM tip.Amendment AS a
    INNER JOIN tip.AmendmentStatusType AS ast ON ast.Id = a.AmendmentStatusTypeId
    WHERE a.Id = @AmendmentId;

    IF @AmendmentStatusCode = 'posted'
    BEGIN
        RAISERROR('Cannot update pending project data for a posted amendment.', 16, 1);
        RETURN 0;
    END;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- =============================================
        -- UPDATE PENDING PROJECT RECORD
        -- =============================================
        UPDATE tip.Project_Pending
        SET
            AgencyId                    = @AgencyId
          , ProjectCode                 = @ProjectCode
          , ContactId                   = @ContactId
          , Title                       = @Title
          , Description                 = @Description
          , WsDotPin                    = @WsDotPin
          , DemoId                      = @DemoId
          , Location                    = @Location
          , LocationFrom                = @LocationFrom
          , LocationTo                  = @LocationTo
          , Length                      = @Length
          , DateFullyImplemented        = @DateFullyImplemented
          , DateCompProject             = CASE
                                            WHEN @DateCompProject IS NULL THEN NULL
                                            WHEN DateCompProject IS NOT NULL
                                                THEN DATEFROMPARTS(YEAR(@DateCompProject), MONTH(DateCompProject), DAY(DateCompProject))
                                            ELSE @DateCompProject
                                          END
          , MappedTypeId                = @MappedTypeId
          , RcpStatusTypeId             = @RcpStatusTypeId
          , EnvironmentalStatusTypeId   = @EnvironmentalStatusTypeId
          , RegionalSignificanceTypeId  = @RegionalSignificanceTypeId
          , FunctionalClassTypeId       = @FunctionalClassTypeId
          , PrimaryImprovementTypeId    = @PrimaryImprovementTypeId
          , ConstantDollarProjectYear   = @ConstantDollarProjectYear
          , YearCompPL                  = @YearCompPL
          , YearCompPE                  = @YearCompPE
          , YearCompROW                 = @YearCompROW
          , YearCompCN                  = @YearCompCN
          , YearCompOther               = @YearCompOther
          , CaSponsorAgencyId           = @CaSponsorAgencyId
          , CompletionStatusTypeId      = @CompletionStatusTypeId
          , UpwpObjective               = @UpwpObjective
          , UpwpTasks                   = @UpwpTasks
          , UpwpProducts                = @UpwpProducts
          , UpwpPolicy                  = @UpwpPolicy
          , UpwpIsEquipmentPurchaseFlag = @UpwpIsEquipmentPurchaseFlag
          , PsrcComments                = @PsrcComments
          , ReportDescription           = @ReportDescription
          , UpdatedById                 = @UserId
          , UpdatedOn                   = GETUTCDATE()
        WHERE
            Id = @ProjectPendingId;

        -- =============================================
        -- UPDATE PROJECT AMENDMENT COMMENTS AND REPORTING FIELDS
        -- =============================================
        -- Update the PsrcComments and Reporting tab fields on the ProjectAmendment record
        UPDATE pa
        SET
          PsrcComments               = @PsrcAmendmentComments
        , ReportDescription          = @AmendmentReportDescription
        , ReportProjectTrackingFlag  = @ReportProjectTrackingFlag
        , ReportNewProjectPhaseFlag  = @ReportNewProjectPhaseFlag
        , ReportUpwpFlag             = @ReportUpwpFlag
        , ReportOtherAmendFlag       = @ReportOtherAmendFlag
        , UpdatedById                = @UserId
        , UpdatedOn                  = GETUTCDATE()
        FROM tip.ProjectAmendment pa
        INNER JOIN tip.Project_Pending pp ON pp.ProjectAmendmentId = pa.Id
        WHERE pp.Id = @ProjectPendingId;

        -- =============================================
        -- MANAGE SECONDARY IMPROVEMENT TYPE MAPPINGS
        -- =============================================
        -- Use MERGE to efficiently sync improvement type mappings
        MERGE tip.ProjectImprovementTypeMapping_Pending AS target
        USING (SELECT ProjectId = @ProjectPendingId, ImprovementTypeId = si.Value FROM @SecondaryImprovementTypeIds si) AS source
        ON target.ProjectId = source.ProjectId AND target.ImprovementTypeId = source.ImprovementTypeId
        WHEN NOT MATCHED BY TARGET THEN
            INSERT
                ( Id
                , ProjectId
                , ImprovementTypeId
                , CreatedById
                , CreatedOn)
                VALUES
                    (NEWID(), source.ProjectId, source.ImprovementTypeId, @UserId, GETUTCDATE())
        WHEN NOT MATCHED BY SOURCE AND target.ProjectId = @ProjectPendingId THEN
            DELETE;

        -- =============================================
        -- MANAGE COUNTY MAPPINGS
        -- =============================================
        -- Use MERGE to efficiently sync county mappings
        MERGE tip.ProjectCountyMapping_Pending AS target
        USING (SELECT ProjectId = @ProjectPendingId, CountyId = c.Value FROM @CountyIds c) AS source
        ON target.ProjectId = source.ProjectId AND target.CountyId = source.CountyId
        WHEN NOT MATCHED BY TARGET THEN
            INSERT
                ( Id
                , ProjectId
                , CountyId
                , CreatedById
                , CreatedOn)
                VALUES
                    (NEWID(), source.ProjectId, source.CountyId, @UserId, GETUTCDATE())
        WHEN NOT MATCHED BY SOURCE AND target.ProjectId = @ProjectPendingId THEN
            DELETE;

        -- =============================================
        -- MANAGE PROGRAMMED FUNDING WITH VERSIONING
        -- =============================================
        -- Complex versioning logic to maintain audit trail of funding changes
        -- Only process if there are active funding records in the input
        IF EXISTS (SELECT 1 FROM @ProgrammedFunds WHERE IsActive = 1)
        BEGIN
            -- Step 1: Identify records that need versioning (existing records being updated)
            ;WITH ExistingActiveRecords AS (
                SELECT
                    ExistingId       = existing.Id
                  , IncomingId       = incoming.Id
                  , ExistingOriginId = existing.OriginRecordId
                FROM
                    tip.ProgrammedFunding_Pending existing
                    INNER JOIN @ProgrammedFunds incoming ON existing.Id = incoming.Id
                WHERE
                        existing.IsActive = 1
                    AND incoming.IsActive = 1
            )

            -- Step 2: Archive existing records by marking them inactive
            UPDATE pf
            SET
                pf.IsActive    = 0
              , pf.UpdatedById = @UserId
              , pf.UpdatedOn   = GETUTCDATE()
            FROM
                tip.ProgrammedFunding_Pending pf
                INNER JOIN ExistingActiveRecords er ON pf.Id = er.ExistingId;

            -- Step 3: Insert updated versions of existing records
            ;WITH ExistingInactiveRecords AS (
                SELECT
                    ExistingId       = existing.Id
                  , IncomingId       = incoming.Id
                  , ExistingOriginId = existing.OriginRecordId
                FROM
                    tip.ProgrammedFunding_Pending existing
                    INNER JOIN @ProgrammedFunds incoming ON existing.Id = incoming.Id
                WHERE
                        existing.IsActive = 0
                    AND incoming.IsActive = 1
            )
            INSERT INTO tip.ProgrammedFunding_Pending
                ( Id
                , Project_PendingId
                , OriginRecordId
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
                , IsActive
                , CreatedById
                , CreatedOn)
            SELECT
                Id                      = NEWID()
              , Project_PendingId       = @ProjectPendingId
              , OriginRecordId          = COALESCE(er.ExistingOriginId, er.ExistingId)
              , AwardReferenceId        = pf.AwardReferenceId
              , PhaseTypeId             = pf.PhaseTypeId
              , ProgrammedFundingYear   = pf.ProgrammedFundingYear
              , EstimatedObligationDate = pf.EstimatedObligationDate
              , FundingSourceTypeId     = pf.FundingSourceTypeId
              , FundingAmount           = pf.FundingAmount
              , IsObligatedFlag         = pf.IsObligatedFlag
              , FtaObligatedDate        = pf.FtaObligatedDate
              , FtaObligatedNumber      = pf.FtaObligatedNumber
              , FhwaObligatedDate       = pf.FhwaObligatedDate
              , FhwaObligatedNumber     = pf.FhwaObligatedNumber
              , IsActive                = 1
              , CreatedById             = @UserId
              , CreatedOn               = GETUTCDATE()
            FROM
                @ProgrammedFunds pf
                INNER JOIN ExistingInactiveRecords er ON pf.Id = er.IncomingId
            WHERE
                pf.IsActive = 1;

            -- Step 4: Insert completely new funding records (not updates)
            INSERT INTO tip.ProgrammedFunding_Pending
                ( Id
                , Project_PendingId
                , OriginRecordId
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
                , IsActive
                , CreatedById
                , CreatedOn)
            SELECT
                Id                      = pf.Id
              , Project_PendingId       = @ProjectPendingId
              , OriginRecordId          = pf.OriginRecordId
              , AwardReferenceId        = pf.AwardReferenceId
              , PhaseTypeId             = pf.PhaseTypeId
              , ProgrammedFundingYear   = pf.ProgrammedFundingYear
              , EstimatedObligationDate = pf.EstimatedObligationDate
              , FundingSourceTypeId     = pf.FundingSourceTypeId
              , FundingAmount           = pf.FundingAmount
              , IsObligatedFlag         = pf.IsObligatedFlag
              , FtaObligatedDate        = pf.FtaObligatedDate
              , FtaObligatedNumber      = pf.FtaObligatedNumber
              , FhwaObligatedDate       = pf.FhwaObligatedDate
              , FhwaObligatedNumber     = pf.FhwaObligatedNumber
              , IsActive                = 1
              , CreatedById             = @UserId
              , CreatedOn               = GETUTCDATE()
            FROM
                @ProgrammedFunds pf
            WHERE
                    pf.IsActive = 1
                AND NOT EXISTS (SELECT 1 FROM tip.ProgrammedFunding_Pending existing WHERE existing.Id = pf.Id);
        END;

        -- =============================================
        -- PENDING PROJECT BUDGET
        -- =============================================
        -- Upsert budget records
        IF EXISTS (SELECT 1 FROM @Budget)
        BEGIN
            -- Update existing budget records
            UPDATE pb
            SET
                pb.FundingSourceTypeId  = b.FundingSourceTypeId
              , pb.PLSecuredAmount      = b.PLSecuredAmount
              , pb.PLUnsecuredAmount    = b.PLUnsecuredAmount
              , pb.PESecuredAmount      = b.PESecuredAmount
              , pb.PEUnsecuredAmount    = b.PEUnsecuredAmount
              , pb.ROWSecuredAmount     = b.ROWSecuredAmount
              , pb.ROWUnsecuredAmount   = b.ROWUnsecuredAmount
              , pb.CNSecuredAmount      = b.CNSecuredAmount
              , pb.CNUnsecuredAmount    = b.CNUnsecuredAmount
              , pb.OtherSecuredAmount   = b.OtherSecuredAmount
              , pb.OtherUnsecuredAmount = b.OtherUnsecuredAmount
              , pb.UpdatedById          = @UserId
              , pb.UpdatedOn            = GETUTCDATE()
            FROM
                tip.ProjectBudget_Pending pb
                INNER JOIN @Budget b ON pb.Id = b.Id
            WHERE
                pb.Project_PendingId = @ProjectPendingId;

            -- Insert new budget records
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
                Id                   = b.Id
              , Project_PendingId    = @ProjectPendingId
              , FundingSourceTypeId  = b.FundingSourceTypeId
              , PLSecuredAmount      = b.PLSecuredAmount
              , PLUnsecuredAmount    = b.PLUnsecuredAmount
              , PESecuredAmount      = b.PESecuredAmount
              , PEUnsecuredAmount    = b.PEUnsecuredAmount
              , ROWSecuredAmount     = b.ROWSecuredAmount
              , ROWUnsecuredAmount   = b.ROWUnsecuredAmount
              , CNSecuredAmount      = b.CNSecuredAmount
              , CNUnsecuredAmount    = b.CNUnsecuredAmount
              , OtherSecuredAmount   = b.OtherSecuredAmount
              , OtherUnsecuredAmount = b.OtherUnsecuredAmount
              , CreatedById          = @UserId
              , CreatedOn            = GETUTCDATE()
            FROM
                @Budget b
            WHERE
                NOT EXISTS (SELECT 1 FROM tip.ProjectBudget_Pending pb WHERE pb.Id = b.Id);
        END;

        COMMIT;

    END TRY BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH;
END;
GO
