SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
/*
==================================================
Stored Procedure: dbo.pr_tip_project_amendment_summary_view_find
==================================================
Purpose: Retrieves paginated project data for a specific TIP amendment with review area
         statuses for the Summary View. Returns projects with their review area status data
         pivoted by review area type, enabling a consolidated table view of all projects
         and their review statuses.

Author: john.hunter@triskelle.solutions
Created: 2025-12-19
Based on: pr_tip_project_amendment_search_view_find.sql

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID requesting the search (for audit/future authorization)
    @AmendmentId (UNIQUEIDENTIFIER) - Amendment ID to retrieve projects for
    @PageSize (INT) - Number of records to return per page
    @Skip (INT) - Number of records to skip (for pagination)
    @Search (VARCHAR(200)) - Optional search text (searches multiple fields)
    @SortBy (SortByArrayType) - Dynamic sorting configuration with multiple columns
    @AmendmentMappedTypeIds (UniqueIdentifierArrayType) - Filter by amendment mapping types
    @RcpStatusTypeIds (UniqueIdentifierArrayType) - Filter by RCP status types
    @AmendmentReviewStatusTypeIds (UniqueIdentifierArrayType) - Filter by review status types
    @AmendmentSectionTypeIds (UniqueIdentifierArrayType) - Filter by amendment section types
    @AmendmentReviewAreaTypeIds (UniqueIdentifierArrayType) - Filter by review area types with unresolved issues

Returns: Four result sets:
    1. Paginated project data matching all filter criteria
    2. Total count of all matching records (for pagination UI)
    3. Review area type metadata (for dynamic column generation)
    4. Review area statuses per project (for populating status cells)

Performance Notes:
    - Uses ROW_NUMBER() for efficient pagination
    - Dynamic SQL is limited to ORDER BY clause for security
    - All filter parameters are properly parameterized
    - Effective/End date filtering uses Amendment.EffectiveDate as comparator

Security Considerations:
    - Column names validated against whitelist before dynamic SQL construction
    - QUOTENAME() used for all dynamic column references
    - All user input parameterized to prevent SQL injection

Dependencies:
    - Tables: tip.Project, tip.ProjectAmendment, tip.Amendment,
              tip.ProjectAmendmentReviewArea, tip.ProjectAmendmentReviewAreaType,
              tip.ProjectAmendmentReviewAreaStatusType, common.Agency
    - User-defined types: SortByArrayType, UniqueIdentifierArrayType
==================================================
*/
CREATE PROCEDURE [dbo].[pr_tip_project_amendment_summary_view_find]
(
    @UserId                       UNIQUEIDENTIFIER,                   -- User making the request
    @AmendmentId                  UNIQUEIDENTIFIER,                   -- Amendment to search within
    @PageSize                     INT,                                -- Records per page
    @Skip                         INT,                                -- Records to skip for pagination
    @Search                       VARCHAR(200) = NULL,                -- Optional search text
    @SortBy                       SortByArrayType READONLY,           -- Dynamic sort configuration
    @AmendmentMappedTypeIds       UniqueIdentifierArrayType READONLY, -- Amendment type filters
    @RcpStatusTypeIds             UniqueIdentifierArrayType READONLY, -- RCP status filters
    @AmendmentReviewStatusTypeIds UniqueIdentifierArrayType READONLY, -- Review status filters
    @AmendmentSectionTypeIds      UniqueIdentifierArrayType READONLY, -- Section type filters
    @AmendmentReviewAreaTypeIds   UniqueIdentifierArrayType READONLY  -- Unresolved issue types filter
)
AS
BEGIN
    SET NOCOUNT ON;

    -- =============================================
    -- SECTION 1: DETERMINE COMPARATOR DATE FOR EFFECTIVE/END DATE FILTERING
    -- =============================================
    -- Use Amendment.EffectiveDate as the comparator for determining "current" types.
    -- If Amendment.EffectiveDate is NULL, fall back to current date.
    DECLARE @ComparatorDate DATE = ISNULL(
        (SELECT EffectiveDate FROM tip.Amendment WHERE Id = @AmendmentId),
        CAST(GETDATE() AS DATE)
    );

    -- Get the "OK" status type ID for unresolved issues filter
    DECLARE @OkStatusId UNIQUEIDENTIFIER;
    SELECT @OkStatusId = Id
    FROM tip.ProjectAmendmentReviewAreaStatusType
    WHERE Code = 'ok';

    -- =============================================
    -- SECTION 2: DYNAMIC SORTING VALIDATION AND CONSTRUCTION
    -- =============================================
    -- Define valid columns to prevent SQL injection (lowercase for case-insensitive comparison)
    DECLARE @ValidColumns TABLE
    (
        ColumnNameLower NVARCHAR(128) NOT NULL,
        ColumnNameActual NVARCHAR(128) NOT NULL
    );

    -- Column names are qualified with table aliases to avoid ambiguity
    -- between tip.Project and tip.Project_Pending (which share column names).
    -- Values are hardcoded so the whitelist itself provides SQL injection protection.
    INSERT INTO @ValidColumns (ColumnNameLower, ColumnNameActual)
    VALUES
        ('projectid', 'proj.Id'),
        ('projectcode', 'proj.ProjectCode'),
        ('amendmentsectiontypeid', 'proj_amend.AmendmentSectionTypeId'),
        ('projectamendmentreviewstatustypeid', 'proj_amend.ProjectAmendmentReviewStatusTypeId'),
        ('title', 'proj.Title'),
        ('projectamendmentid', 'proj_amend.Id');

    -- Build ORDER BY clause from validated columns only
    DECLARE @OrderByClause NVARCHAR(MAX) = '';

    SELECT @OrderByClause = @OrderByClause +
        CASE
            WHEN @OrderByClause = '' THEN ''
            ELSE ', '
        END +
        vc.ColumnNameActual + ' ' +
        CASE
            WHEN UPPER(sb.SortDirection) = 'DESC' THEN 'DESC'
            ELSE 'ASC'
        END
    FROM @SortBy sb
    INNER JOIN @ValidColumns vc ON LOWER(sb.SortColumn) = vc.ColumnNameLower;

    -- Default sort if no valid sort columns provided
    IF @OrderByClause = ''
        SET @OrderByClause = 'proj.ProjectCode ASC';

    -- =============================================
    -- SECTION 3: BUILD AND EXECUTE DYNAMIC QUERY FOR PROJECTS
    -- =============================================
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @CountSQL NVARCHAR(MAX);
    DECLARE @Parameters NVARCHAR(MAX);

    -- Main query using CTE with ROW_NUMBER() for efficient pagination
    SET @SQL = N'
    WITH ProjectData AS (
        SELECT
            -- Fixed columns for Summary View
            ProjectId = proj.Id,
            PendingProjectId = proj_pending.Id,
            ProjectCode = proj.ProjectCode,
            AmendmentSectionTypeId = proj_amend.AmendmentSectionTypeId,
            ProjectAmendmentReviewStatusTypeId = proj_amend.ProjectAmendmentReviewStatusTypeId,
            Title = proj.Title,
            ProjectAmendmentId = proj_amend.Id,

            -- ROW_NUMBER for pagination
            RowNum = ROW_NUMBER() OVER (ORDER BY ' + @OrderByClause + N')
        FROM tip.Project proj
        INNER JOIN tip.ProjectAmendment proj_amend
            ON proj_amend.ProjectId = proj.Id
        INNER JOIN tip.Project_Pending proj_pending
            ON proj_pending.ProjectAmendmentId = proj_amend.Id
        LEFT JOIN common.Agency agency
            ON agency.Id = proj.AgencyId
        LEFT JOIN common.Contact contact
            ON contact.Id = proj.ContactId
        WHERE
            -- Primary filter - must be for requested amendment
            proj_amend.AmendmentId = @AmendmentId
            AND
            -- Text search filter - searches across multiple fields
            (ISNULL(@Search, '''') = '''' OR
             proj.Title LIKE ''%'' + @Search + ''%'' OR
             proj.ProjectCode LIKE ''%'' + @Search + ''%'' OR
             agency.Name LIKE ''%'' + @Search + ''%'' OR
             contact.FirstName LIKE ''%'' + @Search + ''%'' OR
             contact.LastName LIKE ''%'' + @Search + ''%'' OR
             contact.Email LIKE ''%'' + @Search + ''%'')
            AND
            -- Amendment Mapped Type filter
            (NOT EXISTS (SELECT 1 FROM @AmendmentMappedTypeIds amt) OR
             proj.MappedTypeId IN (SELECT amt.Value FROM @AmendmentMappedTypeIds amt))
            AND
            -- RCP Status filter
            (NOT EXISTS (SELECT 1 FROM @RcpStatusTypeIds rcp) OR
             proj.RcpStatusTypeId IN (SELECT rcp.Value FROM @RcpStatusTypeIds rcp))
            AND
            -- Amendment Review Status filter
            (NOT EXISTS (SELECT 1 FROM @AmendmentReviewStatusTypeIds ars) OR
             proj_amend.ProjectAmendmentReviewStatusTypeId IN (SELECT ars.Value FROM @AmendmentReviewStatusTypeIds ars))
            AND
            -- Amendment Section Type filter
            (NOT EXISTS (SELECT 1 FROM @AmendmentSectionTypeIds ast) OR
             proj_amend.AmendmentSectionTypeId IN (SELECT ast.Value FROM @AmendmentSectionTypeIds ast))
            AND
            -- Unresolved Issue Types filter
            -- Return projects where at least one matching review area has status NOT equal to "OK"
            (NOT EXISTS (SELECT 1 FROM @AmendmentReviewAreaTypeIds arat) OR
             EXISTS (
                SELECT 1
                FROM tip.ProjectAmendmentReviewArea para
                WHERE para.ProjectAmendmentId = proj_amend.Id
                  AND para.ProjectAmendmentReviewAreaTypeId IN (SELECT arat.Value FROM @AmendmentReviewAreaTypeIds arat)
                  AND para.ProjectAmendmentReviewAreaStatusTypeId <> @OkStatusId
             ))
    )
    -- Select only the requested page of results
    SELECT
        ProjectId,
        PendingProjectId,
        ProjectCode,
        AmendmentSectionTypeId,
        ProjectAmendmentReviewStatusTypeId,
        Title,
        ProjectAmendmentId
    FROM ProjectData
    WHERE RowNum > @Skip AND RowNum <= @Skip + @PageSize;';

    -- Separate count query for total records
    SET @CountSQL = N'
    SELECT TotalCount = COUNT(DISTINCT proj.Id)
    FROM tip.Project proj
    INNER JOIN tip.ProjectAmendment proj_amend
        ON proj_amend.ProjectId = proj.Id
    LEFT JOIN common.Agency agency
        ON agency.Id = proj.AgencyId
    LEFT JOIN common.Contact contact
        ON contact.Id = proj.ContactId
    WHERE
        proj_amend.AmendmentId = @AmendmentId
        AND
        (ISNULL(@Search, '''') = '''' OR
         proj.Title LIKE ''%'' + @Search + ''%'' OR
         proj.ProjectCode LIKE ''%'' + @Search + ''%'' OR
         agency.Name LIKE ''%'' + @Search + ''%'' OR
         contact.FirstName LIKE ''%'' + @Search + ''%'' OR
         contact.LastName LIKE ''%'' + @Search + ''%'' OR
         contact.Email LIKE ''%'' + @Search + ''%'')
        AND
        (NOT EXISTS (SELECT 1 FROM @AmendmentMappedTypeIds amt) OR
         proj.MappedTypeId IN (SELECT amt.Value FROM @AmendmentMappedTypeIds amt))
        AND
        (NOT EXISTS (SELECT 1 FROM @RcpStatusTypeIds rcp) OR
         proj.RcpStatusTypeId IN (SELECT rcp.Value FROM @RcpStatusTypeIds rcp))
        AND
        (NOT EXISTS (SELECT 1 FROM @AmendmentReviewStatusTypeIds ars) OR
         proj_amend.ProjectAmendmentReviewStatusTypeId IN (SELECT ars.Value FROM @AmendmentReviewStatusTypeIds ars))
        AND
        (NOT EXISTS (SELECT 1 FROM @AmendmentSectionTypeIds ast) OR
         proj_amend.AmendmentSectionTypeId IN (SELECT ast.Value FROM @AmendmentSectionTypeIds ast))
        AND
        (NOT EXISTS (SELECT 1 FROM @AmendmentReviewAreaTypeIds arat) OR
         EXISTS (
            SELECT 1
            FROM tip.ProjectAmendmentReviewArea para
            WHERE para.ProjectAmendmentId = proj_amend.Id
              AND para.ProjectAmendmentReviewAreaTypeId IN (SELECT arat.Value FROM @AmendmentReviewAreaTypeIds arat)
              AND para.ProjectAmendmentReviewAreaStatusTypeId <> @OkStatusId
         ));';

    -- Define parameters for sp_executesql
    SET @Parameters = N'@AmendmentId UNIQUEIDENTIFIER,
                       @Search VARCHAR(200),
                       @Skip INT,
                       @PageSize INT,
                       @OkStatusId UNIQUEIDENTIFIER,
                       @AmendmentMappedTypeIds UniqueIdentifierArrayType READONLY,
                       @RcpStatusTypeIds UniqueIdentifierArrayType READONLY,
                       @AmendmentReviewStatusTypeIds UniqueIdentifierArrayType READONLY,
                       @AmendmentSectionTypeIds UniqueIdentifierArrayType READONLY,
                       @AmendmentReviewAreaTypeIds UniqueIdentifierArrayType READONLY';

    -- Execute the main query for paginated project results (Result Set 1)
    EXEC sp_executesql @SQL = @SQL,
                       @Parameters = @Parameters,
                       @AmendmentId = @AmendmentId,
                       @Search = @Search,
                       @Skip = @Skip,
                       @PageSize = @PageSize,
                       @OkStatusId = @OkStatusId,
                       @AmendmentMappedTypeIds = @AmendmentMappedTypeIds,
                       @RcpStatusTypeIds = @RcpStatusTypeIds,
                       @AmendmentReviewStatusTypeIds = @AmendmentReviewStatusTypeIds,
                       @AmendmentSectionTypeIds = @AmendmentSectionTypeIds,
                       @AmendmentReviewAreaTypeIds = @AmendmentReviewAreaTypeIds;

    -- Execute the count query for total matching records (Result Set 2)
    EXEC sp_executesql @CountSQL = @CountSQL,
                       @Parameters = @Parameters,
                       @AmendmentId = @AmendmentId,
                       @Search = @Search,
                       @Skip = @Skip,
                       @PageSize = @PageSize,
                       @OkStatusId = @OkStatusId,
                       @AmendmentMappedTypeIds = @AmendmentMappedTypeIds,
                       @RcpStatusTypeIds = @RcpStatusTypeIds,
                       @AmendmentReviewStatusTypeIds = @AmendmentReviewStatusTypeIds,
                       @AmendmentSectionTypeIds = @AmendmentSectionTypeIds,
                       @AmendmentReviewAreaTypeIds = @AmendmentReviewAreaTypeIds;

    -- =============================================
    -- SECTION 4: RETURN REVIEW AREA TYPE METADATA (Result Set 3)
    -- =============================================
    -- Return "current" review area types for dynamic column generation
    -- Filtered by Effective/End date using the comparator date
    SELECT
        Id = parat.Id,
        Code = parat.Code,
        Description = parat.Description,
        SortId = parat.SortId
    FROM tip.ProjectAmendmentReviewAreaType parat
    WHERE parat.EffectiveDate <= @ComparatorDate
      AND (parat.EndDate IS NULL OR parat.EndDate >= @ComparatorDate)
    ORDER BY parat.SortId ASC;

    -- =============================================
    -- SECTION 5: RETURN REVIEW AREA STATUSES PER PROJECT (Result Set 4)
    -- =============================================
    -- Return all review area statuses for projects in the current amendment
    -- This allows the UI to populate the dynamic status cells
    SELECT
        ProjectAmendmentId = para.ProjectAmendmentId,
        ProjectAmendmentReviewAreaId = para.Id,
        ProjectAmendmentReviewAreaTypeId = para.ProjectAmendmentReviewAreaTypeId,
        ProjectAmendmentReviewAreaStatusTypeId = para.ProjectAmendmentReviewAreaStatusTypeId,
        StatusTypeCode = parast.Code,
        StatusTypeDescription = parast.Description
    FROM tip.ProjectAmendmentReviewArea para
    INNER JOIN tip.ProjectAmendment pa
        ON pa.Id = para.ProjectAmendmentId
    INNER JOIN tip.ProjectAmendmentReviewAreaType parat
        ON parat.Id = para.ProjectAmendmentReviewAreaTypeId
    INNER JOIN tip.ProjectAmendmentReviewAreaStatusType parast
        ON parast.Id = para.ProjectAmendmentReviewAreaStatusTypeId
    WHERE pa.AmendmentId = @AmendmentId
      -- Only include statuses for "current" review area types
      AND parat.EffectiveDate <= @ComparatorDate
      AND (parat.EndDate IS NULL OR parat.EndDate >= @ComparatorDate)
    ORDER BY para.ProjectAmendmentId, parat.SortId ASC;
END;
GO
