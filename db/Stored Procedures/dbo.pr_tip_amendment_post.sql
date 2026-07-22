SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create Date: 2026-02-19
-- Modified:    2026-04-28 - Promote Project_Pending.ReportDescription to Project on amendment post
-- Description: Posts an amendment by validating review areas, upserting pending
--              data to main tables, creating posting log entries, and updating
--              the amendment status to 'posted'.
--
-- Purpose:     This procedure performs the complete posting workflow:
--              Step 1: Validate all review areas have 'ok' status
--              Step 2: Upsert data from _Pending tables to main tables
--                      - tip.Project_Pending -> tip.Project (UPDATE)
--                      - tip.ProjectBudget_Pending -> tip.ProjectBudget (DELETE + INSERT)
--                      - tip.ProgrammedFunding_Pending -> tip.ProgrammedFunding (DELETE + INSERT)
--                      - tip.ProjectCountyMapping_Pending -> tip.ProjectCountyMapping (DELETE + INSERT)
--                      - tip.ProjectImprovementTypeMapping_Pending -> tip.ProjectImprovementTypeMapping (DELETE + INSERT)
--              Step 3: Create posting log entries for each ProjectAmendment
--              Step 4: Update amendment status to 'posted'
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_amendment_post]
    @UserId      UNIQUEIDENTIFIER
