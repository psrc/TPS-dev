SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================================================
-- View:        reporting.vw_SelectProjectList
-- Purpose:     Backs the "Select Project List" report (amendment-scoped).
--              Returns one row per project on each ProjectAmendment, with the
--              pending field values + per-field "changed" bit columns computed
--              by comparing to the posted tip.Project row. NewProject = 1 when
--              no posted row exists. Consumers filter by AmendmentId.
-- Source:      tip.ProjectAmendment + tip.Project_Pending vs tip.Project
-- Change flags: 0 = unchanged or NULL on both sides
--               1 = pending value differs from posted (or new project)
-- Created:     2026-05-08 (PSRC-wdb) - draft
-- =============================================================================
CREATE   VIEW [reporting].[vw_SelectProjectList]
AS
SELECT
    ProjectAmendmentId           = pa.Id
   ,AmendmentId                  = pa.AmendmentId
   ,AmendmentName                = amd.Name
   ,ProjectId                    = pa.ProjectId
   ,ProjectPendingId             = pp.Id
   ,ProjectNumber                = pp.ProjectCode
   ,JurisdictionShortName        = a.ShortName
   ,JurisdictionName             = a.Name
   ,CountyNames                  = counties.CountyNames
   -- Pending (amendment-side) values shown in the report:
   ,Title                        = pp.Title
   ,WsDotPin                     = pp.WsDotPin
   ,DemoId                       = pp.DemoId
   ,FederalAidGrantNumber        = grantNum.FederalAidGrantNumber
   ,Description                  = pp.Description
   ,Location                     = pp.Location
   ,LocationFrom                 = pp.LocationFrom
   ,LocationTo                   = pp.LocationTo
   ,ProjectLength                = pp.Length
   ,FunctionalClass              = fc.Description
   ,ImprovementType              = it.Description
   ,MtpStatus                    = rcps.Description
   ,RegionallySignificant        = rs.Description
   ,EnvironmentalStatus          = es.Description
   ,ReportDescription            = pp.ReportDescription
   -- Annotation / change flags. INTERSECT idiom treats NULL = NULL.
   ,IsNewProject                 = CASE WHEN p.Id IS NULL THEN 1 ELSE 0 END
   ,TitleChanged                 = CASE WHEN p.Id IS NULL OR NOT EXISTS (SELECT pp.Title         INTERSECT SELECT p.Title)         THEN 1 ELSE 0 END
   ,DescriptionChanged           = CASE WHEN p.Id IS NULL OR NOT EXISTS (SELECT pp.Description   INTERSECT SELECT p.Description)   THEN 1 ELSE 0 END
   ,LocationChanged              = CASE WHEN p.Id IS NULL OR NOT EXISTS (SELECT pp.Location      INTERSECT SELECT p.Location)      THEN 1 ELSE 0 END
   ,LocationFromToChanged        = CASE WHEN p.Id IS NULL
                                            OR NOT EXISTS (SELECT pp.LocationFrom INTERSECT SELECT p.LocationFrom)
                                            OR NOT EXISTS (SELECT pp.LocationTo   INTERSECT SELECT p.LocationTo)   THEN 1 ELSE 0 END
   ,LengthChanged                = CASE WHEN p.Id IS NULL OR NOT EXISTS (SELECT pp.Length        INTERSECT SELECT p.Length)        THEN 1 ELSE 0 END
   ,FunctionalClassChanged       = CASE WHEN p.Id IS NULL OR NOT EXISTS (SELECT pp.FunctionalClassTypeId    INTERSECT SELECT p.FunctionalClassTypeId)    THEN 1 ELSE 0 END
   ,ImprovementTypeChanged       = CASE WHEN p.Id IS NULL OR NOT EXISTS (SELECT pp.PrimaryImprovementTypeId INTERSECT SELECT p.PrimaryImprovementTypeId) THEN 1 ELSE 0 END
   ,WsDotPinChanged              = CASE WHEN p.Id IS NULL OR NOT EXISTS (SELECT pp.WsDotPin      INTERSECT SELECT p.WsDotPin)      THEN 1 ELSE 0 END
   ,DemoIdChanged                = CASE WHEN p.Id IS NULL OR NOT EXISTS (SELECT pp.DemoId        INTERSECT SELECT p.DemoId)        THEN 1 ELSE 0 END
   ,FederalAidGrantNumberChanged = CASE WHEN p.Id IS NULL
                                            OR NOT EXISTS (
                                                SELECT COALESCE(grantNum.FederalAidGrantNumber,       '')
                                                INTERSECT
                                                SELECT COALESCE(postedGrantNum.FederalAidGrantNumber, '')
                                            )
                                            THEN 1 ELSE 0 END
   ,MtpStatusChanged             = CASE WHEN p.Id IS NULL OR NOT EXISTS (SELECT pp.RcpStatusTypeId INTERSECT SELECT p.RcpStatusTypeId) THEN 1 ELSE 0 END
   ,RegionallySignificantChanged = CASE WHEN p.Id IS NULL OR NOT EXISTS (SELECT pp.RegionalSignificanceTypeId INTERSECT SELECT p.RegionalSignificanceTypeId) THEN 1 ELSE 0 END
   ,EnvironmentalStatusChanged   = CASE WHEN p.Id IS NULL OR NOT EXISTS (SELECT pp.EnvironmentalStatusTypeId  INTERSECT SELECT p.EnvironmentalStatusTypeId)  THEN 1 ELSE 0 END
   ,FundingChanged               = fundingDelta.FundingChanged
   -- Section / amendment metadata useful for ordering and Section-A filtering
   ,SectionDescription           = ast.Description
   ,IsBoardReviewedFlag          = ast.IsBoardReviewedFlag
   ,SponsorComments              = pa.SponsorComments
   ,PsrcComments                 = pa.PsrcComments
   -- Pending funding rolled up as JSON (same shape as vw_AppendixA.Phases)
   ,Phases                       = funding.Phases
   ,TotalCost                    = fundTotals.TotalCost
