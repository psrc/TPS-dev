SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
/*
==================================================
Stored Procedure: dbo.pr_tip_project_amendment_search_view_find
==================================================
Purpose: Retrieves paginated pending project data for a specific TIP amendment with search,
         filtering, and dynamic sorting capabilities. Optimized to only fetch the
         requested page of data rather than all matching records.

Author: john.hunter@triskelle.solutions
Created: 2025-07-24
Modified:
    - 2025-07-24: Refactored to use ROW_NUMBER() for efficient pagination
    - 2025-12-12: Fixed case-sensitivity bug in sort column matching - use lowercase comparisons
    - 2025-12-22: Query from pending tables instead of original Project table to show
                  amendment-specific data and return correct Project_Pending.Id

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

Returns: Two result sets:
    1. Paginated pending project data matching all filter criteria
    2. Total count of all matching records (for pagination UI)

Performance Notes:
    - Uses ROW_NUMBER() for efficient pagination - only fetches requested rows
    - Dynamic SQL is limited to ORDER BY clause for security
    - All filter parameters are properly parameterized
    - Count query optimized to exclude unnecessary joins

Security Considerations:
    - Column names validated against whitelist before dynamic SQL construction
    - QUOTENAME() used for all dynamic column references
    - All user input parameterized to prevent SQL injection

Dependencies:
    - Tables: tip.Project_Pending, tip.ProjectAmendment, tip.ProgrammedFunding_Pending,
              tip.ProjectTipMapping, tip.Tip, common.Agency,
              common.UserProfile, common.Contact
    - User-defined types: SortByArrayType, UniqueIdentifierArrayType
==================================================
*/
CREATE PROCEDURE [dbo].[pr_tip_project_amendment_search_view_find]
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
    @AmendmentSectionTypeIds      UniqueIdentifierArrayType READONLY  -- Section type filters
)
AS
BEGIN
    SET NOCOUNT ON;

    -- =============================================
    -- SECTION 1: DYNAMIC SORTING VALIDATION AND CONSTRUCTION
    -- =============================================
    -- Define valid columns to prevent SQL injection (lowercase for case-insensitive comparison)
    -- Only columns listed here can be used for sorting
    DECLARE @ValidColumns TABLE
    (
        ColumnNameLower NVARCHAR(128) NOT NULL,  -- Lowercase for matching
        ColumnNameActual NVARCHAR(128) NOT NULL  -- Actual column name for SQL
    );

    INSERT INTO @ValidColumns (ColumnNameLower, ColumnNameActual)
    VALUES
        ('id', 'Id'),
        ('projectcode', 'ProjectCode'),
        ('agencyname', 'AgencyName'),
        ('title', 'Title'),
        ('amendmentsectiontypeid', 'AmendmentSectionTypeId'),
        ('projectamendmentreviewstatustypeid', 'ProjectAmendmentReviewStatusTypeId'),
        ('totalcost', 'TotalCost'),
        ('contactfirstname', 'ContactFirstName'),
        ('contactlastname', 'ContactLastName'),
        ('contactemail', 'ContactEmail'),
        ('contactphone', 'ContactPhone'),
        ('lastpostedtip', 'LastPostedTip'),
        ('lastupdatedby', 'LastUpdatedBy');

    -- Build ORDER BY clause from validated columns only (case-insensitive matching)
    -- This prevents SQL injection by only using pre-approved column names
    DECLARE @OrderByClause NVARCHAR(MAX) = '';

    SELECT @OrderByClause = @OrderByClause +
        CASE
            WHEN @OrderByClause = '' THEN ''
            ELSE ', '
        END +
        QUOTENAME(vc.ColumnNameActual) + ' ' +              -- Use actual column name for SQL
        CASE
            WHEN UPPER(sb.SortDirection) = 'DESC' THEN 'DESC'
            ELSE 'ASC'                                       -- Default to ASC if not DESC
        END
    FROM @SortBy sb
    INNER JOIN @ValidColumns vc ON LOWER(sb.SortColumn) = vc.ColumnNameLower;  -- Case-insensitive match

    -- Default sort if no valid sort columns provided
    IF @OrderByClause = ''
        SET @OrderByClause = 'ProjectCode ASC';

    -- =============================================
    -- SECTION 2: BUILD AND EXECUTE DYNAMIC QUERY
    -- =============================================
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @CountSQL NVARCHAR(MAX);
    DECLARE @Parameters NVARCHAR(MAX);

    -- Main query using CTE with ROW_NUMBER() for efficient pagination
    -- Only the ORDER BY clause is dynamic - all other parts are static for security
    -- Uses pending tables to show amendment-specific data
    SET @SQL = N'
    WITH ProjectData AS (
        SELECT
            -- Project_Pending Id (used for API route and editing)
            proj_pending.Id,
            -- Original Project Id (used for add dialog filtering)
            proj_amend.ProjectId,
            proj_amend.AmendmentId,
            proj_pending.ProjectCode,
            AgencyName = ISNULL(agency.Name, ''''),
            proj_pending.Title,

            -- Amendment-specific fields
            proj_amend.AmendmentSectionTypeId,
            proj_amend.ProjectAmendmentReviewStatusTypeId,

            -- Aggregated funding total from pending table
            TotalCost = ISNULL(SUM(prog_funding.FundingAmount), 0),

            -- Contact information from pending project
            proj_pending.ContactId,
            contact.FirstName AS ContactFirstName,
            contact.LastName AS ContactLastName,
            contact.Email AS ContactEmail,
            contact.Phone AS ContactPhone,
            contact.PhoneExt AS ContactPhoneExt,

            -- Latest TIP information (from original project via ProjectAmendment.ProjectId)
            LastPostedTip = MAX(tip.Description),

            -- Audit information from pending project
            LastUpdatedBy = ISNULL(user_profile.FullName, ''''),

            -- ROW_NUMBER for pagination - this is the key optimization
            RowNum = ROW_NUMBER() OVER (ORDER BY ' + @OrderByClause + N')
        FROM tip.ProjectAmendment proj_amend
        INNER JOIN tip.Project_Pending proj_pending
            ON proj_pending.ProjectAmendmentId = proj_amend.Id
        LEFT JOIN common.Agency agency
            ON agency.Id = proj_pending.AgencyId
        LEFT JOIN common.UserProfile user_profile
            ON user_profile.UserId = proj_pending.UpdatedById
        LEFT JOIN common.Contact contact
            ON contact.Id = proj_pending.ContactId
        LEFT JOIN tip.ProgrammedFunding_Pending prog_funding
            ON prog_funding.Project_PendingId = proj_pending.Id
               AND prog_funding.IsActive = 1
        LEFT JOIN tip.ProjectTipMapping proj_tip_map
            ON proj_tip_map.ProjectId = proj_amend.ProjectId
        LEFT JOIN tip.Tip tip
            ON tip.Id = proj_tip_map.TipId
        WHERE
            -- Primary filter - must be for requested amendment
            proj_amend.AmendmentId = @AmendmentId
            AND
            -- Text search filter - searches across multiple fields
            (ISNULL(@Search, '''') = '''' OR
             proj_pending.Title LIKE ''%'' + @Search + ''%'' OR
             proj_pending.ProjectCode LIKE ''%'' + @Search + ''%'' OR
             agency.Name LIKE ''%'' + @Search + ''%'' OR
             contact.FirstName LIKE ''%'' + @Search + ''%'' OR
             contact.LastName LIKE ''%'' + @Search + ''%'' OR
             contact.Email LIKE ''%'' + @Search + ''%'' OR
             contact.Phone LIKE ''%'' + @Search + ''%'')
            AND
            -- Amendment Mapped Type filter
            -- If no filter values provided, include all records
            (NOT EXISTS (SELECT 1 FROM @AmendmentMappedTypeIds amt) OR
             proj_pending.MappedTypeId IN (SELECT amt.Value FROM @AmendmentMappedTypeIds amt))
            AND
            -- RCP Status filter
            (NOT EXISTS (SELECT 1 FROM @RcpStatusTypeIds rcp) OR
             proj_pending.RcpStatusTypeId IN (SELECT rcp.Value FROM @RcpStatusTypeIds rcp))
            AND
            -- Amendment Review Status filter
            (NOT EXISTS (SELECT 1 FROM @AmendmentReviewStatusTypeIds ars) OR
             proj_amend.ProjectAmendmentReviewStatusTypeId IN (SELECT ars.Value FROM @AmendmentReviewStatusTypeIds ars))
            AND
            -- Amendment Section Type filter
            (NOT EXISTS (SELECT 1 FROM @AmendmentSectionTypeIds ast) OR
             proj_amend.AmendmentSectionTypeId IN (SELECT ast.Value FROM @AmendmentSectionTypeIds ast))
        GROUP BY
            proj_pending.Id, proj_amend.ProjectId, proj_amend.AmendmentId, proj_pending.ProjectCode, agency.Name, proj_pending.Title,
            proj_amend.AmendmentSectionTypeId, proj_amend.ProjectAmendmentReviewStatusTypeId,
            proj_pending.ContactId, contact.FirstName, contact.LastName, contact.Email,
            contact.Phone, contact.PhoneExt, user_profile.FullName
    )
    -- Select only the requested page of results
    -- This is the key optimization - we only process the rows we need
    SELECT
        Id,
        ProjectId,
        AmendmentId,
        ProjectCode,
        AgencyName,
        Title,
        AmendmentSectionTypeId,
        ProjectAmendmentReviewStatusTypeId,
        TotalCost,
        ContactId,
        ContactFirstName,
        ContactLastName,
        ContactEmail,
        ContactPhone,
        ContactPhoneExt,
        LastPostedTip,
        LastUpdatedBy
    FROM ProjectData
    WHERE RowNum > @Skip AND RowNum <= @Skip + @PageSize;';

    -- Separate count query for total records
    -- Optimized to only include the necessary joins for counting
    -- Uses pending tables to match main query
    SET @CountSQL = N'
    SELECT TotalCount = COUNT(DISTINCT proj_pending.Id)
    FROM tip.ProjectAmendment proj_amend
    INNER JOIN tip.Project_Pending proj_pending
        ON proj_pending.ProjectAmendmentId = proj_amend.Id
    LEFT JOIN common.Agency agency
        ON agency.Id = proj_pending.AgencyId    -- Needed for search
    LEFT JOIN common.Contact contact
        ON contact.Id = proj_pending.ContactId   -- Needed for search
    WHERE
        -- Same filter criteria as main query
        proj_amend.AmendmentId = @AmendmentId
        AND
        -- Text search filter
        (ISNULL(@Search, '''') = '''' OR
         proj_pending.Title LIKE ''%'' + @Search + ''%'' OR
         proj_pending.ProjectCode LIKE ''%'' + @Search + ''%'' OR
         agency.Name LIKE ''%'' + @Search + ''%'' OR
         contact.FirstName LIKE ''%'' + @Search + ''%'' OR
         contact.LastName LIKE ''%'' + @Search + ''%'' OR
         contact.Email LIKE ''%'' + @Search + ''%'' OR
         contact.Phone LIKE ''%'' + @Search + ''%'')
        AND
        -- Type filters (same as main query)
        (NOT EXISTS (SELECT 1 FROM @AmendmentMappedTypeIds amt) OR
         proj_pending.MappedTypeId IN (SELECT amt.Value FROM @AmendmentMappedTypeIds amt))
        AND
        (NOT EXISTS (SELECT 1 FROM @RcpStatusTypeIds rcp) OR
         proj_pending.RcpStatusTypeId IN (SELECT rcp.Value FROM @RcpStatusTypeIds rcp))
        AND
        (NOT EXISTS (SELECT 1 FROM @AmendmentReviewStatusTypeIds ars) OR
         proj_amend.ProjectAmendmentReviewStatusTypeId IN (SELECT ars.Value FROM @AmendmentReviewStatusTypeIds ars))
        AND
        (NOT EXISTS (SELECT 1 FROM @AmendmentSectionTypeIds ast) OR
         proj_amend.AmendmentSectionTypeId IN (SELECT ast.Value FROM @AmendmentSectionTypeIds ast));';

    -- Define parameters for sp_executesql
    SET @Parameters = N'@AmendmentId UNIQUEIDENTIFIER, 
                       @Search VARCHAR(200), 
                       @Skip INT, 
                       @PageSize INT,
                       @AmendmentMappedTypeIds UniqueIdentifierArrayType READONLY,
                       @RcpStatusTypeIds UniqueIdentifierArrayType READONLY,
                       @AmendmentReviewStatusTypeIds UniqueIdentifierArrayType READONLY,
                       @AmendmentSectionTypeIds UniqueIdentifierArrayType READONLY';
    
    -- Execute the main query for paginated results
    EXEC sp_executesql @SQL = @SQL, 
                       @Parameters = @Parameters, 
                       @AmendmentId = @AmendmentId,
                       @Search = @Search,
                       @Skip = @Skip, 
                       @PageSize = @PageSize,
                       @AmendmentMappedTypeIds = @AmendmentMappedTypeIds,
                       @RcpStatusTypeIds = @RcpStatusTypeIds,
                       @AmendmentReviewStatusTypeIds = @AmendmentReviewStatusTypeIds,
                       @AmendmentSectionTypeIds = @AmendmentSectionTypeIds;

    -- Execute the count query for total matching records
    EXEC sp_executesql @CountSQL = @CountSQL, 
                       @Parameters = @Parameters, 
                       @AmendmentId = @AmendmentId,
                       @Search = @Search,
                       @Skip = @Skip, 
                       @PageSize = @PageSize,
                       @AmendmentMappedTypeIds = @AmendmentMappedTypeIds,
                       @RcpStatusTypeIds = @RcpStatusTypeIds,
                       @AmendmentReviewStatusTypeIds = @AmendmentReviewStatusTypeIds,
                       @AmendmentSectionTypeIds = @AmendmentSectionTypeIds;
END;
GO