, @AmendmentId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Now DATETIME2(7) = GETUTCDATE();
    DECLARE @PostedStatusId UNIQUEIDENTIFIER;
    DECLARE @PostingLogTypeId UNIQUEIDENTIFIER;
    DECLARE @OkStatusId UNIQUEIDENTIFIER;
    DECLARE @AmendmentStatusCode NVARCHAR(50);
    DECLARE @ErrorsJson NVARCHAR(MAX);

    -- Look up status/type IDs by code
    SELECT @PostedStatusId = Id
        FROM
            tip.AmendmentStatusType
        WHERE
            Code = 'posted';
    SELECT @PostingLogTypeId = Id
        FROM
            tip.ProjectAmendmentLogType
        WHERE
            Code = 'Posting Logs';
    SELECT @OkStatusId = Id
        FROM
            tip.ProjectAmendmentReviewAreaStatusType
        WHERE
            Code = 'ok';

    -- =============================================
    -- STEP 1: Validation
    -- =============================================

    -- Check amendment exists
    SELECT @AmendmentStatusCode = ast.Code
        FROM
            tip.Amendment                      AS a
            INNER JOIN tip.AmendmentStatusType AS ast
                       ON ast.Id = a.AmendmentStatusTypeId
        WHERE
            a.Id = @AmendmentId;

    IF @AmendmentStatusCode IS NULL
        BEGIN
            SELECT Success = CAST(0 AS BIT), Errors = N'["Amendment not found."]';
            RETURN 0;
        END;

    -- Check amendment is not already posted
    IF @AmendmentStatusCode = 'posted'
        BEGIN
            SELECT
                Success = CAST(0 AS BIT)
              , Errors  = N'["Amendment has already been posted."]';
            RETURN 0;
        END;

    -- Check all review areas have 'ok' status
    DECLARE @ReviewErrors TABLE
                          (
                              ErrorMessage NVARCHAR(500) NOT NULL
                          );

    INSERT INTO @ReviewErrors
               (ErrorMessage)
    SELECT CONCAT(pp.ProjectCode, ': Review area "', parat.Description, '" has status "', parast.Description, '"')
           FROM
               tip.ProjectAmendment                                AS pa
               INNER JOIN tip.ProjectAmendmentReviewArea           AS para
                          ON para.ProjectAmendmentId = pa.Id
               INNER JOIN tip.ProjectAmendmentReviewAreaType       AS parat
                          ON parat.Id                = para.ProjectAmendmentReviewAreaTypeId
               INNER JOIN tip.ProjectAmendmentReviewAreaStatusType AS parast
                          ON parast.Id               = para.ProjectAmendmentReviewAreaStatusTypeId
               INNER JOIN tip.Project_Pending                      AS pp
                          ON pp.ProjectAmendmentId   = pa.Id
           WHERE
                 pa.AmendmentId                                  = @AmendmentId
             AND para.ProjectAmendmentReviewAreaStatusTypeId <> @OkStatusId;

    IF EXISTS (SELECT 1 FROM @ReviewErrors)
        BEGIN
            SELECT @ErrorsJson = N'[' + STRING_AGG(N'"' + STRING_ESCAPE(ErrorMessage, 'json') + N'"', N',') + N']'
                FROM
                    @ReviewErrors;

            SELECT Success = CAST(0 AS BIT), Errors = @ErrorsJson;
            RETURN 0;
        END;

    -- =============================================
    -- STEPS 2-4: Upsert, Log, and Update Status (in transaction)
    -- =============================================
    BEGIN TRANSACTION;

    BEGIN TRY

        -- Temp table to hold ProjectAmendment data for cursor-free processing
        DECLARE @ProjectAmendments TABLE
                                   (
                                       ProjectAmendmentId UNIQUEIDENTIFIER NOT NULL
                                       , OriginalProjectId  UNIQUEIDENTIFIER NOT NULL
                                       , PendingProjectId   UNIQUEIDENTIFIER NOT NULL
                                   );

        INSERT INTO @ProjectAmendments
                   (ProjectAmendmentId, OriginalProjectId, PendingProjectId)
        SELECT
            pa.Id
          , pa.ProjectId
          , pp.Id
               FROM
                   tip.ProjectAmendment           AS pa
                   INNER JOIN tip.Project_Pending AS pp
                              ON pp.ProjectAmendmentId = pa.Id
               WHERE
                   pa.AmendmentId = @AmendmentId;

        -- =============================================
        -- STEP 2a: Update tip.Project from Project_Pending
        -- =============================================
        UPDATE p
        SET
            p.AgencyId = pp.AgencyId
          , p.Title = pp.Title
          , p.ContactId = pp.ContactId
          , p.WsDotPin = pp.WsDotPin
          , p.DemoId = pp.DemoId
          , p.Location = pp.Location
          , p.LocationFrom = pp.LocationFrom
          , p.LocationTo = pp.LocationTo
          , p.Length = pp.Length
          , p.FunctionalClassTypeId = pp.FunctionalClassTypeId
          , p.PrimaryImprovementTypeId = pp.PrimaryImprovementTypeId
          , p.Description = pp.Description
          , p.DateFullyImplemented = pp.DateFullyImplemented
          , p.RcpStatusTypeId = pp.RcpStatusTypeId
          , p.ConstantDollarProjectYear = pp.ConstantDollarProjectYear
          , p.MappedTypeId = pp.MappedTypeId
          , p.EnvironmentalStatusTypeId = pp.EnvironmentalStatusTypeId
          , p.RegionalSignificanceTypeId = pp.RegionalSignificanceTypeId
          , p.YearCompPL = pp.YearCompPL
          , p.YearCompPE = pp.YearCompPE
          , p.YearCompROW = pp.YearCompROW
          , p.YearCompCN = pp.YearCompCN
          , p.YearCompOther = pp.YearCompOther
          , p.DateCompProject = pp.DateCompProject
          , p.CaSponsorAgencyId = pp.CaSponsorAgencyId
          , p.CompletionStatusTypeId = pp.CompletionStatusTypeId
          , p.UpwpObjective = pp.UpwpObjective
          , p.UpwpTasks = pp.UpwpTasks
          , p.UpwpProducts = pp.UpwpProducts
          , p.UpwpPolicy = pp.UpwpPolicy
          , p.UpwpIsEquipmentPurchaseFlag = pp.UpwpIsEquipmentPurchaseFlag
          , p.PsrcComments = pp.PsrcComments
          , p.ReportDescription = pp.ReportDescription
          , p.UpdatedById = @UserId
          , p.UpdatedOn = @Now
            FROM
                tip.Project                    AS p
                INNER JOIN @ProjectAmendments  AS pam
                           ON pam.OriginalProjectId = p.Id
                INNER JOIN tip.Project_Pending AS pp
                           ON pp.Id                 = pam.PendingProjectId
            WHERE
                1 = 1;

        -- =============================================
        -- STEP 2b: ProjectBudget - DELETE + INSERT
        -- =============================================
        DELETE
            pb
            FROM
                tip.ProjectBudget             AS pb
                INNER JOIN @ProjectAmendments AS pam
                           ON pam.OriginalProjectId = pb.ProjectId
            WHERE
                1 = 1;

        INSERT INTO tip.ProjectBudget
                   (Id
                   , ProjectId
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
          , pam.OriginalProjectId
          , pbp.FundingSourceTypeId
          , pbp.PLSecuredAmount
          , pbp.PLUnsecuredAmount
          , pbp.PESecuredAmount
          , pbp.PEUnsecuredAmount
          , pbp.ROWSecuredAmount
          , pbp.ROWUnsecuredAmount
          , pbp.CNSecuredAmount
          , pbp.CNUnsecuredAmount
          , pbp.OtherSecuredAmount
          , pbp.OtherUnsecuredAmount
          , @UserId
          , @Now
               FROM
                   tip.ProjectBudget_Pending     AS pbp
                   INNER JOIN @ProjectAmendments AS pam
                              ON pam.PendingProjectId = pbp.Project_PendingId;

        -- =============================================
        -- STEP 2c: ProgrammedFunding - DELETE + INSERT
        -- =============================================
        DELETE
            pf
            FROM
                tip.ProgrammedFunding         AS pf
                INNER JOIN @ProjectAmendments AS pam
                           ON pam.OriginalProjectId = pf.ProjectId
            WHERE
                1 = 1;

        INSERT INTO tip.ProgrammedFunding
                   (Id
                   , ProjectId
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
            NEWID()
          , pam.OriginalProjectId
          , pfp.AwardReferenceId
          , pfp.PhaseTypeId
          , pfp.ProgrammedFundingYear
          , pfp.EstimatedObligationDate
          , pfp.FundingSourceTypeId
          , pfp.FundingAmount
          , pfp.IsObligatedFlag
          , pfp.FtaObligatedDate
          , pfp.FtaObligatedNumber
          , pfp.FhwaObligatedDate
          , pfp.FhwaObligatedNumber
          , pfp.OriginRecordId
          , pfp.IsActive
          , @UserId
          , @Now
               FROM
                   tip.ProgrammedFunding_Pending AS pfp
                   INNER JOIN @ProjectAmendments AS pam
                              ON pam.PendingProjectId = pfp.Project_PendingId;

        -- =============================================
        -- STEP 2d: ProjectCountyMapping - DELETE + INSERT
        -- =============================================
        DELETE
            pcm
            FROM
                tip.ProjectCountyMapping      AS pcm
                INNER JOIN @ProjectAmendments AS pam
                           ON pam.OriginalProjectId = pcm.ProjectId
            WHERE
                1 = 1;

        INSERT INTO tip.ProjectCountyMapping
                   (Id, ProjectId, CountyId, CreatedById, CreatedOn)
        SELECT
            NEWID()
          , pam.OriginalProjectId
          , pcmp.CountyId
          , @UserId
          , @Now
               FROM
                   tip.ProjectCountyMapping_Pending AS pcmp
                   INNER JOIN @ProjectAmendments    AS pam
                              ON pam.PendingProjectId = pcmp.ProjectId;

        -- =============================================
        -- STEP 2e: ProjectImprovementTypeMapping - DELETE + INSERT
        -- =============================================
        DELETE
            pitm
            FROM
                tip.ProjectImprovementTypeMapping AS pitm
                INNER JOIN @ProjectAmendments     AS pam
                           ON pam.OriginalProjectId = pitm.ProjectId
            WHERE
                1 = 1;

        INSERT INTO tip.ProjectImprovementTypeMapping
                   (Id, ProjectId, ImprovementTypeId, CreatedById, CreatedOn)
        SELECT
            NEWID()
          , pam.OriginalProjectId
          , pitmp.ImprovementTypeId
          , @UserId
          , @Now
               FROM
                   tip.ProjectImprovementTypeMapping_Pending AS pitmp
                   INNER JOIN @ProjectAmendments             AS pam
                              ON pam.PendingProjectId = pitmp.ProjectId;

        -- =============================================
        -- STEP 3: Create Posting Log entries
        -- =============================================
        INSERT INTO tip.ProjectAmendmentLog
                   (Id, ProjectAmendmentId, ProjectAmendmentLogTypeId, Description, RawChanges, CreatedById, CreatedOn)
        SELECT
            NEWID()
          , pam.ProjectAmendmentId
          , @PostingLogTypeId
          , CONCAT('Amendment posted - ', ISNULL(logCounts.ChangeCount, 0), ' change(s) applied')
          , logAgg.AggregatedChanges
          , @UserId
          , @Now
               FROM
                   @ProjectAmendments AS pam
                   OUTER APPLY (
                       SELECT ChangeCount = COUNT(*)
                           FROM
                               tip.ProjectAmendmentLog AS pal
                           WHERE
                                 pal.ProjectAmendmentId            = pam.ProjectAmendmentId
                             AND pal.ProjectAmendmentLogTypeId <> @PostingLogTypeId
                   )      AS logCounts
                   OUTER APPLY (
                       SELECT AggregatedChanges = N'[' + STRING_AGG(changes.singleChange, N',') + N']'
                           FROM (
                               SELECT
                                   singleChange = CASE
                                                      WHEN ISJSON(pal2.RawChanges) = 1
                                                          AND LEFT(LTRIM(pal2.RawChanges), 1) = '[' THEN
                                                          SUBSTRING(LTRIM(pal2.RawChanges), 2, LEN(LTRIM(pal2.RawChanges)) - 2)
                                                      WHEN ISJSON(pal2.RawChanges) = 1 THEN pal2.RawChanges
                                                      ELSE NULL
                                                  END
                                   FROM
                                       tip.ProjectAmendmentLog AS pal2
                                   WHERE
                                         pal2.ProjectAmendmentId            = pam.ProjectAmendmentId
                                     AND pal2.RawChanges IS NOT NULL
                                     AND pal2.ProjectAmendmentLogTypeId <> @PostingLogTypeId
                           ) AS changes
                           WHERE
                               changes.singleChange IS NOT NULL
                   ) AS logAgg;

        -- =============================================
        -- STEP 4: Update Amendment status to 'posted'
        -- =============================================
        UPDATE tip.Amendment
        SET
            AmendmentStatusTypeId = @PostedStatusId
          , UpdatedById = @UserId
          , UpdatedOn = @Now
            WHERE
                Id = @AmendmentId;

        COMMIT TRANSACTION;

        -- Return success
        SELECT Success = CAST(1 AS BIT), Errors = CAST(NULL AS NVARCHAR(MAX));

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
