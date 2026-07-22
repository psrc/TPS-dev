SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================================================
-- View:        reporting.vw_AppendixA
-- Purpose:     Backs the "Appendix A Project Descriptions" report. Returns one
--              row per posted project in the current TIP (tip.Tip.IsCurrent = 1)
--              with programmed funding rolled up as a JSON array (one element
--              per ProgrammedFunding row, ordered by phase + year + source).
-- Source:      tip.Project + tip.ProgrammedFunding (posted, no amendments)
-- Created:     2026-05-13 (PSRC-wdb) - draft
-- =============================================================================
CREATE   VIEW [reporting].[vw_AppendixA]
AS
SELECT
    ProjectId                = p.Id
   ,TipId                    = t.Id
   ,TipBeginYear             = t.BeginYear
   ,TipEndYear               = t.EndYear
   ,JurisdictionShortName    = a.ShortName
   ,JurisdictionName         = a.Name
   ,ProjectNumber            = p.ProjectCode
   ,CountyNames              = counties.CountyNames
   ,Title                    = p.Title
   ,WsDotPin                 = p.WsDotPin
   ,DemoId                   = p.DemoId
   -- TODO PSRC-wdb: surface second WSDOT WIN identifier when its column is added.
   ,FederalAidGrantNumber    = grantNum.FederalAidGrantNumber
   ,FunctionalClass          = fc.Description
   ,ImprovementType          = it.Description
   ,Location                 = p.Location
   ,LocationFrom             = p.LocationFrom
   ,LocationTo               = p.LocationTo
   ,ProjectLength            = p.Length
   ,TotalCost                = fundTotals.TotalCost
   ,RegionallySignificant    = rs.Description
   ,EnvironmentalStatus      = es.Description
   ,YearOfExpenditure        = p.ConstantDollarProjectYear
   ,ExpectedYearOfCompletion = (
        SELECT MAX(v)
        FROM (VALUES (p.YearCompPL),(p.YearCompPE),(p.YearCompROW),(p.YearCompCN),(p.YearCompOther)) AS m(v)
    )
   ,MtpStatus                = rcps.Description
   -- TODO PSRC-wdb: MTP Reference(s) column not yet identified in schema.
   ,MtpReferences            = CAST(NULL AS NVARCHAR(MAX))
   ,Description              = p.Description
   ,ReportDescription        = p.ReportDescription
   ,Phases                   = funding.Phases
FROM tip.Project AS p
JOIN tip.ProjectTipMapping AS ptm
    ON ptm.ProjectId = p.Id
JOIN tip.Tip AS t
    ON t.Id = ptm.TipId
   AND t.IsCurrent = 1
JOIN common.Agency AS a
    ON a.Id = p.AgencyId
LEFT JOIN tip.FunctionalClassType AS fc
    ON fc.Id = p.FunctionalClassTypeId
LEFT JOIN tip.ImprovementType AS it
    ON it.Id = p.PrimaryImprovementTypeId
LEFT JOIN tip.RegionalSignificanceType AS rs
    ON rs.Id = p.RegionalSignificanceTypeId
LEFT JOIN tip.EnvironmentalStatusType AS es
    ON es.Id = p.EnvironmentalStatusTypeId
LEFT JOIN tip.RcpStatusType AS rcps
    ON rcps.Id = p.RcpStatusTypeId
OUTER APPLY (
    SELECT
        CountyNames = STRING_AGG(c.Description, ', ') WITHIN GROUP (ORDER BY c.Description)
    FROM tip.ProjectCountyMapping AS pcm
    JOIN common.County AS c ON c.Id = pcm.CountyId
    WHERE pcm.ProjectId = p.Id
) AS counties
OUTER APPLY (
    -- Total Cost = sum of ProjectBudget.TotalAmount (secured + unsecured across all
    -- phases/funding sources). Matches pr_tip_project_search_view_find. Differs
    -- from sum of programmed funding because budget includes unprogrammed costs.
    SELECT
        TotalCost = SUM(pb.TotalAmount)
    FROM tip.ProjectBudget AS pb
    WHERE pb.ProjectId = p.Id
) AS fundTotals
OUTER APPLY (
    -- Federal Aid (FHWA) and FTA Grant numbers. Routed by FundFamilyType.Code:
    -- 'FHWA' family => pf.FhwaObligatedNumber; 'FTA' family => pf.FtaObligatedNumber.
    -- Distinct non-empty values aggregated into a comma-separated list.
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
) AS grantNum
OUTER APPLY (
    SELECT
        Phase                       = ph.Description
       ,ProgrammedYear              = pf.ProgrammedFundingYear
       ,EstimatedObligationDate     = pf.EstimatedObligationDate
       ,ActualObligationDate        = COALESCE(pf.FhwaObligatedDate, pf.FtaObligatedDate)
       ,IsObligated                 = pf.IsObligatedFlag
       -- Drives the '*' next to obligation date on the report: funds obligated
       -- earlier this calendar year (per the Appendix A legend footnote).
       ,IsObligatedThisCalendarYear = CASE
            WHEN pf.IsObligatedFlag = 1
                 AND YEAR(COALESCE(pf.FhwaObligatedDate, pf.FtaObligatedDate)) = YEAR(GETDATE())
                THEN CAST(1 AS BIT)
            ELSE CAST(0 AS BIT)
        END
       ,FundingSource               = fs.Description
       ,GovernmentLevel             = fs.GovernmentLevel
       ,FederalFunds                = CASE WHEN fs.GovernmentLevel = 'Federal' THEN pf.FundingAmount ELSE 0 END
       ,StateFunds                  = CASE WHEN fs.GovernmentLevel = 'State'   THEN pf.FundingAmount ELSE 0 END
       ,LocalFunds                  = CASE WHEN fs.GovernmentLevel = 'Local'   THEN pf.FundingAmount ELSE 0 END
       ,PhaseTotal                  = pf.FundingAmount
    FROM tip.ProgrammedFunding AS pf
    LEFT JOIN tip.PhaseType         AS ph ON ph.Id = pf.PhaseTypeId
    LEFT JOIN tip.FundingSourceType AS fs ON fs.Id = pf.FundingSourceTypeId
    WHERE pf.ProjectId = p.Id
      AND pf.IsActive = 1
    ORDER BY ph.SortId
            ,pf.ProgrammedFundingYear
            ,fs.SortId
    FOR JSON PATH
) AS funding(Phases);
GO
