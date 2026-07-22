SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
==================================================
Stored Procedure: reporting.pr_report_all_type_tables
==================================================
Purpose: Returns all lookup/type table data used throughout the TIP system in a single
         multi-result-set call. Intended to support reporting and reference data export
         (e.g., populating an Excel workbook with one tab per type table).

Author: john.hunter@triskelle.solutions
Created: 12/1/2025
Modified: [Date] - [Reason for modification]

Parameters: None

Returns: 26 result sets:
         1.  Metadata - list of tab/table names corresponding to result sets 2-26
         2.  AgencyType
         3.  County
         4.  WsdotRegion
         5.  AmendmentMappedType
         6.  AmendmentSectionType
         7.  AmendmentStatusType
         8.  CompletionStatusType
         9.  DistributionType
         10. EnvironmentalStatusType
         11. FinancialSummaryGroupType
         12. ForumType
         13. FunctionalClassType
         14. FundFamilyType
         15. FundingSourceType
         16. ImprovementType
         17. MappedType
         18. PhaseType
         19. ProjectAmendmentLogType
         20. ProjectAmendmentReviewAreaStatusType
         21. ProjectAmendmentReviewAreaType
         22. ProjectAmendmentReviewStatusType
         23. ProjectTipLogType
         24. RcpStatusType
         25. RegionalSignificanceType
         26. ReportType

Example Usage:
    EXEC reporting.pr_report_all_type_tables

Dependencies:
    common.AgencyType
    common.County
    common.WsdotRegion
    tip.AmendmentMappedType
    tip.AmendmentSectionType
    tip.AmendmentStatusType
    tip.CompletionStatusType
    tip.DistributionType
    tip.EnvironmentalStatusType
    tip.FinancialSummaryGroupType
    tip.ForumType
    tip.FunctionalClassType
    tip.FundFamilyType
    tip.FundingSourceType
    tip.ImprovementType
    tip.MappedType
    tip.PhaseType
    tip.ProjectAmendmentLogType
    tip.ProjectAmendmentReviewAreaStatusType
    tip.ProjectAmendmentReviewAreaType
    tip.ProjectAmendmentReviewStatusType
    tip.ProjectTipLogType
    tip.RcpStatusType
    tip.RegionalSignificanceType
    reporting.ReportType

Business Rules:
    - All result sets return columns: Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    - County does not have SortId, EffectiveDate, or EndDate columns; NULLs are returned for those fields
    - WsdotRegion uses a Name column instead of Description; it is aliased as Description for consistency
    - Results are ordered by SortId, Code except County which is ordered by Code only
==================================================
*/
CREATE PROCEDURE [reporting].[pr_report_all_type_tables]
AS
BEGIN
    SET NOCOUNT ON;

    -- Result Set 1: Metadata (Tab Names)
    SELECT 'AgencyType' AS TabName
    UNION ALL SELECT 'County'
    UNION ALL SELECT 'WsdotRegion'
    UNION ALL SELECT 'AmendmentMappedType'
    UNION ALL SELECT 'AmendmentSectionType'
    UNION ALL SELECT 'AmendmentStatusType'
    UNION ALL SELECT 'CompletionStatusType'
    UNION ALL SELECT 'DistributionType'
    UNION ALL SELECT 'EnvironmentalStatusType'
    UNION ALL SELECT 'FinancialSummaryGroupType'
    UNION ALL SELECT 'ForumType'
    UNION ALL SELECT 'FunctionalClassType'
    UNION ALL SELECT 'FundFamilyType'
    UNION ALL SELECT 'FundingSourceType'
    UNION ALL SELECT 'ImprovementType'
    UNION ALL SELECT 'MappedType'
    UNION ALL SELECT 'PhaseType'
    UNION ALL SELECT 'ProjectAmendmentLogType'
    UNION ALL SELECT 'ProjectAmendmentReviewAreaStatusType'
    UNION ALL SELECT 'ProjectAmendmentReviewAreaType'
    UNION ALL SELECT 'ProjectAmendmentReviewStatusType'
    UNION ALL SELECT 'ProjectTipLogType'
    UNION ALL SELECT 'RcpStatusType'
    UNION ALL SELECT 'RegionalSignificanceType'
    UNION ALL SELECT 'ReportType';

    -- Result Set 2: AgencyType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM common.AgencyType
    ORDER BY SortId, Code;

    -- Result Set 3: County (different schema - no SortId, EffectiveDate, EndDate)
    SELECT Id, Code, Description, NULL AS SortId, NULL AS EffectiveDate, NULL AS EndDate, CreatedOn, UpdatedOn
    FROM common.County
    ORDER BY Code;

    -- Result Set 4: WsdotRegion (uses Name instead of Description)
    SELECT Id, Code, Name AS Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM common.WsdotRegion
    ORDER BY SortId, Code;

    -- Result Set 5: AmendmentMappedType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.AmendmentMappedType
    ORDER BY SortId, Code;

    -- Result Set 6: AmendmentSectionType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.AmendmentSectionType
    ORDER BY SortId, Code;

    -- Result Set 7: AmendmentStatusType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.AmendmentStatusType
    ORDER BY SortId, Code;

    -- Result Set 8: CompletionStatusType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.CompletionStatusType
    ORDER BY SortId, Code;

    -- Result Set 9: DistributionType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.DistributionType
    ORDER BY SortId, Code;

    -- Result Set 10: EnvironmentalStatusType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.EnvironmentalStatusType
    ORDER BY SortId, Code;

    -- Result Set 11: FinancialSummaryGroupType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.FinancialSummaryGroupType
    ORDER BY SortId, Code;

    -- Result Set 12: ForumType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.ForumType
    ORDER BY SortId, Code;

    -- Result Set 13: FunctionalClassType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.FunctionalClassType
    ORDER BY SortId, Code;

    -- Result Set 14: FundFamilyType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.FundFamilyType
    ORDER BY SortId, Code;

    -- Result Set 15: FundingSourceType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.FundingSourceType
    ORDER BY SortId, Code;

    -- Result Set 16: ImprovementType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.ImprovementType
    ORDER BY SortId, Code;

    -- Result Set 17: MappedType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.MappedType
    ORDER BY SortId, Code;

    -- Result Set 18: PhaseType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.PhaseType
    ORDER BY SortId, Code;

    -- Result Set 19: ProjectAmendmentLogType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.ProjectAmendmentLogType
    ORDER BY SortId, Code;

    -- Result Set 20: ProjectAmendmentReviewAreaStatusType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.ProjectAmendmentReviewAreaStatusType
    ORDER BY SortId, Code;

    -- Result Set 21: ProjectAmendmentReviewAreaType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.ProjectAmendmentReviewAreaType
    ORDER BY SortId, Code;

    -- Result Set 22: ProjectAmendmentReviewStatusType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.ProjectAmendmentReviewStatusType
    ORDER BY SortId, Code;

    -- Result Set 23: ProjectTipLogType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.ProjectTipLogType
    ORDER BY SortId, Code;

    -- Result Set 24: RcpStatusType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.RcpStatusType
    ORDER BY SortId, Code;

    -- Result Set 25: RegionalSignificanceType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM tip.RegionalSignificanceType
    ORDER BY SortId, Code;

    -- Result Set 26: ReportType
    SELECT Id, Code, Description, SortId, EffectiveDate, EndDate, CreatedOn, UpdatedOn
    FROM reporting.ReportType
    ORDER BY SortId, Code;
END;
GO
