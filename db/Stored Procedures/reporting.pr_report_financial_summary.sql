SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================================================
-- Procedure:   reporting.pr_report_financial_summary
-- Purpose:     Financial Summary report (Asana Reports-001, PSRC-wtiw): total
--              programmed dollars by funding source and programmed year for one
--              TIP, as an Excel workbook (stored-procedure report).
--              Worksheet "Summary": one row per funding source with a column per
--              year of the TIP window (BeginYear..EndYear), an "Outside TIP years"
--              column for funding programmed in other years, and a row total;
--              a final "Grand total" row.
--              Worksheet "Detail": the same dollars in long form (source, year,
--              amount, project count) for reconciliation against the Posted TIP
--              Project List.
-- Source:      tip.ProgrammedFunding (posted rows, IsActive = 1) for projects on
--              the TIP via tip.ProjectTipMapping. Pending amendments are NOT
--              included — this is the posted position.
-- Parameters:  @TipBeginYear — the TIP to report, by its starting year. NULL =
--              the current TIP (tip.Tip.IsCurrent = 1). Offered as a run-time
--              prompt on the registered report.
-- Created:     2026-09-14 (PSRC-wtiw)
-- =============================================================================
CREATE PROCEDURE [reporting].[pr_report_financial_summary]
    @TipBeginYear SMALLINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TipId     UNIQUEIDENTIFIER
           ,@BeginYear SMALLINT
           ,@EndYear   SMALLINT;

    SELECT TOP (1)
        @TipId     = t.Id
       ,@BeginYear = t.BeginYear
       ,@EndYear   = t.EndYear
    FROM tip.Tip AS t
    WHERE (@TipBeginYear IS NULL AND t.IsCurrent = 1)
       OR (@TipBeginYear IS NOT NULL AND t.BeginYear = @TipBeginYear)
    ORDER BY t.IsCurrent DESC
            ,t.EndYear DESC;

    IF @TipId IS NULL
        THROW 50404, 'No TIP matches the requested starting year.', 1;

    -- Result set 1: worksheet names (the runner's convention for multi-sheet workbooks).
    SELECT TabName = 'Summary'
    UNION ALL
    SELECT TabName = 'Detail';

    -- Posted dollars for the TIP, one row per source and year. A temp table rather than a
    -- table variable so the dynamic pivot below can read it without a table type.
    CREATE TABLE #Detail (
        GroupSortId     INT           NULL
       ,GroupName       NVARCHAR(255) NULL
       ,SourceSortId    INT           NULL
       ,FundingSource   NVARCHAR(255) NOT NULL
       ,GovernmentLevel NVARCHAR(50)  NULL
       ,ProgrammedYear  SMALLINT      NULL
       ,Amount          BIGINT        NOT NULL
       ,Projects        INT           NOT NULL
    );

    INSERT #Detail (
         GroupSortId
        ,GroupName
        ,SourceSortId
        ,FundingSource
        ,GovernmentLevel
        ,ProgrammedYear
        ,Amount
        ,Projects)
    SELECT
        GroupSortId     = g.SortId
       ,GroupName       = g.Description
       ,SourceSortId    = fs.SortId
       ,FundingSource   = COALESCE(fs.Description, fs.Code)
       ,GovernmentLevel = fs.GovernmentLevel
       ,ProgrammedYear  = pf.ProgrammedFundingYear
       ,Amount          = SUM(COALESCE(pf.FundingAmount, 0))
       ,Projects        = COUNT(DISTINCT pf.ProjectId)
    FROM tip.ProgrammedFunding AS pf
    JOIN tip.ProjectTipMapping AS ptm ON ptm.ProjectId = pf.ProjectId
                                     AND ptm.TipId     = @TipId
    JOIN tip.FundingSourceType AS fs  ON fs.Id = pf.FundingSourceTypeId
    LEFT JOIN tip.FinancialSummaryGroupType AS g ON g.Id = fs.FinancialSummaryGroupTypeId
    WHERE pf.IsActive = 1
    GROUP BY g.SortId
            ,g.Description
            ,fs.SortId
            ,fs.Description
            ,fs.Code
            ,fs.GovernmentLevel
            ,pf.ProgrammedFundingYear;

    -- Result set 2: Summary — one column per TIP year. The column list is built from
    -- integers only, so the dynamic SQL carries nothing a caller supplied.
    DECLARE @YearColumns NVARCHAR(MAX) = N''
           ,@YearSums    NVARCHAR(MAX) = N''
           ,@Year        SMALLINT      = @BeginYear;

    WHILE @Year <= @EndYear
    BEGIN
        SET @YearColumns += N',' + QUOTENAME(CAST(@Year AS NVARCHAR(4))) + N' = SUM(CASE WHEN d.ProgrammedYear = ' + CAST(@Year AS NVARCHAR(4)) + N' THEN d.Amount ELSE 0 END)' + NCHAR(10);
        SET @Year += 1;
    END;

    DECLARE @Sql NVARCHAR(MAX) = N'
    SELECT
        [Group]           = d.GroupName
       ,FundingSource     = d.FundingSource
       ,GovernmentLevel   = d.GovernmentLevel
    ' + @YearColumns + N'
       ,OutsideTipYears   = SUM(CASE WHEN d.ProgrammedYear IS NULL OR d.ProgrammedYear < @BeginYear OR d.ProgrammedYear > @EndYear THEN d.Amount ELSE 0 END)
       ,Total             = SUM(d.Amount)
       ,SortOrder         = 0
       ,GroupSortKey      = ISNULL(MIN(d.GroupSortId), 2147483647)   -- sources with no summary group sort last
       ,SourceSortId      = MIN(d.SourceSortId)
    FROM #Detail AS d
    GROUP BY d.GroupName
            ,d.FundingSource
            ,d.GovernmentLevel
    UNION ALL
    SELECT
        [Group]           = NULL
       ,FundingSource     = N''Grand total''
       ,GovernmentLevel   = NULL
    ' + @YearColumns + N'
       ,OutsideTipYears   = SUM(CASE WHEN d.ProgrammedYear IS NULL OR d.ProgrammedYear < @BeginYear OR d.ProgrammedYear > @EndYear THEN d.Amount ELSE 0 END)
       ,Total             = SUM(d.Amount)
       ,SortOrder         = 1
       ,GroupSortKey      = NULL
       ,SourceSortId      = NULL
    FROM #Detail AS d
    ORDER BY SortOrder
            ,GroupSortKey
            ,SourceSortId
            ,FundingSource;';

    -- The sort helper columns travel to the sheet; they are cheap and make the
    -- ordering auditable in Excel.
    EXEC sys.sp_executesql
        @Sql
       ,N'@BeginYear SMALLINT, @EndYear SMALLINT'
       ,@BeginYear = @BeginYear
       ,@EndYear   = @EndYear;

    -- Result set 3: Detail — long form for reconciliation.
    SELECT
        [Group]         = d.GroupName
       ,FundingSource   = d.FundingSource
       ,GovernmentLevel = d.GovernmentLevel
       ,ProgrammedYear  = d.ProgrammedYear
       ,Amount          = d.Amount
       ,Projects        = d.Projects
       ,TipBeginYear    = @BeginYear
       ,TipEndYear      = @EndYear
    FROM #Detail AS d
    ORDER BY ISNULL(d.GroupSortId, 2147483647)
            ,d.SourceSortId
            ,d.FundingSource
            ,d.ProgrammedYear;
END;
GO
