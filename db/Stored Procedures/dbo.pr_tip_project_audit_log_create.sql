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
-- Modified:    2026-09-08 - PSRC-cs0z: key funding subfields on the row (OriginRecordId) rather
--                           than {fundingSource|phase|year}, so editing any of those three reads
--                           as one change instead of a remove plus an add. Fund source, phase and
--                           year become ordinary subfields; unchanged subfields are kept as the
--                           context Miles's TIP-012 sketch renders on both sides; fundingRowId and
--                           subField are carried into the JSON so the client can group a row; the
--                           amendment merge matches on (row, field) and only drops a funding row
--                           once EVERY subfield has reverted.
-- Modified:    2026-09-08 - PSRC-cs0z: absent funding values stay NULL rather than becoming
--                           '(none)' / '(no FHWA#)'. Only the client knows whether a missing value
--                           means "empty" or "the row did not exist on that side".
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
-- Field Categories (Asana TIP-012/013 Q19, 2026-09-09 — collapsed to two log types):
--   'Phase'          -> folded into Amendment Logs at STEP 1b
--   'Administrative' -> folded into Amendment Logs at STEP 1b
--   'Amendment'      -> Amendment Logs
--
-- Modified:    2026-09-09 - PSRC-6ksm - fold the Phase and Administrative categories into
--                           Amendment at STEP 1c.
-- Modified:    2026-09-10 - PSRC-shiu - carry ChangeKind through, so a split funding row logs as
--                           'Split - Added' / 'Split - Modified' instead of two entries a user
--                           cannot tell were one operation.
-- Modified:    2026-09-10 - Asana TIP-005 - revert detection is now null-safe. A field or funding
--                           row that ends where it started is dropped even when that value is
--                           blank, so a row added and removed within one amendment leaves no log.
-- Modified:    2026-09-09 - PSRC-cev0 - stamp TipId on the administrative amendment this creates.
--                           Without it every regular project edit left an amendment with a NULL
--                           TipId, which tip.Amendment.TipId NOT NULL then rejects outright.
-- Modified:    2026-09-09 - PSRC-yipi - removed the Phase and Administrative per-category blocks,
--                           their log-type lookups and their category flags, all unreachable once
--                           the fold above landed.
-- Modified:    2026-09-12 - PSRC-mte.1 tenancy scoping (@TenantAgencyId/@BypassTenancy)
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_audit_log_create]
    @UserId            UNIQUEIDENTIFIER,           -- ID of the user making the changes
    @ProjectId         UNIQUEIDENTIFIER,           -- ID of the project being modified
    @AmendmentId       UNIQUEIDENTIFIER = NULL,    -- NULL for regular updates (creates admin amendment)
    @ProjectAmendmentId UNIQUEIDENTIFIER = NULL,   -- NULL for regular updates (creates project amendment)
    @FieldChanges      dbo.ProjectFieldChangeType READONLY, -- Table of field changes
    @TenantAgencyId UNIQUEIDENTIFIER = NULL,      -- PSRC-mte.1: caller's agency (NULL = none)
    @BypassTenancy  BIT = 0                       -- PSRC-mte.1: 1 = internal caller, no scoping
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- PSRC-mte.1: internal-only. This object has no owning agency, so a scoped caller has no
    -- rows here at all; refusing beats guessing.
    IF @BypassTenancy = 0
        THROW 50403, 'Tenancy: pr_tip_project_audit_log_create is internal-only.', 1;

    -- =============================================
    -- LOOKUP: Log Type IDs (by Code to support different environments)
    -- =============================================
    DECLARE @AmendmentLogTypeId UNIQUEIDENTIFIER;

    SELECT @AmendmentLogTypeId = Id FROM tip.ProjectAmendmentLogType WHERE Code = 'Amendment Logs';

    -- =============================================
    -- LOOKUP: Amendment Status and Section Types (by Code to support different environments)
    -- =============================================
    DECLARE @PostedStatusId UNIQUEIDENTIFIER;
    DECLARE @DefaultSectionTypeId UNIQUEIDENTIFIER;
    DECLARE @CompleteReviewStatusId UNIQUEIDENTIFIER;

    SELECT @PostedStatusId = Id FROM tip.AmendmentStatusType WHERE Code = 'Posted';

    -- PSRC-cev0: the administrative amendment this procedure may create below needs a TipId, the
    -- same as any other amendment. It amends the project as it stands, so it belongs to the TIP in
    -- effect — matching pr_tip_amendment_create's fallback.
    DECLARE @CurrentTipId UNIQUEIDENTIFIER;
    SELECT TOP (1) @CurrentTipId = Id FROM tip.Tip WHERE IsCurrent = 1;
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
        FieldCategory    NVARCHAR(50)  NOT NULL,
        -- PSRC-cs0z: which programmed-funding row a subfield belongs to, so the client can
        -- render one block per row. NULL for every non-funding change.
        FundingRowId     NVARCHAR(36)  NULL,
        SubFieldName     NVARCHAR(50)  NULL,
        -- PSRC-shiu: qualifies HOW the change came about where Added/Modified/Removed alone is
        -- not the whole story. 'Split' marks both halves of a split funding row.
        ChangeKind       NVARCHAR(20)  NULL
    );

    INSERT INTO @ChangedFields (FieldName, OldValue, NewValue, OldValueDisplay, NewValueDisplay, FieldCategory, ChangeKind)
    SELECT FieldName, OldValue, NewValue, OldValueDisplay, NewValueDisplay, FieldCategory, ChangeKind
    FROM @FieldChanges
    -- PSRC-cs0z: funding subfields come through even when unchanged. AuditLogService only emits
    -- a funding row at all once something on it differs, so an all-equal row never reaches here;
    -- the equal subfields that do are the context Miles's sketch renders on both sides.
    WHERE FieldName LIKE 'ProgrammedFunding:%'
       OR (OldValue IS NULL AND NewValue IS NOT NULL)
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

    -- ProgrammedFunding per-subfield display resolution.
    -- FieldName format (PSRC-cs0z): ProgrammedFunding:{originRowId}:{SubFieldName}
    --
    -- The key used to be {fundingSourceTypeId}|{phaseTypeId}|{year}, which meant editing any of
    -- those three re-keyed the row and read as a remove plus an add. It is now the row's own
    -- identity, so those three are ordinary subfields that can show a before and an after — which
    -- is what Miles's sketch asks for.
    --
    -- The label therefore no longer embeds fund source / phase / year: those are values inside the
    -- block now, and baking a changeable value into the field name would make the merge below
    -- treat one row as two. FundingRowId carries the grouping instead.
    UPDATE cf SET
        FundingRowId = NULLIF(parts.RowId, ''),
        SubFieldName = NULLIF(parts.SubFieldName, ''),
        FieldName = 'Programmed Funding '
            + CASE parts.SubFieldName
                WHEN 'AwardReferenceId'        THEN 'Award Ref'
                WHEN 'PhaseTypeId'             THEN 'Phase'
                WHEN 'ProgrammedFundingYear'   THEN 'Year'
                WHEN 'EstimatedObligationDate' THEN 'Est Oblig Date'
                WHEN 'FundingSourceTypeId'     THEN 'Fund Source'
                WHEN 'Amount'                  THEN 'Amount'
                WHEN 'IsObligatedFlag'         THEN 'Obligated'
                WHEN 'FtaObligatedDate'        THEN 'FTA Date'
                WHEN 'FtaObligatedNumber'      THEN 'FTA #'
                WHEN 'FhwaObligatedDate'       THEN 'FHWA Date'
                WHEN 'FhwaObligatedNumber'     THEN 'FHWA #'
                ELSE parts.SubFieldName
              END,
        OldValueDisplay = CASE WHEN cf.OldValue IS NULL THEN NULL
            ELSE CASE parts.SubFieldName
                WHEN 'AwardReferenceId'    THEN ISNULL(COALESCE(NULLIF(oldAr.SubAwardReference, ''), oldAr.AwardRef), '(none)')
                WHEN 'PhaseTypeId'         THEN ISNULL(oldPt.Code, '(none)')
                WHEN 'FundingSourceTypeId' THEN ISNULL(oldFst.Description, '(none)')
                WHEN 'Amount'              THEN '$' + FORMAT(TRY_CAST(cf.OldValue AS BIGINT), 'N0')
                WHEN 'IsObligatedFlag'     THEN CASE cf.OldValue WHEN '1' THEN 'Yes' WHEN '0' THEN 'No' ELSE '(none)' END
                -- PSRC-cs0z: an absent value stays NULL. The client decides whether that reads
                -- "not set" (the sub-field is empty) or an em dash (the object did not exist on
                -- that side) — the server cannot tell those apart.
                ELSE NULLIF(cf.OldValue, '')
            END END,
        NewValueDisplay = CASE WHEN cf.NewValue IS NULL THEN NULL
            ELSE CASE parts.SubFieldName
                WHEN 'AwardReferenceId'    THEN ISNULL(COALESCE(NULLIF(newAr.SubAwardReference, ''), newAr.AwardRef), '(none)')
                WHEN 'PhaseTypeId'         THEN ISNULL(newPt.Code, '(none)')
                WHEN 'FundingSourceTypeId' THEN ISNULL(newFst.Description, '(none)')
                WHEN 'Amount'              THEN '$' + FORMAT(TRY_CAST(cf.NewValue AS BIGINT), 'N0')
                WHEN 'IsObligatedFlag'     THEN CASE cf.NewValue WHEN '1' THEN 'Yes' WHEN '0' THEN 'No' ELSE '(none)' END
                -- PSRC-cs0z: an absent value stays NULL. The client decides whether that reads
                -- "not set" (the sub-field is empty) or an em dash (the object did not exist on
                -- that side) — the server cannot tell those apart.
                ELSE NULLIF(cf.NewValue, '')
            END END
    FROM @ChangedFields cf
    -- Split 'ProgrammedFunding:{rowId}:{SubFieldName}' on its LAST colon. IIF guards keep
    -- SUBSTRING lengths non-negative for rows that are not funding changes.
    CROSS APPLY (
        SELECT CHARINDEX(':', REVERSE(cf.FieldName)) AS RevColonPos
    ) rc
    CROSS APPLY (
        SELECT IIF(rc.RevColonPos > 0, LEN(cf.FieldName) - rc.RevColonPos + 1, 0) AS LastColonPos
    ) lc
    CROSS APPLY (
        SELECT
            IIF(lc.LastColonPos > 19, SUBSTRING(cf.FieldName, 19, lc.LastColonPos - 19), '') AS RowId,
            IIF(lc.LastColonPos > 0, SUBSTRING(cf.FieldName, lc.LastColonPos + 1, LEN(cf.FieldName)), '') AS SubFieldName
    ) parts
    LEFT JOIN tip.AwardReference oldAr
        ON parts.SubFieldName = 'AwardReferenceId'
        AND TRY_CAST(NULLIF(cf.OldValue, '') AS UNIQUEIDENTIFIER) = oldAr.Id
    LEFT JOIN tip.AwardReference newAr
        ON parts.SubFieldName = 'AwardReferenceId'
        AND TRY_CAST(NULLIF(cf.NewValue, '') AS UNIQUEIDENTIFIER) = newAr.Id
    LEFT JOIN tip.PhaseType oldPt
        ON parts.SubFieldName = 'PhaseTypeId'
        AND TRY_CAST(NULLIF(cf.OldValue, '') AS UNIQUEIDENTIFIER) = oldPt.Id
    LEFT JOIN tip.PhaseType newPt
        ON parts.SubFieldName = 'PhaseTypeId'
        AND TRY_CAST(NULLIF(cf.NewValue, '') AS UNIQUEIDENTIFIER) = newPt.Id
    LEFT JOIN tip.FundingSourceType oldFst
        ON parts.SubFieldName = 'FundingSourceTypeId'
        AND TRY_CAST(NULLIF(cf.OldValue, '') AS UNIQUEIDENTIFIER) = oldFst.Id
    LEFT JOIN tip.FundingSourceType newFst
        ON parts.SubFieldName = 'FundingSourceTypeId'
        AND TRY_CAST(NULLIF(cf.NewValue, '') AS UNIQUEIDENTIFIER) = newFst.Id
    WHERE cf.FieldName LIKE 'ProgrammedFunding:%';

    -- If no changes, exit early
    IF NOT EXISTS (SELECT 1 FROM @ChangedFields)
    BEGIN
        -- Return empty result set for consistency
        SELECT CAST(NULL AS UNIQUEIDENTIFIER) AS LogId WHERE 1 = 0;
        RETURN 0;
    END;

    -- =============================================
    -- STEP 1c: Fold the retired categories into Amendment (Asana TIP-012/013 Q19)
    -- =============================================
    -- The client collapsed four log types to two: Amendment Logs, for everything a PSRC user
    -- changes while working an amendment, and Posting Logs, written when the amendment is posted.
    -- Phase and Administrative changes are both the former, so they are relabelled here rather
    -- than at each per-category block below. Doing it at the source means the Phase
    -- and Administrative blocks were unreachable and have since been removed (PSRC-yipi), so every
    -- change flows through the Amendment block — which already merges into one log per
    -- ProjectAmendment + LogType. Repointing the type IDs instead would have left three blocks
    -- contending for the same log row.
    UPDATE @ChangedFields
    SET    FieldCategory = 'Amendment'
    WHERE  FieldCategory IN ('Phase', 'Administrative');

    -- =============================================
    -- STEP 2: Group changes by category
    -- =============================================
    -- Only one category survives Q19; STEP 1c has already folded the other two into it.
    DECLARE @HasAmendmentChanges BIT = 0;

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
                    (Id, AmendmentStatusTypeId, Name, IsAdministrativeAmendmentFlag, EffectiveDate, TipId, CreatedById, CreatedOn)
                VALUES
                    (@EffectiveAmendmentId, @PostedStatusId, @ExpectedAmendmentName, 1, @Today, @CurrentTipId, @UserId, @Now);

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

        -- 4a: Handle Amendment Log — the only category, since Q19 folded Phase and
        --     Administrative into it at STEP 1c.
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
                    -- PSRC-shiu: ChangeKind qualifies the derived type rather than replacing it,
                    -- so a split reads 'Split - Added' / 'Split - Modified' and the plain forms
                    -- are untouched for every ordinary change.
                    CONCAT(
                        CASE WHEN ChangeKind IS NULL THEN '' ELSE ChangeKind + ' - ' END,
                        CASE
                            WHEN OldValue IS NULL AND NewValue IS NOT NULL THEN 'Added'
                            WHEN OldValue IS NOT NULL AND NewValue IS NULL THEN 'Removed'
                            ELSE 'Modified'
                        END
                    ) AS [changeType],
                    LOWER(CAST(@UserId AS NVARCHAR(36))) AS [changedById],
                    @UserEmail AS [changedByEmail],
                    @Now AS [changedOn],
                    -- PSRC-cs0z: null for non-funding changes, and FOR JSON PATH omits nulls,
                    -- so existing consumers see exactly the shape they saw before.
                    FundingRowId AS [fundingRowId],
                    SubFieldName AS [subField]
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
                        JSON_VALUE(value, '$.changedOn') AS changedOn,
                        JSON_VALUE(value, '$.fundingRowId') AS fundingRowId,
                        JSON_VALUE(value, '$.subField') AS subField,
                        -- Match key: two funding rows both carry 'Programmed Funding Amount', so
                        -- the field name alone would merge them into one (PSRC-cs0z).
                        CONCAT(ISNULL(JSON_VALUE(value, '$.fundingRowId'), ''), '|',
                               JSON_VALUE(value, '$.field')) AS matchKey
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
                        JSON_VALUE(value, '$.changedOn') AS changedOn,
                        JSON_VALUE(value, '$.fundingRowId') AS fundingRowId,
                        JSON_VALUE(value, '$.subField') AS subField,
                        CONCAT(ISNULL(JSON_VALUE(value, '$.fundingRowId'), ''), '|',
                               JSON_VALUE(value, '$.field')) AS matchKey
                    FROM OPENJSON(@NewAmendChangesJson)
                ),
                MergedFields AS (
                    -- 1) Existing fields NOT touched in this save - preserve everything
                    SELECT e.field, e.oldValue, e.newValue, e.changeType, e.changedById, e.changedByEmail, e.changedOn,
                           e.fundingRowId, e.subField
                    FROM ExistingFields e
                    WHERE NOT EXISTS (SELECT 1 FROM NewFields n WHERE n.matchKey = e.matchKey)
                    UNION ALL
                    -- 2) Brand-new fields (first time this field appears in the log)
                    SELECT n.field, n.oldValue, n.newValue, n.changeType, n.changedById, n.changedByEmail, n.changedOn,
                           n.fundingRowId, n.subField
                    FROM NewFields n
                    WHERE NOT EXISTS (SELECT 1 FROM ExistingFields e WHERE e.matchKey = n.matchKey)
                    UNION ALL
                    -- 3) Re-changed fields: preserve original oldValue, update newValue + metadata
                    SELECT n.field, e.oldValue, n.newValue,
                        -- Recomputed against the ORIGINAL old value, so keep whatever qualifier
                        -- the incoming change carried (PSRC-shiu) rather than dropping back to the
                        -- bare form on a second save.
                        CONCAT(
                            CASE WHEN CHARINDEX(' - ', n.changeType) = 0 THEN ''
                                 ELSE LEFT(n.changeType, CHARINDEX(' - ', n.changeType) + 2) END,
                            CASE
                                WHEN e.oldValue IS NULL AND n.newValue IS NOT NULL THEN 'Added'
                                WHEN e.oldValue IS NOT NULL AND n.newValue IS NULL THEN 'Removed'
                                ELSE 'Modified'
                            END
                        ),
                        n.changedById, n.changedByEmail, n.changedOn,
                        n.fundingRowId, n.subField
                    FROM NewFields n
                    INNER JOIN ExistingFields e ON e.matchKey = n.matchKey
                ),
                -- 4) Remove reverted entries.
                --    For a plain field that still means "value changed back to original".
                --    For a funding row it has to be judged per ROW, not per subfield: PSRC-cs0z
                --    keeps unchanged subfields deliberately, as the context the block renders on
                --    both sides, so dropping them individually would empty the block. A funding
                --    row disappears only when EVERY one of its subfields has come back to where
                --    it started — which is the same "fully reverted" rule, applied at row level.
                RevertedFundingRows AS (
                    SELECT fundingRowId
                    FROM MergedFields
                    WHERE fundingRowId IS NOT NULL
                    GROUP BY fundingRowId
                    -- Null-safe on purpose. A row ADDED and then REMOVED inside the same
                    -- amendment leaves every subfield at NULL -> NULL, which the old
                    -- "both sides NOT NULL" test scored as a change and kept — leaving a log entry
                    -- with no values in it at all (Asana TIP-005). Blank is blank, matching
                    -- AuditLogService.NormaliseBlank on the way in.
                    HAVING SUM(CASE
                                   WHEN ISNULL(oldValue, '') = ISNULL(newValue, '')
                                       THEN 0
                                   ELSE 1
                               END) = 0
                ),
                FilteredFields AS (
                    SELECT field, oldValue, newValue, changeType, changedById, changedByEmail, changedOn,
                           fundingRowId, subField
                    FROM MergedFields m
                    WHERE (
                            m.fundingRowId IS NULL
                            -- Null-safe for the same reason as RevertedFundingRows above: a plain
                            -- field that ends where it started is reverted whether that value is
                            -- blank or not.
                            AND NOT (ISNULL(m.oldValue, '') = ISNULL(m.newValue, ''))
                          )
                       OR (
                            m.fundingRowId IS NOT NULL
                            AND NOT EXISTS (SELECT 1 FROM RevertedFundingRows r WHERE r.fundingRowId = m.fundingRowId)
                          )
                )
                SELECT @MergedAmendJson = (
                    SELECT field, oldValue, newValue, changeType, changedById, changedByEmail, changedOn,
                           fundingRowId, subField
                    FROM FilteredFields
                    ORDER BY ISNULL(fundingRowId, ''), field
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
