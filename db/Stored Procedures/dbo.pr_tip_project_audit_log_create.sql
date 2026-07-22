SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create Date: 2025-12-26
-- Modified:    2025-12-26 - Changed to merge changes into existing log records
-- Modified:    2026-02-17 - Preserve original oldValue on re-changes, per-field timestamps, revert detection
-- Modified:    2026-02-20 - Add display value resolution for ProgrammedFunding fields
-- Modified:    2026-02-20 - Use SubAwardReference/AwardRef fallback and conditionally include award ref in label
-- Modified:    2026-02-20 - Include all funding fields in audit (obligation dates, flags, numbers) via XML parsing
-- Modified:    2026-02-20 - Add Award Reference to Modified display so NULL-to-value changes are logged
-- Modified:    2026-03-31 - Switch to per-subfield funding changes to fix merge bug with sequential saves
-- Modified:    2026-04-02 - Display funding source Description instead of Code in audit log labels
-- Description: Creates or updates audit log records for TIP project field changes.
--              Handles both regular project updates (creates administrative amendment)
--              and amendment workflow updates (uses provided amendment).
--
-- Features:
--   - Filters to only changed fields (OldValue != NewValue or NULL handling)
--   - Categorizes changes by FieldCategory to create appropriate log type records
--   - Creates Administrative Amendment when @AmendmentId is NULL
--   - Reuses existing administrative amendment for same project/date
--   - MERGES changes into existing log record (one log per ProjectAmendment + LogType)
--   - Preserves original oldValue when same field is re-changed
--   - Removes field from log if value is reverted to original
--   - Deletes log entry entirely if all fields are reverted
--   - Tracks userId, userEmail, changedOn at field level (per-field timestamps)
--   - Returns generated/updated log IDs
--
-- Field Categories:
--   'Phase' -> Phase Logs
--   'Administrative' -> Administrative Logs
--   'Amendment' -> Amendment Logs
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_audit_log_create]
    @UserId            UNIQUEIDENTIFIER,           -- ID of the user making the changes
    @ProjectId         UNIQUEIDENTIFIER,           -- ID of the project being modified
    @AmendmentId       UNIQUEIDENTIFIER = NULL,    -- NULL for regular updates (creates admin amendment)
    @ProjectAmendmentId UNIQUEIDENTIFIER = NULL,   -- NULL for regular updates (creates project amendment)
    @FieldChanges      dbo.ProjectFieldChangeType READONLY -- Table of field changes
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- =============================================
    -- LOOKUP: Log Type IDs (by Code to support different environments)
    -- =============================================
    DECLARE @AmendmentLogTypeId UNIQUEIDENTIFIER;
    DECLARE @PhaseLogTypeId UNIQUEIDENTIFIER;
    DECLARE @AdministrativeLogTypeId UNIQUEIDENTIFIER;

    SELECT @AmendmentLogTypeId = Id FROM tip.ProjectAmendmentLogType WHERE Code = 'Amendment Logs';
    SELECT @PhaseLogTypeId = Id FROM tip.ProjectAmendmentLogType WHERE Code = 'Phase Logs';
    SELECT @AdministrativeLogTypeId = Id FROM tip.ProjectAmendmentLogType WHERE Code = 'Administrative Logs';

    -- =============================================
    -- LOOKUP: Amendment Status and Section Types (by Code to support different environments)
    -- =============================================
    DECLARE @PostedStatusId UNIQUEIDENTIFIER;
    DECLARE @DefaultSectionTypeId UNIQUEIDENTIFIER;
    DECLARE @CompleteReviewStatusId UNIQUEIDENTIFIER;

    SELECT @PostedStatusId = Id FROM tip.AmendmentStatusType WHERE Code = 'Posted';
    SELECT @DefaultSectionTypeId = Id FROM tip.AmendmentSectionType WHERE Code = 'A';
    SELECT @CompleteReviewStatusId = Id FROM tip.ProjectAmendmentReviewStatusType WHERE Code = 'Complete';

    DECLARE @Now DATETIME2(7) = GETUTCDATE();
    DECLARE @Today DATE = CAST(@Now AS DATE);

    -- =============================================
    -- STEP 1: Filter to only changed fields
    -- =============================================
    -- Create temp table with only fields that actually changed
    DECLARE @ChangedFields Table(
        FieldName        NVARCHAR(200) NOT NULL,
        OldValue         NVARCHAR(MAX) NULL,
        NewValue         NVARCHAR(MAX) NULL,
        OldValueDisplay  NVARCHAR(500) NULL,
        NewValueDisplay  NVARCHAR(500) NULL,
        FieldCategory    NVARCHAR(50)  NOT NULL
    );

    INSERT INTO @ChangedFields (FieldName, OldValue, NewValue, OldValueDisplay, NewValueDisplay, FieldCategory)
    SELECT FieldName, OldValue, NewValue, OldValueDisplay, NewValueDisplay, FieldCategory
    FROM @FieldChanges
    WHERE (OldValue IS NULL AND NewValue IS NOT NULL)
       OR (OldValue IS NOT NULL AND NewValue IS NULL)
       OR (OldValue <> NewValue);

    -- =============================================
    -- STEP 1b: Resolve display values for GUID reference fields
    -- =============================================
    -- Agency
    UPDATE cf SET OldValueDisplay = a.Name
    FROM @ChangedFields cf
    INNER JOIN common.Agency a ON TRY_CAST(cf.OldValue AS UNIQUEIDENTIFIER) = a.Id
    WHERE cf.FieldName = 'AgencyId' AND cf.OldValue IS NOT NULL AND cf.OldValueDisplay IS NULL;

    UPDATE cf SET NewValueDisplay = a.Name
    FROM @ChangedFields cf
    INNER JOIN common.Agency a ON TRY_CAST(cf.NewValue AS UNIQUEIDENTIFIER) = a.Id
    WHERE cf.FieldName = 'AgencyId' AND cf.NewValue IS NOT NULL AND cf.NewValueDisplay IS NULL;

    -- CaSponsorAgency (also uses common.Agency)
    UPDATE cf SET OldValueDisplay = a.Name
    FROM @ChangedFields cf
    INNER JOIN common.Agency a ON TRY_CAST(cf.OldValue AS UNIQUEIDENTIFIER) = a.Id
    WHERE cf.FieldName = 'CaSponsorAgencyId' AND cf.OldValue IS NOT NULL AND cf.OldValueDisplay IS NULL;

    UPDATE cf SET NewValueDisplay = a.Name
    FROM @ChangedFields cf
    INNER JOIN common.Agency a ON TRY_CAST(cf.NewValue AS UNIQUEIDENTIFIER) = a.Id
    WHERE cf.FieldName = 'CaSponsorAgencyId' AND cf.NewValue IS NOT NULL AND cf.NewValueDisplay IS NULL;

    -- Contact
    UPDATE cf SET OldValueDisplay = CONCAT(c.FirstName, ' ', c.LastName)
    FROM @ChangedFields cf
    INNER JOIN common.Contact c ON TRY_CAST(cf.OldValue AS UNIQUEIDENTIFIER) = c.Id
    WHERE cf.FieldName = 'ContactId' AND cf.OldValue IS NOT NULL AND cf.OldValueDisplay IS NULL;

    UPDATE cf SET NewValueDisplay = CONCAT(c.FirstName, ' ', c.LastName)
    FROM @ChangedFields cf
    INNER JOIN common.Contact c ON TRY_CAST(cf.NewValue AS UNIQUEIDENTIFIER) = c.Id
    WHERE cf.FieldName = 'ContactId' AND cf.NewValue IS NOT NULL AND cf.NewValueDisplay IS NULL;

    -- County (handles comma-separated GUIDs for many-to-many relationships)
    UPDATE cf SET OldValueDisplay = (
        SELECT STRING_AGG(c.Description, ', ') WITHIN GROUP (ORDER BY c.Description)
        FROM STRING_SPLIT(cf.OldValue, ',') s
        INNER JOIN common.County c ON TRY_CAST(TRIM(s.value) AS UNIQUEIDENTIFIER) = c.Id
    )
    FROM @ChangedFields cf
    WHERE cf.FieldName = 'County' AND cf.OldValue IS NOT NULL AND cf.OldValueDisplay IS NULL;

    UPDATE cf SET NewValueDisplay = (
        SELECT STRING_AGG(c.Description, ', ') WITHIN GROUP (ORDER BY c.Description)
        FROM STRING_SPLIT(cf.NewValue, ',') s
        INNER JOIN common.County c ON TRY_CAST(TRIM(s.value) AS UNIQUEIDENTIFIER) = c.Id
    )
    FROM @ChangedFields cf
    WHERE cf.FieldName = 'County' AND cf.NewValue IS NOT NULL AND cf.NewValueDisplay IS NULL;

    -- FunctionalClassType
    UPDATE cf SET OldValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.FunctionalClassType t ON TRY_CAST(cf.OldValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'FunctionalClassTypeId' AND cf.OldValue IS NOT NULL AND cf.OldValueDisplay IS NULL;

    UPDATE cf SET NewValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.FunctionalClassType t ON TRY_CAST(cf.NewValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'FunctionalClassTypeId' AND cf.NewValue IS NOT NULL AND cf.NewValueDisplay IS NULL;

    -- PrimaryImprovementType (single GUID)
    UPDATE cf SET OldValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.ImprovementType t ON TRY_CAST(cf.OldValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'PrimaryImprovementTypeId' AND cf.OldValue IS NOT NULL AND cf.OldValueDisplay IS NULL;

    UPDATE cf SET NewValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.ImprovementType t ON TRY_CAST(cf.NewValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'PrimaryImprovementTypeId' AND cf.NewValue IS NOT NULL AND cf.NewValueDisplay IS NULL;

    -- SecondaryImprovementType (handles comma-separated GUIDs for many-to-many relationships)
    UPDATE cf SET OldValueDisplay = (
        SELECT STRING_AGG(t.Description, ', ') WITHIN GROUP (ORDER BY t.Description)
        FROM STRING_SPLIT(cf.OldValue, ',') s
        INNER JOIN tip.ImprovementType t ON TRY_CAST(TRIM(s.value) AS UNIQUEIDENTIFIER) = t.Id
    )
    FROM @ChangedFields cf
    WHERE cf.FieldName = 'SecondaryImprovementType' AND cf.OldValue IS NOT NULL AND cf.OldValueDisplay IS NULL;

    UPDATE cf SET NewValueDisplay = (
        SELECT STRING_AGG(t.Description, ', ') WITHIN GROUP (ORDER BY t.Description)
        FROM STRING_SPLIT(cf.NewValue, ',') s
        INNER JOIN tip.ImprovementType t ON TRY_CAST(TRIM(s.value) AS UNIQUEIDENTIFIER) = t.Id
    )
    FROM @ChangedFields cf
    WHERE cf.FieldName = 'SecondaryImprovementType' AND cf.NewValue IS NOT NULL AND cf.NewValueDisplay IS NULL;

    -- MappedType
    UPDATE cf SET OldValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.MappedType t ON TRY_CAST(cf.OldValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'MappedTypeId' AND cf.OldValue IS NOT NULL AND cf.OldValueDisplay IS NULL;

    UPDATE cf SET NewValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.MappedType t ON TRY_CAST(cf.NewValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'MappedTypeId' AND cf.NewValue IS NOT NULL AND cf.NewValueDisplay IS NULL;

    -- EnvironmentalStatusType
    UPDATE cf SET OldValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.EnvironmentalStatusType t ON TRY_CAST(cf.OldValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'EnvironmentalStatusTypeId' AND cf.OldValue IS NOT NULL AND cf.OldValueDisplay IS NULL;

    UPDATE cf SET NewValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.EnvironmentalStatusType t ON TRY_CAST(cf.NewValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'EnvironmentalStatusTypeId' AND cf.NewValue IS NOT NULL AND cf.NewValueDisplay IS NULL;

    -- RcpStatusType
    UPDATE cf SET OldValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.RcpStatusType t ON TRY_CAST(cf.OldValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'RcpStatusTypeId' AND cf.OldValue IS NOT NULL AND cf.OldValueDisplay IS NULL;

    UPDATE cf SET NewValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.RcpStatusType t ON TRY_CAST(cf.NewValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'RcpStatusTypeId' AND cf.NewValue IS NOT NULL AND cf.NewValueDisplay IS NULL;

    -- RegionalSignificanceType
    UPDATE cf SET OldValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.RegionalSignificanceType t ON TRY_CAST(cf.OldValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'RegionalSignificanceTypeId' AND cf.OldValue IS NOT NULL AND cf.OldValueDisplay IS NULL;

    UPDATE cf SET NewValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.RegionalSignificanceType t ON TRY_CAST(cf.NewValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'RegionalSignificanceTypeId' AND cf.NewValue IS NOT NULL AND cf.NewValueDisplay IS NULL;

    -- CompletionStatusType
    UPDATE cf SET OldValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.CompletionStatusType t ON TRY_CAST(cf.OldValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'CompletionStatusTypeId' AND cf.OldValue IS NOT NULL AND cf.OldValueDisplay IS NULL;

    UPDATE cf SET NewValueDisplay = t.Description
    FROM @ChangedFields cf
    INNER JOIN tip.CompletionStatusType t ON TRY_CAST(cf.NewValue AS UNIQUEIDENTIFIER) = t.Id
    WHERE cf.FieldName = 'CompletionStatusTypeId' AND cf.NewValue IS NOT NULL AND cf.NewValueDisplay IS NULL;

    -- ProgrammedFunding per-subfield display resolution
    -- FieldName format: ProgrammedFunding:{fundingSourceTypeId}|{phaseTypeId}|{year}:{SubFieldName}
    -- Extract composite key parts from FieldName for the display label
    -- Resolve to "Programmed Funding (AwardRef - Phase - Year) SubFieldLabel" display format

    -- Parse the composite key parts from the FieldName
    -- FieldName structure: ProgrammedFunding:{compositeKey}:{SubFieldName}
    -- compositeKey structure: {fundingSourceTypeId}|{phaseTypeId}|{year}
    UPDATE cf SET
        FieldName = 'Programmed Funding ('
            + ISNULL(fst.Description, '')
            + ' - '
            + ISNULL(pt.Code, '')
            + ' - '
            + ISNULL(keyParts.FundingYear, '')
            + CASE
                WHEN ar.Id IS NOT NULL
                    THEN ' - ' + COALESCE(NULLIF(ar.SubAwardReference, ''), ar.AwardRef)
                ELSE ''
              END
            + ') '
            + CASE parts.SubFieldName
                WHEN 'AwardReferenceId' THEN 'Award Ref'
                WHEN 'Amount' THEN 'Amount'
                WHEN 'EstimatedObligationDate' THEN 'Est Oblig Date'
                WHEN 'IsObligatedFlag' THEN 'Obligated'
                WHEN 'FtaObligatedDate' THEN 'FTA Date'
                WHEN 'FtaObligatedNumber' THEN 'FTA #'
                WHEN 'FhwaObligatedDate' THEN 'FHWA Date'
                WHEN 'FhwaObligatedNumber' THEN 'FHWA #'
                ELSE parts.SubFieldName
              END,
        OldValueDisplay = CASE WHEN cf.OldValue IS NULL THEN NULL
            ELSE CASE parts.SubFieldName
                WHEN 'AwardReferenceId' THEN ISNULL(COALESCE(NULLIF(oldAr.SubAwardReference, ''), oldAr.AwardRef), '(none)')
                WHEN 'Amount' THEN '$' + FORMAT(TRY_CAST(cf.OldValue AS BIGINT), 'N0')
                WHEN 'IsObligatedFlag' THEN CASE cf.OldValue WHEN '1' THEN 'Yes' WHEN '0' THEN 'No' ELSE '(none)' END
                ELSE ISNULL(NULLIF(cf.OldValue, ''), '(none)')
            END END,
        NewValueDisplay = CASE WHEN cf.NewValue IS NULL THEN NULL
            ELSE CASE parts.SubFieldName
                WHEN 'AwardReferenceId' THEN ISNULL(COALESCE(NULLIF(newAr.SubAwardReference, ''), newAr.AwardRef), '(none)')
                WHEN 'Amount' THEN '$' + FORMAT(TRY_CAST(cf.NewValue AS BIGINT), 'N0')
                WHEN 'IsObligatedFlag' THEN CASE cf.NewValue WHEN '1' THEN 'Yes' WHEN '0' THEN 'No' ELSE '(none)' END
                ELSE ISNULL(NULLIF(cf.NewValue, ''), '(none)')
            END END
    FROM @ChangedFields cf
    -- Parse composite key and subfield name from FieldName
    -- FieldName = 'ProgrammedFunding:{fstId}|{phaseTypeId}|{year}:{SubFieldName}'
    -- Uses IIF guards to prevent negative SUBSTRING lengths for non-funding rows
    CROSS APPLY (
        SELECT
            CHARINDEX(':', REVERSE(cf.FieldName)) AS RevColonPos
    ) rc
    CROSS APPLY (
        SELECT
            IIF(rc.RevColonPos > 0, LEN(cf.FieldName) - rc.RevColonPos + 1, 0) AS LastColonPos
    ) lc
    CROSS APPLY (
        SELECT
            IIF(lc.LastColonPos > 19, SUBSTRING(cf.FieldName, 19, lc.LastColonPos - 19), '') AS CompositeKey,
            IIF(lc.LastColonPos > 0, SUBSTRING(cf.FieldName, lc.LastColonPos + 1, LEN(cf.FieldName)), '') AS SubFieldName
    ) parts
    CROSS APPLY (
        SELECT
            PARSENAME(REPLACE(parts.CompositeKey, '|', '.'), 3) AS FundingSourceTypeId,
            PARSENAME(REPLACE(parts.CompositeKey, '|', '.'), 2) AS PhaseTypeId,
            PARSENAME(REPLACE(parts.CompositeKey, '|', '.'), 1) AS FundingYear
    ) keyParts
    -- Look up FundingSourceType for label
    LEFT JOIN tip.FundingSourceType fst
        ON TRY_CAST(NULLIF(keyParts.FundingSourceTypeId, '') AS UNIQUEIDENTIFIER) = fst.Id
    -- Look up PhaseType for label
    LEFT JOIN tip.PhaseType pt
        ON TRY_CAST(NULLIF(keyParts.PhaseTypeId, '') AS UNIQUEIDENTIFIER) = pt.Id
    -- Look up AwardReference display for AwardReferenceId subfield values
    LEFT JOIN tip.AwardReference oldAr
        ON parts.SubFieldName = 'AwardReferenceId'
        AND TRY_CAST(NULLIF(cf.OldValue, '') AS UNIQUEIDENTIFIER) = oldAr.Id
    LEFT JOIN tip.AwardReference newAr
        ON parts.SubFieldName = 'AwardReferenceId'
        AND TRY_CAST(NULLIF(cf.NewValue, '') AS UNIQUEIDENTIFIER) = newAr.Id
    -- Look up AwardReference for the funding row label (from any AwardReferenceId subfield in same batch)
    LEFT JOIN tip.AwardReference ar
        ON ar.Id = (
            SELECT TOP 1 TRY_CAST(NULLIF(COALESCE(cf2.NewValue, cf2.OldValue), '') AS UNIQUEIDENTIFIER)
            FROM @ChangedFields cf2
            WHERE cf2.FieldName LIKE 'ProgrammedFunding:' + parts.CompositeKey + ':AwardReferenceId'
        )
    WHERE cf.FieldName LIKE 'ProgrammedFunding:%';

    -- If no changes, exit early
    IF NOT EXISTS (SELECT 1 FROM @ChangedFields)
    BEGIN
        -- Return empty result set for consistency
        SELECT CAST(NULL AS UNIQUEIDENTIFIER) AS LogId WHERE 1 = 0;
        RETURN 0;
    END;

    -- =============================================
    -- STEP 2: Group changes by category
    -- =============================================
    DECLARE @HasPhaseChanges BIT = 0;
    DECLARE @HasAdminChanges BIT = 0;
    DECLARE @HasAmendmentChanges BIT = 0;

    IF EXISTS (SELECT 1 FROM @ChangedFields WHERE FieldCategory = 'Phase')
        SET @HasPhaseChanges = 1;
    IF EXISTS (SELECT 1 FROM @ChangedFields WHERE FieldCategory = 'Administrative')
        SET @HasAdminChanges = 1;
    IF EXISTS (SELECT 1 FROM @ChangedFields WHERE FieldCategory = 'Amendment')
        SET @HasAmendmentChanges = 1;

    -- =============================================
    -- STEP 3: Handle Amendment/ProjectAmendment creation if needed
    -- =============================================
    DECLARE @EffectiveAmendmentId UNIQUEIDENTIFIER = @AmendmentId;
    DECLARE @EffectiveProjectAmendmentId UNIQUEIDENTIFIER = @ProjectAmendmentId;

    BEGIN TRANSACTION;

    BEGIN TRY
        IF @AmendmentId IS NULL
        BEGIN
            -- Regular project update - need administrative amendment
            -- First, check if an administrative amendment exists for this project today
            DECLARE @ProjectCode NVARCHAR(50);
            SELECT @ProjectCode = ProjectCode FROM tip.Project WHERE Id = @ProjectId;

            DECLARE @ExpectedAmendmentName NVARCHAR(50) = 'Admin-' + CONVERT(NVARCHAR(10), @Today, 23) + '-' + ISNULL(@ProjectCode, 'UNKNOWN');

            -- Check for existing administrative amendment for this project today
            SELECT TOP (1)
                @EffectiveAmendmentId = a.Id,
                @EffectiveProjectAmendmentId = pa.Id
            FROM tip.Amendment a
            INNER JOIN tip.ProjectAmendment pa ON pa.AmendmentId = a.Id
            WHERE a.IsAdministrativeAmendmentFlag = 1
              AND a.Name = @ExpectedAmendmentName
              AND pa.ProjectId = @ProjectId
              AND CAST(a.CreatedOn AS DATE) = @Today
            ORDER BY a.CreatedOn DESC;

            -- If no existing administrative amendment, create one
            IF @EffectiveAmendmentId IS NULL
            BEGIN
                SET @EffectiveAmendmentId = NEWID();
                SET @EffectiveProjectAmendmentId = NEWID();

                -- Create Amendment with IsAdministrativeAmendmentFlag = TRUE
                INSERT INTO tip.Amendment
                    (Id, AmendmentStatusTypeId, Name, IsAdministrativeAmendmentFlag, EffectiveDate, CreatedById, CreatedOn)
                VALUES
                    (@EffectiveAmendmentId, @PostedStatusId, @ExpectedAmendmentName, 1, @Today, @UserId, @Now);

                -- Create ProjectAmendment linking project to amendment
                INSERT INTO tip.ProjectAmendment
                    (Id, ProjectId, AmendmentId, AmendmentSectionTypeId, ProjectAmendmentReviewStatusTypeId, CreatedById, CreatedOn)
                VALUES
                    (@EffectiveProjectAmendmentId, @ProjectId, @EffectiveAmendmentId, @DefaultSectionTypeId, @CompleteReviewStatusId, @UserId, @Now);
            END;
        END
        ELSE IF @ProjectAmendmentId IS NULL
        BEGIN
            -- Amendment provided but no ProjectAmendment - find or create it
            SELECT TOP (1) @EffectiveProjectAmendmentId = Id
            FROM tip.ProjectAmendment
            WHERE ProjectId = @ProjectId AND AmendmentId = @AmendmentId
            ORDER BY Id;

            IF @EffectiveProjectAmendmentId IS NULL
            BEGIN
                SET @EffectiveProjectAmendmentId = NEWID();

                INSERT INTO tip.ProjectAmendment
                    (Id, ProjectId, AmendmentId, AmendmentSectionTypeId, ProjectAmendmentReviewStatusTypeId, CreatedById, CreatedOn)
                VALUES
                    (@EffectiveProjectAmendmentId, @ProjectId, @EffectiveAmendmentId, @DefaultSectionTypeId, @CompleteReviewStatusId, @UserId, @Now);
            END;
        END;

        -- =============================================
        -- STEP 4: Create or update log records for each category with changes
        -- =============================================
        -- Get user email for field-level tracking
        DECLARE @UserEmail NVARCHAR(256);
        SELECT @UserEmail = Email FROM common.Users WHERE Id = @UserId;

        -- Table to collect generated/updated log IDs
        DECLARE @GeneratedLogIds TABLE (LogId UNIQUEIDENTIFIER NOT NULL);

        -- 4a: Handle Phase Log if phase changes exist
        IF @HasPhaseChanges = 1
        BEGIN
            DECLARE @PhaseLogId UNIQUEIDENTIFIER;
            DECLARE @ExistingPhaseJson NVARCHAR(MAX);

            -- Check for existing log record
            SELECT @PhaseLogId = Id, @ExistingPhaseJson = RawChanges
            FROM tip.ProjectAmendmentLog
            WHERE ProjectAmendmentId = @EffectiveProjectAmendmentId
              AND ProjectAmendmentLogTypeId = @PhaseLogTypeId;

            -- Build JSON for new phase changes (includes user info at field level)
            DECLARE @NewPhaseChangesJson NVARCHAR(MAX);
            SELECT @NewPhaseChangesJson = (
                SELECT
                    FieldName AS [field],
                    COALESCE(OldValueDisplay, OldValue) AS [oldValue],
                    COALESCE(NewValueDisplay, NewValue) AS [newValue],
                    CASE
                        WHEN OldValue IS NULL AND NewValue IS NOT NULL THEN 'Added'
                        WHEN OldValue IS NOT NULL AND NewValue IS NULL THEN 'Removed'
                        ELSE 'Modified'
                    END AS [changeType],
                    LOWER(CAST(@UserId AS NVARCHAR(36))) AS [changedById],
                    @UserEmail AS [changedByEmail],
                    @Now AS [changedOn]
                FROM @ChangedFields
                WHERE FieldCategory = 'Phase'
                FOR JSON PATH
            );

            IF @PhaseLogId IS NOT NULL
            BEGIN
                -- Merge with existing record
                DECLARE @MergedPhaseJson NVARCHAR(MAX);

                -- Parse existing JSON and merge (new values overwrite existing for same field)
                WITH ExistingFields AS (
                    SELECT
                        JSON_VALUE(value, '$.field') AS field,
                        JSON_VALUE(value, '$.oldValue') AS oldValue,
                        JSON_VALUE(value, '$.newValue') AS newValue,
                        JSON_VALUE(value, '$.changeType') AS changeType,
                        JSON_VALUE(value, '$.changedById') AS changedById,
                        JSON_VALUE(value, '$.changedByEmail') AS changedByEmail,
                        JSON_VALUE(value, '$.changedOn') AS changedOn
                    FROM OPENJSON(@ExistingPhaseJson)
                ),
                NewFields AS (
                    SELECT
                        JSON_VALUE(value, '$.field') AS field,
                        JSON_VALUE(value, '$.oldValue') AS oldValue,
                        JSON_VALUE(value, '$.newValue') AS newValue,
                        JSON_VALUE(value, '$.changeType') AS changeType,
                        JSON_VALUE(value, '$.changedById') AS changedById,
                        JSON_VALUE(value, '$.changedByEmail') AS changedByEmail,
                        JSON_VALUE(value, '$.changedOn') AS changedOn
                    FROM OPENJSON(@NewPhaseChangesJson)
                ),
                MergedFields AS (
                    -- 1) Existing fields NOT touched in this save - preserve everything
                    SELECT e.field, e.oldValue, e.newValue, e.changeType, e.changedById, e.changedByEmail, e.changedOn
                    FROM ExistingFields e
                    WHERE NOT EXISTS (SELECT 1 FROM NewFields n WHERE n.field = e.field)
                    UNION ALL
                    -- 2) Brand-new fields (first time this field appears in the log)
                    SELECT n.field, n.oldValue, n.newValue, n.changeType, n.changedById, n.changedByEmail, n.changedOn
                    FROM NewFields n
                    WHERE NOT EXISTS (SELECT 1 FROM ExistingFields e WHERE e.field = n.field)
                    UNION ALL
                    -- 3) Re-changed fields: preserve original oldValue, update newValue + metadata
                    SELECT n.field, e.oldValue, n.newValue,
                        CASE
                            WHEN e.oldValue IS NULL AND n.newValue IS NOT NULL THEN 'Added'
                            WHEN e.oldValue IS NOT NULL AND n.newValue IS NULL THEN 'Removed'
                            ELSE 'Modified'
                        END,
                        n.changedById, n.changedByEmail, n.changedOn
                    FROM NewFields n
                    INNER JOIN ExistingFields e ON e.field = n.field
                ),
                -- 4) Remove reverted fields (value changed back to original)
                FilteredFields AS (
                    SELECT field, oldValue, newValue, changeType, changedById, changedByEmail, changedOn
                    FROM MergedFields
                    WHERE NOT (oldValue IS NOT NULL AND newValue IS NOT NULL AND oldValue = newValue)
                )
                SELECT @MergedPhaseJson = (
                    SELECT field, oldValue, newValue, changeType, changedById, changedByEmail, changedOn
                    FROM FilteredFields
                    ORDER BY field
                    FOR JSON PATH
                );

                IF @MergedPhaseJson IS NULL OR @MergedPhaseJson = '[]'
                BEGIN
                    DELETE FROM tip.ProjectAmendmentLog WHERE Id = @PhaseLogId;
                END
                ELSE
                BEGIN
                    -- Build description with unique user emails
                    DECLARE @PhaseUsers NVARCHAR(MAX);
                    WITH AllUsers AS (
                        SELECT DISTINCT JSON_VALUE(value, '$.changedByEmail') AS email
                        FROM OPENJSON(@MergedPhaseJson)
                    )
                    SELECT @PhaseUsers = STRING_AGG(email, ', ') FROM AllUsers WHERE email IS NOT NULL;

                    UPDATE tip.ProjectAmendmentLog
                    SET RawChanges = @MergedPhaseJson,
                        Description = 'Phase changes by: ' + ISNULL(@PhaseUsers, 'Unknown'),
                        UpdatedById = @UserId,
                        UpdatedOn = @Now
                    WHERE Id = @PhaseLogId;

                    INSERT INTO @GeneratedLogIds (LogId) VALUES (@PhaseLogId);
                END;
            END
            ELSE
            BEGIN
                -- Create new log record
                SET @PhaseLogId = NEWID();

                INSERT INTO tip.ProjectAmendmentLog
                    (Id, ProjectAmendmentId, ProjectAmendmentLogTypeId, Description, RawChanges, CreatedById, CreatedOn)
                VALUES
                    (@PhaseLogId, @EffectiveProjectAmendmentId, @PhaseLogTypeId,
                     'Phase changes by: ' + ISNULL(@UserEmail, 'Unknown'), @NewPhaseChangesJson, @UserId, @Now);

                INSERT INTO @GeneratedLogIds (LogId) VALUES (@PhaseLogId);
            END;
        END;

        -- 4b: Handle Administrative Log if administrative changes exist
        IF @HasAdminChanges = 1
        BEGIN
            DECLARE @AdminLogId UNIQUEIDENTIFIER;
            DECLARE @ExistingAdminJson NVARCHAR(MAX);

            -- Check for existing log record
            SELECT @AdminLogId = Id, @ExistingAdminJson = RawChanges
            FROM tip.ProjectAmendmentLog
            WHERE ProjectAmendmentId = @EffectiveProjectAmendmentId
              AND ProjectAmendmentLogTypeId = @AdministrativeLogTypeId;

            -- Build JSON for new admin changes
            DECLARE @NewAdminChangesJson NVARCHAR(MAX);
            SELECT @NewAdminChangesJson = (
                SELECT
                    FieldName AS [field],
                    COALESCE(OldValueDisplay, OldValue) AS [oldValue],
                    COALESCE(NewValueDisplay, NewValue) AS [newValue],
                    CASE
                        WHEN OldValue IS NULL AND NewValue IS NOT NULL THEN 'Added'
                        WHEN OldValue IS NOT NULL AND NewValue IS NULL THEN 'Removed'
                        ELSE 'Modified'
                    END AS [changeType],
                    LOWER(CAST(@UserId AS NVARCHAR(36))) AS [changedById],
                    @UserEmail AS [changedByEmail],
                    @Now AS [changedOn]
                FROM @ChangedFields
                WHERE FieldCategory = 'Administrative'
                FOR JSON PATH
            );

            IF @AdminLogId IS NOT NULL
            BEGIN
                -- Merge with existing record
                DECLARE @MergedAdminJson NVARCHAR(MAX);

                WITH ExistingFields AS (
                    SELECT
                        JSON_VALUE(value, '$.field') AS field,
                        JSON_VALUE(value, '$.oldValue') AS oldValue,
                        JSON_VALUE(value, '$.newValue') AS newValue,
                        JSON_VALUE(value, '$.changeType') AS changeType,
                        JSON_VALUE(value, '$.changedById') AS changedById,
                        JSON_VALUE(value, '$.changedByEmail') AS changedByEmail,
                        JSON_VALUE(value, '$.changedOn') AS changedOn
                    FROM OPENJSON(@ExistingAdminJson)
                ),
                NewFields AS (
                    SELECT
                        JSON_VALUE(value, '$.field') AS field,
                        JSON_VALUE(value, '$.oldValue') AS oldValue,
                        JSON_VALUE(value, '$.newValue') AS newValue,
                        JSON_VALUE(value, '$.changeType') AS changeType,
                        JSON_VALUE(value, '$.changedById') AS changedById,
                        JSON_VALUE(value, '$.changedByEmail') AS changedByEmail,
                        JSON_VALUE(value, '$.changedOn') AS changedOn
                    FROM OPENJSON(@NewAdminChangesJson)
                ),
                MergedFields AS (
                    -- 1) Existing fields NOT touched in this save - preserve everything
                    SELECT e.field, e.oldValue, e.newValue, e.changeType, e.changedById, e.changedByEmail, e.changedOn
                    FROM ExistingFields e
                    WHERE NOT EXISTS (SELECT 1 FROM NewFields n WHERE n.field = e.field)
                    UNION ALL
                    -- 2) Brand-new fields (first time this field appears in the log)
                    SELECT n.field, n.oldValue, n.newValue, n.changeType, n.changedById, n.changedByEmail, n.changedOn
                    FROM NewFields n
                    WHERE NOT EXISTS (SELECT 1 FROM ExistingFields e WHERE e.field = n.field)
                    UNION ALL
                    -- 3) Re-changed fields: preserve original oldValue, update newValue + metadata
                    SELECT n.field, e.oldValue, n.newValue,
                        CASE
                            WHEN e.oldValue IS NULL AND n.newValue IS NOT NULL THEN 'Added'
                            WHEN e.oldValue IS NOT NULL AND n.newValue IS NULL THEN 'Removed'
                            ELSE 'Modified'
                        END,
                        n.changedById, n.changedByEmail, n.changedOn
                    FROM NewFields n
                    INNER JOIN ExistingFields e ON e.field = n.field
                ),
                -- 4) Remove reverted fields (value changed back to original)
                FilteredFields AS (
                    SELECT field, oldValue, newValue, changeType, changedById, changedByEmail, changedOn
                    FROM MergedFields
                    WHERE NOT (oldValue IS NOT NULL AND newValue IS NOT NULL AND oldValue = newValue)
                )
                SELECT @MergedAdminJson = (
                    SELECT field, oldValue, newValue, changeType, changedById, changedByEmail, changedOn
                    FROM FilteredFields
                    ORDER BY field
                    FOR JSON PATH
                );

                IF @MergedAdminJson IS NULL OR @MergedAdminJson = '[]'
                BEGIN
                    DELETE FROM tip.ProjectAmendmentLog WHERE Id = @AdminLogId;
                END
                ELSE
                BEGIN
                    DECLARE @AdminUsers NVARCHAR(MAX);
                    WITH AllUsers AS (
                        SELECT DISTINCT JSON_VALUE(value, '$.changedByEmail') AS email
                        FROM OPENJSON(@MergedAdminJson)
                    )
                    SELECT @AdminUsers = STRING_AGG(email, ', ') FROM AllUsers WHERE email IS NOT NULL;

                    UPDATE tip.ProjectAmendmentLog
                    SET RawChanges = @MergedAdminJson,
                        Description = 'Administrative changes by: ' + ISNULL(@AdminUsers, 'Unknown'),
                        UpdatedById = @UserId,
                        UpdatedOn = @Now
                    WHERE Id = @AdminLogId;

                    INSERT INTO @GeneratedLogIds (LogId) VALUES (@AdminLogId);
                END;
            END
            ELSE
            BEGIN
                SET @AdminLogId = NEWID();

                INSERT INTO tip.ProjectAmendmentLog
                    (Id, ProjectAmendmentId, ProjectAmendmentLogTypeId, Description, RawChanges, CreatedById, CreatedOn)
                VALUES
                    (@AdminLogId, @EffectiveProjectAmendmentId, @AdministrativeLogTypeId,
                     'Administrative changes by: ' + ISNULL(@UserEmail, 'Unknown'), @NewAdminChangesJson, @UserId, @Now);

                INSERT INTO @GeneratedLogIds (LogId) VALUES (@AdminLogId);
            END;
        END;

        -- 4c: Handle Amendment Log if general amendment changes exist
        IF @HasAmendmentChanges = 1
        BEGIN
            DECLARE @AmendLogId UNIQUEIDENTIFIER;
            DECLARE @ExistingAmendJson NVARCHAR(MAX);

            -- Check for existing log record
            SELECT @AmendLogId = Id, @ExistingAmendJson = RawChanges
            FROM tip.ProjectAmendmentLog
            WHERE ProjectAmendmentId = @EffectiveProjectAmendmentId
              AND ProjectAmendmentLogTypeId = @AmendmentLogTypeId;

            -- Build JSON for new amendment changes
            DECLARE @NewAmendChangesJson NVARCHAR(MAX);
            SELECT @NewAmendChangesJson = (
                SELECT
                    FieldName AS [field],
                    COALESCE(OldValueDisplay, OldValue) AS [oldValue],
                    COALESCE(NewValueDisplay, NewValue) AS [newValue],
                    CASE
                        WHEN OldValue IS NULL AND NewValue IS NOT NULL THEN 'Added'
                        WHEN OldValue IS NOT NULL AND NewValue IS NULL THEN 'Removed'
                        ELSE 'Modified'
                    END AS [changeType],
                    LOWER(CAST(@UserId AS NVARCHAR(36))) AS [changedById],
                    @UserEmail AS [changedByEmail],
                    @Now AS [changedOn]
                FROM @ChangedFields
                WHERE FieldCategory = 'Amendment'
                FOR JSON PATH
            );

            IF @AmendLogId IS NOT NULL
            BEGIN
                -- Merge with existing record
                DECLARE @MergedAmendJson NVARCHAR(MAX);

                WITH ExistingFields AS (
                    SELECT
                        JSON_VALUE(value, '$.field') AS field,
                        JSON_VALUE(value, '$.oldValue') AS oldValue,
                        JSON_VALUE(value, '$.newValue') AS newValue,
                        JSON_VALUE(value, '$.changeType') AS changeType,
                        JSON_VALUE(value, '$.changedById') AS changedById,
                        JSON_VALUE(value, '$.changedByEmail') AS changedByEmail,
                        JSON_VALUE(value, '$.changedOn') AS changedOn
                    FROM OPENJSON(@ExistingAmendJson)
                ),
                NewFields AS (
                    SELECT
                        JSON_VALUE(value, '$.field') AS field,
                        JSON_VALUE(value, '$.oldValue') AS oldValue,
                        JSON_VALUE(value, '$.newValue') AS newValue,
                        JSON_VALUE(value, '$.changeType') AS changeType,
                        JSON_VALUE(value, '$.changedById') AS changedById,
                        JSON_VALUE(value, '$.changedByEmail') AS changedByEmail,
                        JSON_VALUE(value, '$.changedOn') AS changedOn
                    FROM OPENJSON(@NewAmendChangesJson)
                ),
                MergedFields AS (
                    -- 1) Existing fields NOT touched in this save - preserve everything
                    SELECT e.field, e.oldValue, e.newValue, e.changeType, e.changedById, e.changedByEmail, e.changedOn
                    FROM ExistingFields e
                    WHERE NOT EXISTS (SELECT 1 FROM NewFields n WHERE n.field = e.field)
                    UNION ALL
                    -- 2) Brand-new fields (first time this field appears in the log)
                    SELECT n.field, n.oldValue, n.newValue, n.changeType, n.changedById, n.changedByEmail, n.changedOn
                    FROM NewFields n
                    WHERE NOT EXISTS (SELECT 1 FROM ExistingFields e WHERE e.field = n.field)
                    UNION ALL
                    -- 3) Re-changed fields: preserve original oldValue, update newValue + metadata
                    SELECT n.field, e.oldValue, n.newValue,
                        CASE
                            WHEN e.oldValue IS NULL AND n.newValue IS NOT NULL THEN 'Added'
                            WHEN e.oldValue IS NOT NULL AND n.newValue IS NULL THEN 'Removed'
                            ELSE 'Modified'
                        END,
                        n.changedById, n.changedByEmail, n.changedOn
                    FROM NewFields n
                    INNER JOIN ExistingFields e ON e.field = n.field
                ),
                -- 4) Remove reverted fields (value changed back to original)
                FilteredFields AS (
                    SELECT field, oldValue, newValue, changeType, changedById, changedByEmail, changedOn
                    FROM MergedFields
                    WHERE NOT (oldValue IS NOT NULL AND newValue IS NOT NULL AND oldValue = newValue)
                )
                SELECT @MergedAmendJson = (
                    SELECT field, oldValue, newValue, changeType, changedById, changedByEmail, changedOn
                    FROM FilteredFields
                    ORDER BY field
                    FOR JSON PATH
                );

                IF @MergedAmendJson IS NULL OR @MergedAmendJson = '[]'
                BEGIN
                    DELETE FROM tip.ProjectAmendmentLog WHERE Id = @AmendLogId;
                END
                ELSE
                BEGIN
                    DECLARE @AmendUsers NVARCHAR(MAX);
                    WITH AllUsers AS (
                        SELECT DISTINCT JSON_VALUE(value, '$.changedByEmail') AS email
                        FROM OPENJSON(@MergedAmendJson)
                    )
                    SELECT @AmendUsers = STRING_AGG(email, ', ') FROM AllUsers WHERE email IS NOT NULL;

                    UPDATE tip.ProjectAmendmentLog
                    SET RawChanges = @MergedAmendJson,
                        Description = 'Amendment changes by: ' + ISNULL(@AmendUsers, 'Unknown'),
                        UpdatedById = @UserId,
                        UpdatedOn = @Now
                    WHERE Id = @AmendLogId;

                    INSERT INTO @GeneratedLogIds (LogId) VALUES (@AmendLogId);
                END;
            END
            ELSE
            BEGIN
                SET @AmendLogId = NEWID();

                INSERT INTO tip.ProjectAmendmentLog
                    (Id, ProjectAmendmentId, ProjectAmendmentLogTypeId, Description, RawChanges, CreatedById, CreatedOn)
                VALUES
                    (@AmendLogId, @EffectiveProjectAmendmentId, @AmendmentLogTypeId,
                     'Amendment changes by: ' + ISNULL(@UserEmail, 'Unknown'), @NewAmendChangesJson, @UserId, @Now);

                INSERT INTO @GeneratedLogIds (LogId) VALUES (@AmendLogId);
            END;
        END;

        COMMIT TRANSACTION;

        -- =============================================
        -- STEP 5: Return generated log IDs
        -- =============================================
        SELECT LogId FROM @GeneratedLogIds;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;

GO
