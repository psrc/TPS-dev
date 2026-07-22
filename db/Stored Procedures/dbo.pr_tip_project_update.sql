SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author: john.hunter@triskelle.solutions
-- Create date: 2025-07-02
-- Modified:    2026-02-20 - Preserve existing month/day for DateCompProject when only year changes
-- Modified:    2026-04-28 - Added @ReportDescription parameter to persist Reporting tab project-level description
-- Description: Updates a subset of a TIP (Transportation Improvement Program) project with all related data
--              including secondary improvement types, county mappings, and programmed funding.
--              Implements versioning for programmed funding records to maintain audit trail.
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_update]
(
    -- Core identifiers
    @UserId                      UNIQUEIDENTIFIER -- User performing the update (for audit trail)
,   @Id                          UNIQUEIDENTIFIER -- Project ID to update
,   @AgencyId                    UNIQUEIDENTIFIER -- Agency responsible for the project
,   @ContactId                   UNIQUEIDENTIFIER = NULL -- Optional contact person for the project
-- Basic information
,   @ProjectCode                 NVARCHAR(50) -- Unique project code/identifier
,   @Title                       NVARCHAR(255) -- Project title/name
,   @Description                 NVARCHAR(MAX) -- Detailed project description
,   @WsDotPin                    NVARCHAR(30) = NULL -- Washington State DOT PIN Identifier
,   @DemoId                      NVARCHAR(30) = NULL -- Demo ID
-- Location information
,   @Location                    NVARCHAR(255) = NULL -- General project location
,   @LocationFrom                NVARCHAR(255) = NULL -- Starting location/point
,   @LocationTo                  NVARCHAR(255) = NULL -- Ending location/point
,   @Length                      INT = NULL -- Project length (likely in feet/miles)
,   @DateFullyImplemented        DATE = NULL -- When project was/will be fully completed
-- Classification and status type identifiers
,   @MappedTypeId                UNIQUEIDENTIFIER = NULL -- Project mapping/classification type
,   @RcpStatusTypeId             UNIQUEIDENTIFIER = NULL -- RCP (Regional Capital Program) status
,   @EnvironmentalStatusTypeId   UNIQUEIDENTIFIER = NULL -- Environmental review status
,   @RegionalSignificanceTypeId  UNIQUEIDENTIFIER = NULL -- Regional significance level
,   @FunctionalClassTypeId       UNIQUEIDENTIFIER = NULL -- Functional classification (arterial, local, etc.)
,   @PrimaryImprovementTypeId    UNIQUEIDENTIFIER = NULL -- Primary type of improvement
,   @SecondaryImprovementTypeIds UniqueIdentifierArrayType READONLY -- Additional improvement types
-- Year completion fields
,   @ConstantDollarProjectYear   SMALLINT = NULL -- Constant dollar project year
,   @YearCompPL                  SMALLINT = NULL -- Year completion - Planning
,   @YearCompPE                  SMALLINT = NULL -- Year completion - Preliminary Engineering
,   @YearCompROW                 SMALLINT = NULL -- Year completion - Right of Way
,   @YearCompCN                  SMALLINT = NULL -- Year completion - Construction
,   @YearCompOther               SMALLINT = NULL -- Year completion - Other
,   @YearCompProject             DATE = NULL -- Project completion date
-- UPWP (Unified Planning Work Program) related fields
,   @UpwpObjective               NVARCHAR(MAX) = NULL -- UPWP planning objectives
,   @UpwpTasks                   NVARCHAR(MAX) = NULL -- UPWP tasks to be performed
,   @UpwpProducts                NVARCHAR(MAX) = NULL -- UPWP deliverable products
,   @UpwpPolicy                  NVARCHAR(MAX) = NULL -- UPWP policy considerations
,   @UpwpIsEquipmentPurchaseFlag BIT = NULL -- Flag indicating equipment purchase
-- Administrative fields
,   @PsrcComments                NVARCHAR(MAX) = NULL -- PSRC (Puget Sound Regional Council) comments
,   @ReportDescription           NVARCHAR(MAX) = NULL -- Reporting tab project-level description
,   @CountyIds                   UniqueIdentifierArrayType READONLY -- Counties where project is located
,   @ProgrammedFunds             ProgrammedFundsArrayType READONLY -- Funding information with versioning
,   @Budget                      ProjectBudgetArrayType READONLY -- Budget information
) AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- =============================================
        -- UPDATE MAIN PROJECT RECORD
        -- =============================================
        -- Update the core project information in the tip.Project table
        UPDATE tip.Project
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
          , DateCompProject             = CASE
                                            WHEN @YearCompProject IS NULL THEN NULL
                                            WHEN DateCompProject IS NOT NULL
                                                THEN DATEFROMPARTS(YEAR(@YearCompProject), MONTH(DateCompProject), DAY(DateCompProject))
                                            ELSE @YearCompProject
                                          END
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
                Id = @Id;

        -- =============================================
        -- MANAGE SECONDARY IMPROVEMENT TYPE MAPPINGS
        -- =============================================
        -- Handle many-to-many relationship between projects and secondary improvement types
        -- Use MERGE to efficiently sync improvement type mappings in a single operation
        MERGE tip.ProjectImprovementTypeMapping AS target
        USING (SELECT ProjectId = @Id, ImprovementTypeId = si.Value FROM @SecondaryImprovementTypeIds si) AS source
        ON target.ProjectId = source.ProjectId AND target.ImprovementTypeId = source.ImprovementTypeId
        WHEN NOT MATCHED BY TARGET THEN
            -- Insert new improvement type mappings
            INSERT
                ( Id
                , ProjectId
                , ImprovementTypeId
                , CreatedById
                , CreatedOn)
                VALUES
                    (NEWID(), source.ProjectId, source.ImprovementTypeId, @UserId, GETUTCDATE())
        WHEN NOT MATCHED BY SOURCE AND target.ProjectId = @Id THEN
            -- Remove improvement type mappings no longer in the list
            DELETE;

        -- =============================================
        -- MANAGE COUNTY MAPPINGS
        -- =============================================
        -- Handle many-to-many relationship between projects and counties
        -- Use MERGE to efficiently sync county mappings in a single operation
        MERGE tip.ProjectCountyMapping AS target
        USING (SELECT ProjectId = @Id, CountyId = c.Value FROM @CountyIds c) AS source
        ON target.ProjectId = source.ProjectId AND target.CountyId = source.CountyId
        WHEN NOT MATCHED BY TARGET THEN
            -- Insert new county mappings
            INSERT
                ( Id
                , ProjectId
                , CountyId
                , CreatedById
                , CreatedOn)
                VALUES
                    (NEWID(), source.ProjectId, source.CountyId, @UserId, GETUTCDATE())
        WHEN NOT MATCHED BY SOURCE AND target.ProjectId = @Id THEN
            -- Remove county mappings no longer in the list
            DELETE;

        -- =============================================
        -- MANAGE PROGRAMMED FUNDING WITH VERSIONING
        -- =============================================
        -- Complex versioning logic to maintain audit trail of funding changes
        -- Cannot use simple MERGE due to versioning requirements
        --
        -- Business Rules:
        -- - Records are never deleted; inactive versions are preserved for audit trail
        -- - Client should only send IsActive = 1 records; IsActive = 0 records are managed by the database
        -- - Records not included in @ProgrammedFunds are intentionally left unchanged (no orphan deletion)
        --
        -- Only process if there are active funding records in the input
        IF EXISTS (SELECT 1 FROM @ProgrammedFunds WHERE IsActive = 1)
            BEGIN
                -- Step 1: Identify records that need versioning (existing records being updated)
                ;WITH
                    ExistingActiveRecords AS (SELECT
                                                  ExistingId       = existing.Id
                                                , IncomingId       = incoming.Id
                                                , ExistingOriginId = existing.OriginRecordId
                                                  FROM
                                                      tip.ProgrammedFunding existing
                                                      INNER JOIN @ProgrammedFunds incoming
                                                                 ON existing.Id = incoming.Id
                                                  WHERE
                                                        existing.IsActive = 1
                                                    AND incoming.IsActive = 1)

                -- Step 2: Archive existing records by marking them inactive
                UPDATE pf
                SET
                    pf.IsActive    = 0
                  , pf.UpdatedById = @UserId
                  , pf.UpdatedOn   = GETUTCDATE()
                    FROM
                        tip.ProgrammedFunding pf
                        INNER JOIN ExistingActiveRecords er
                                   ON pf.Id = er.ExistingId


                -- Step 3: Insert updated versions of existing records (with new IDs, preserving version chain)
                ;WITH
                    ExistingInactiveRecords AS (SELECT
                                                    ExistingId       = existing.Id
                                                  , IncomingId       = incoming.Id
                                                  , ExistingOriginId = existing.OriginRecordId
                                                    FROM
                                                        tip.ProgrammedFunding existing
                                                        INNER JOIN @ProgrammedFunds incoming
                                                                   ON existing.Id = incoming.Id
                                                    WHERE
                                                          existing.IsActive = 0 -- Now inactive after Step 2
                                                      AND incoming.IsActive = 1)
                INSERT
                    INTO
                        tip.ProgrammedFunding
                        ( Id
                        , ProjectId
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
                    Id                      = NEWID() -- New ID for versioned record
                  , ProjectId               = pf.ProjectId -- Maintain version chain: use existing origin, or the old record ID if no origin exists
                  , OriginRecordId          = COALESCE(er.ExistingOriginId, er.ExistingId) -- Database manages version chain; ignore client-provided OriginRecordId
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
                        INNER JOIN ExistingInactiveRecords er
                                   ON pf.Id = er.IncomingId
                    WHERE
                        pf.IsActive = 1;

                -- Step 4: Insert completely new funding records (not updates)
                INSERT
                    INTO
                        tip.ProgrammedFunding
                        ( Id
                        , ProjectId
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
                    Id                      = pf.Id -- Keep original ID for truly new records
                  , ProjectId               = pf.ProjectId
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
                      AND NOT EXISTS (SELECT 1 FROM tip.ProgrammedFunding existing WHERE existing.Id = pf.Id);
            END;

        -- =============================================
        -- PROJECT BUDGET
        -- =============================================
        -- Business Rules:
        -- - Records not included in @Budget are intentionally left unchanged (no orphan deletion)
        -- - Deletion is not currently supported per business rules; this may change in the future
        -- - ProjectId is enforced via @Id parameter to prevent cross-project updates
        --
        -- Only process if there are budget records in the input
        IF EXISTS (SELECT 1 FROM @Budget)
            BEGIN
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
                        [tip].[ProjectBudget] pb
                        INNER JOIN @Budget b
                                   ON pb.Id = b.Id
                    WHERE
                        pb.ProjectId = @Id; -- Only update records belonging to this project

                INSERT
                    INTO
                        [tip].[ProjectBudget]
                        ( Id, ProjectId, FundingSourceTypeId, PLSecuredAmount, PLUnsecuredAmount, PESecuredAmount
                        , PEUnsecuredAmount, ROWSecuredAmount, ROWUnsecuredAmount, CNSecuredAmount, CNUnsecuredAmount
                        , OtherSecuredAmount, OtherUnsecuredAmount, CreatedById, CreatedOn)
                SELECT
                    Id                   = b.Id
                  , ProjectId            = @Id -- Use procedure parameter, not client-provided value
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
                        NOT EXISTS (SELECT 1 FROM [tip].[ProjectBudget] pb WHERE pb.Id = b.Id);
            END;

        -- If we reach this point, all operations succeeded
        COMMIT;

    END TRY BEGIN CATCH
        -- If any error occurs, rollback all changes to maintain data integrity
        ROLLBACK;

        -- Re-throw the original error to the calling application
        THROW;
    END CATCH;
END;
GO