FROM tip.ProjectAmendment AS pa
JOIN tip.Amendment            AS amd ON amd.Id = pa.AmendmentId
JOIN tip.AmendmentSectionType AS ast ON ast.Id = pa.AmendmentSectionTypeId
JOIN tip.Project_Pending      AS pp  ON pp.ProjectAmendmentId = pa.Id
LEFT JOIN tip.Project         AS p   ON p.Id = pa.ProjectId  -- NULL for new projects
JOIN common.Agency            AS a   ON a.Id = pp.AgencyId
LEFT JOIN tip.FunctionalClassType        AS fc   ON fc.Id   = pp.FunctionalClassTypeId
LEFT JOIN tip.ImprovementType            AS it   ON it.Id   = pp.PrimaryImprovementTypeId
LEFT JOIN tip.RcpStatusType              AS rcps ON rcps.Id = pp.RcpStatusTypeId
LEFT JOIN tip.RegionalSignificanceType   AS rs   ON rs.Id   = pp.RegionalSignificanceTypeId
LEFT JOIN tip.EnvironmentalStatusType    AS es   ON es.Id   = pp.EnvironmentalStatusTypeId
OUTER APPLY (
    SELECT
        CountyNames = STRING_AGG(c.Description, ', ') WITHIN GROUP (ORDER BY c.Description)
    FROM tip.ProjectCountyMapping_Pending AS pcm
    JOIN common.County AS c ON c.Id = pcm.CountyId
    WHERE pcm.ProjectId = pp.Id
) AS counties
OUTER APPLY (
    -- Total Cost = sum of ProjectBudget_Pending.TotalAmount (secured + unsecured
    -- across all phases/funding sources). Matches pr_tip_project_search_view_find.
    SELECT
        TotalCost = SUM(pbp.TotalAmount)
    FROM tip.ProjectBudget_Pending AS pbp
    WHERE pbp.Project_PendingId = pp.Id
) AS fundTotals
OUTER APPLY (
    -- Federal Aid (FHWA) and FTA Grant numbers (pending). Routed by
    -- FundFamilyType.Code: 'FHWA' => FhwaObligatedNumber; 'FTA' => FtaObligatedNumber.
    SELECT
        FederalAidGrantNumber = STRING_AGG(g.GrantNumber, ', ') WITHIN GROUP (ORDER BY g.GrantNumber)
    FROM (
        SELECT DISTINCT
            GrantNumber = CASE ff.Code
                              WHEN 'FHWA' THEN NULLIF(pfp.FhwaObligatedNumber, '')
                              WHEN 'FTA'  THEN NULLIF(pfp.FtaObligatedNumber,  '')
                          END
        FROM tip.ProgrammedFunding_Pending AS pfp
        JOIN      tip.FundingSourceType    AS fst ON fst.Id = pfp.FundingSourceTypeId
        LEFT JOIN tip.FundFamilyType       AS ff  ON ff.Id  = fst.FundFamilyTypeId
        WHERE pfp.Project_PendingId = pp.Id
          AND pfp.IsActive          = 1
          AND ff.Code IN ('FHWA', 'FTA')
    ) AS g
    WHERE g.GrantNumber IS NOT NULL
) AS grantNum
OUTER APPLY (
    -- Same logic against the posted project's ProgrammedFunding rows, so we can
    -- detect whether the grant-number set changed in this amendment.
    SELECT
        FederalAidGrantNumber = STRING_AGG(g.GrantNumber, ', ') WITHIN GROUP (ORDER BY g.GrantNumber)
    FROM (
        SELECT DISTINCT
            GrantNumber = CASE ff.Code
                              WHEN 'FHWA' THEN NULLIF(pf.FhwaObligatedNumber, '')
                              WHEN 'FTA'  THEN NULLIF(pf.FtaObligatedNumber,  '')
                          END
        FROM tip.ProgrammedFunding   AS pf
        JOIN      tip.FundingSourceType AS fst ON fst.Id = pf.FundingSourceTypeId
        LEFT JOIN tip.FundFamilyType    AS ff  ON ff.Id  = fst.FundFamilyTypeId
        WHERE pf.ProjectId = p.Id
          AND pf.IsActive  = 1
          AND ff.Code IN ('FHWA', 'FTA')
    ) AS g
    WHERE g.GrantNumber IS NOT NULL
) AS postedGrantNum
OUTER APPLY (
    -- Coarse "any funding line changed?" flag: TRUE if the multiset of
    -- (Phase, Year, FundingSource, Amount) on the pending side differs from
    -- the posted side. Counts both adds/removes and amount changes.
    SELECT
        FundingChanged = CASE
            WHEN p.Id IS NULL THEN 1
            WHEN EXISTS (
                    SELECT pfp.PhaseTypeId, pfp.ProgrammedFundingYear, pfp.FundingSourceTypeId, pfp.FundingAmount
                    FROM tip.ProgrammedFunding_Pending AS pfp
                    WHERE pfp.Project_PendingId = pp.Id AND pfp.IsActive = 1
                    EXCEPT
                    SELECT pf.PhaseTypeId, pf.ProgrammedFundingYear, pf.FundingSourceTypeId, pf.FundingAmount
                    FROM tip.ProgrammedFunding AS pf
                    WHERE pf.ProjectId = p.Id AND pf.IsActive = 1
                 ) THEN 1
            WHEN EXISTS (
                    SELECT pf.PhaseTypeId, pf.ProgrammedFundingYear, pf.FundingSourceTypeId, pf.FundingAmount
                    FROM tip.ProgrammedFunding AS pf
                    WHERE pf.ProjectId = p.Id AND pf.IsActive = 1
                    EXCEPT
                    SELECT pfp.PhaseTypeId, pfp.ProgrammedFundingYear, pfp.FundingSourceTypeId, pfp.FundingAmount
                    FROM tip.ProgrammedFunding_Pending AS pfp
                    WHERE pfp.Project_PendingId = pp.Id AND pfp.IsActive = 1
                 ) THEN 1
            ELSE 0
        END
) AS fundingDelta
OUTER APPLY (
    SELECT
        Phase                       = ph.Description
       ,ProgrammedYear              = pfp.ProgrammedFundingYear
       ,EstimatedObligationDate     = pfp.EstimatedObligationDate
       ,ActualObligationDate        = COALESCE(pfp.FhwaObligatedDate, pfp.FtaObligatedDate)
       ,IsObligated                 = pfp.IsObligatedFlag
       -- Drives the '*' next to obligation date on the report: funds obligated
       -- earlier this calendar year.
       ,IsObligatedThisCalendarYear = CASE
            WHEN pfp.IsObligatedFlag = 1
                 AND YEAR(COALESCE(pfp.FhwaObligatedDate, pfp.FtaObligatedDate)) = YEAR(GETDATE())
                THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END
       ,FundingSource               = fs.Description
       ,GovernmentLevel             = fs.GovernmentLevel
       ,FederalFunds                = CASE WHEN fs.GovernmentLevel = 'Federal' THEN pfp.FundingAmount ELSE 0 END
       ,StateFunds                  = CASE WHEN fs.GovernmentLevel = 'State'   THEN pfp.FundingAmount ELSE 0 END
       ,LocalFunds                  = CASE WHEN fs.GovernmentLevel = 'Local'   THEN pfp.FundingAmount ELSE 0 END
       ,PhaseTotal                  = pfp.FundingAmount
    FROM tip.ProgrammedFunding_Pending AS pfp
    LEFT JOIN tip.PhaseType         AS ph ON ph.Id = pfp.PhaseTypeId
    LEFT JOIN tip.FundingSourceType AS fs ON fs.Id = pfp.FundingSourceTypeId
    WHERE pfp.Project_PendingId = pp.Id
      AND pfp.IsActive = 1
    ORDER BY ph.SortId
            ,pfp.ProgrammedFundingYear
            ,fs.SortId
    FOR JSON PATH
) AS funding(Phases);
GO
