SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================================================
-- View:        reporting.vw_TpbExhibit
-- Purpose:     Backs the "TPB Exhibit" report. Returns one row per project on
--              an amendment with the four exhibit checkboxes, the simplified
--              ReportDescription, sponsor agency, and pending funding totals
--              grouped by Federal/State/Local. Consumers typically filter to
--              AmendmentSectionType.IsBoardReviewedFlag = 1 (Section A) but
--              the view returns all sections so other exhibit sections can
--              reuse it.
--
-- Note:        Previously the exhibit was assembled by clearing/repopulating
--              a staging table each month. The "staging" columns now live
--              directly on tip.ProjectAmendment (Report* flags + ReportDesc-
--              ription + AmendmentSectionTypeId), so this view reads those
--              rather than a separate staging table.
-- Created:     2026-05-12 (PSRC-wdb) - draft
-- =============================================================================
CREATE   VIEW [reporting].[vw_TpbExhibit]
AS
SELECT
    ProjectAmendmentId     = pa.Id
   ,AmendmentId            = pa.AmendmentId
   ,AmendmentName          = amd.Name
   ,ProjectId              = pa.ProjectId
   ,ProjectNumber          = p.ProjectCode
   ,ProjectTitle           = p.Title
   ,SponsorAgencyName      = a.Name
   ,SponsorAgencyShortName = a.ShortName
   -- Simplified "existing project" / "new project" prose written by staff
   ,ExhibitDescription     = pa.ReportDescription
   -- "PSRC Action Needed" checkbox columns (exact 4 from the report):
   ,ActionProjectTracking  = pa.ReportProjectTrackingFlag
   ,ActionNewProjectPhase  = pa.ReportNewProjectPhaseFlag
   ,ActionOther            = pa.ReportOtherAmendFlag
   ,ActionUpwpAmend        = pa.ReportUpwpFlag
   -- Section assignment (Section A == board-reviewed). Surfaced here because
   -- the application currently only exposes it on the add-to-amendment dialog.
   ,SectionDescription     = ast.Description
   ,IsBoardReviewedFlag    = ast.IsBoardReviewedFlag
   ,SectionSortId          = ast.SortId
   -- Funding being added/modified by this amendment, summed by government level
   ,FederalFunds           = funds.FederalFunds
   ,StateFunds             = funds.StateFunds
   ,LocalFunds             = funds.LocalFunds
   ,TotalFunds             = funds.TotalFunds
FROM tip.ProjectAmendment      AS pa
JOIN tip.Amendment             AS amd ON amd.Id = pa.AmendmentId
JOIN tip.AmendmentSectionType  AS ast ON ast.Id = pa.AmendmentSectionTypeId
JOIN tip.Project               AS p   ON p.Id   = pa.ProjectId
JOIN common.Agency             AS a   ON a.Id   = p.AgencyId
OUTER APPLY (
    SELECT
        FederalFunds = SUM(CASE WHEN fs.GovernmentLevel = 'Federal' THEN pfp.FundingAmount ELSE 0 END)
       ,StateFunds   = SUM(CASE WHEN fs.GovernmentLevel = 'State'   THEN pfp.FundingAmount ELSE 0 END)
       ,LocalFunds   = SUM(CASE WHEN fs.GovernmentLevel = 'Local'   THEN pfp.FundingAmount ELSE 0 END)
       ,TotalFunds   = SUM(pfp.FundingAmount)
    FROM tip.Project_Pending           AS pp
    JOIN tip.ProgrammedFunding_Pending AS pfp ON pfp.Project_PendingId = pp.Id
    LEFT JOIN tip.FundingSourceType    AS fs  ON fs.Id = pfp.FundingSourceTypeId
    WHERE pp.ProjectAmendmentId = pa.Id
      AND pfp.IsActive = 1
) AS funds;
GO
