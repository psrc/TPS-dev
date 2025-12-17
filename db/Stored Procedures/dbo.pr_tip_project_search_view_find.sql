SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
/*
==================================================
Stored Procedure: dbo.pr_tip_project_search_view_find
==================================================
Purpose: Retrieves paginated TIP project data with search, filtering, and single-column
         sorting capabilities. Uses CTE for efficient filtering and pagination without
         storing unnecessary rows.

Author: john.hunter@triskelle.solutions
Created: 2025-06-15
Modified:
    - 2025-07-28: Updated @Search fields
    - 2025-07-28: Refactored to use ROW_NUMBER() for efficient pagination and align with amendment search pattern
    - 2025-07-29: Refactored to use CROSS APPLY instead of inner joins for aggregations
    - 2025-07-29: Refactored to include Amendment information
    - 2025-08-08: Removed dynamic SQL and implemented CTE approach for single-column sorting with efficient pagination
    - 2025-12-12: Fixed case-sensitivity bug in sort column matching - use lowercase comparisons throughout

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID requesting the search (for audit/future authorization)
    @PageSize (INT) - Number of records to return per page
    @Skip (INT) - Number of records to skip (for pagination)
    @Search (VARCHAR(200)) - Optional search text (searches multiple fields)
    @SortColumn (NVARCHAR(128)) - Column name to sort by
    @SortDirection (VARCHAR(4)) - Sort direction (ASC or DESC)
    @TipIds (UniqueIdentifierArrayType) - Filter by TIP IDs
    @ProjectStatusIds (UniqueIdentifierArrayType) - Filter by project status types
    @ProgramYears (IntArrayType) - Filter by program years
    @FundingSourceIds (UniqueIdentifierArrayType) - Filter by funding source types
    @AgencyIds (UniqueIdentifierArrayType) - Filter by agency IDs

Returns: Two result sets:
    1. Paginated project data matching all filter criteria
    2. Total count of all matching records (for pagination UI)

Performance Notes:
    - Uses CTE with ROW_NUMBER() for efficient pagination
    - Only fetches the requested page of data
    - Separate optimized count query

Dependencies:
    - Tables: tip.Project, tip.ProgrammedFunding, tip.ProjectTipMapping, 
              tip.Tip, common.Agency, common.UserProfile, common.Contact,
              tip.ProjectBudget
    - User-defined types: UniqueIdentifierArrayType, IntArrayType
==================================================
*/
CREATE PROCEDURE [dbo].[pr_tip_project_search_view_find]
(
    @UserId           UNIQUEIDENTIFIER                   -- User making the request
  , @PageSize         INT                                -- Records per page
  , @Skip             INT                                -- Records to skip for pagination
  , @Search           VARCHAR(200) = NULL                -- Optional search text
  , @SortBy           SortByArrayType           READONLY -- Dynamic sort configuration
  , @TipIds           UniqueIdentifierArrayType READONLY -- TIP filters
  , @ProjectStatusIds UniqueIdentifierArrayType READONLY -- Project status filters
  , @ProgramYears     IntArrayType              READONLY -- Program year filters
  , @FundingSourceIds UniqueIdentifierArrayType READONLY -- Funding source filters
  , @AgencyIds        UniqueIdentifierArrayType READONLY -- Agency filters
)
AS
    BEGIN
        SET NOCOUNT ON;

        -- Variable to store the total count
        DECLARE
            @TotalCount    INT
          , @SortColumn    NVARCHAR(128) = N'projectcode' -- Column to sort by (lowercase for case-insensitive comparison)
          , @SortDirection VARCHAR(4)    = 'ASC';         -- Sort direction (ASC/DESC)

        -- CREATE RESULTS TABLE
        -- =============================================
        DECLARE @results TABLE
        (
            RowNum              INT              NOT NULL
          , Id                  UNIQUEIDENTIFIER NOT NULL
          , ProjectCode         NVARCHAR(20)     NOT NULL
          , AgencyName          NVARCHAR(255)    NOT NULL
          , Title               NVARCHAR(500)    NOT NULL
          , Description         NVARCHAR(MAX)    NULL
          , TotalCost           DECIMAL(19, 2)   NOT NULL
          , ContactId           UNIQUEIDENTIFIER NULL
          , ContactFirstName    NVARCHAR(100)    NULL
          , ContactLastName     NVARCHAR(100)    NULL
          , ContactEmail        NVARCHAR(255)    NULL
          , ContactPhone        NVARCHAR(20)     NULL
          , ContactPhoneExt     NVARCHAR(10)     NULL
          , LastPostedTip       NVARCHAR(255)    NULL
          , LastPostedAmendment NVARCHAR(255)    NULL
          , PendingAmendments   NVARCHAR(MAX)    NULL
          , LastUpdatedBy       NVARCHAR(255)    NOT NULL
        );

        -- =============================================
        -- SECTION 1: DYNAMIC SORTING VALIDATION
        -- =============================================
        -- Get sort column and direction from parameter (case-insensitive comparison)
        -- Only valid column names are accepted to prevent SQL injection
        SELECT TOP (1)
               @SortColumn    = LOWER(sb.SortColumn)
             , @SortDirection = CASE
                                    WHEN UPPER(sb.SortDirection) = 'DESC' THEN 'DESC'
                                    ELSE 'ASC' -- Default to ASC if not DESC
                                END
        FROM
            @SortBy sb
        WHERE
            LOWER(sb.SortColumn) IN ('id', 'projectcode', 'agencyname', 'title', 'totalcost', 'contactlastname', 'lastpostedtip');



        -- =============================================
        -- MAIN QUERY WITH CTE FOR PAGINATION
        -- =============================================
        WITH ProjectData
          AS
          (SELECT
               -- Project base information
               Id                  = proj.Id
             , ProjectCode         = proj.ProjectCode
             , AgencyName          = ISNULL(agency.Name, '')
             , Title               = proj.Title
             , Description         = proj.Description
             -- Aggregated total cost
             , TotalCost           = ISNULL(cost_summary.TotalCost, 0)
             -- Contact information
             , ContactId           = proj.ContactId
             , ContactFirstName    = contact.FirstName
             , ContactLastName     = contact.LastName
             , ContactEmail        = contact.Email
             , ContactPhone        = contact.Phone
             , ContactPhoneExt     = contact.PhoneExt
             -- Latest TIP information (most recent by end year)
             , LastPostedTip       = tip_summary.LastPostedTip
             -- Amendment Information (most recent and pending)
             , LastPostedAmendment = last_posted_amendment.LastPostedAmendment
             , PendingAmendments   = open_amendments.OpenAmendments
             -- Audit information
             , LastUpdatedBy       = ISNULL(user_profile.FullName, 'PSRC Staff')
             -- ROW_NUMBER for pagination with single-column sorting (using lowercase comparisons)
             , RowNum              = ROW_NUMBER() OVER (ORDER BY
                                                            CASE
                                                                WHEN @SortColumn = 'id'
                                                                     AND @SortDirection = 'ASC' THEN CAST(proj.Id AS NVARCHAR(36))
                                                            END ASC
                                                          , CASE
                                                                WHEN @SortColumn = 'id'
                                                                     AND @SortDirection = 'DESC' THEN CAST(proj.Id AS NVARCHAR(36))
                                                            END DESC
                                                          , CASE
                                                                WHEN @SortColumn = 'projectcode'
                                                                     AND @SortDirection = 'ASC' THEN proj.ProjectCode
                                                            END ASC
                                                          , CASE
                                                                WHEN @SortColumn = 'projectcode'
                                                                     AND @SortDirection = 'DESC' THEN proj.ProjectCode
                                                            END DESC
                                                          , CASE
                                                                WHEN @SortColumn = 'agencyname'
                                                                     AND @SortDirection = 'ASC' THEN ISNULL(agency.Name, '')
                                                            END ASC
                                                          , CASE
                                                                WHEN @SortColumn = 'agencyname'
                                                                     AND @SortDirection = 'DESC' THEN ISNULL(agency.Name, '')
                                                            END DESC
                                                          , CASE
                                                                WHEN @SortColumn = 'title'
                                                                     AND @SortDirection = 'ASC' THEN proj.Title
                                                            END ASC
                                                          , CASE
                                                                WHEN @SortColumn = 'title'
                                                                     AND @SortDirection = 'DESC' THEN proj.Title
                                                            END DESC
                                                          , CASE
                                                                WHEN @SortColumn = 'totalcost'
                                                                     AND @SortDirection = 'ASC' THEN ISNULL(cost_summary.TotalCost, 0)
                                                            END ASC
                                                          , CASE
                                                                WHEN @SortColumn = 'totalcost'
                                                                     AND @SortDirection = 'DESC' THEN ISNULL(cost_summary.TotalCost, 0)
                                                            END DESC
                                                          , CASE
                                                                WHEN @SortColumn = 'contactlastname'
                                                                     AND @SortDirection = 'ASC' THEN ISNULL(contact.LastName, '') + ',' + ISNULL(contact.FirstName, '')
                                                            END ASC
                                                          , CASE
                                                                WHEN @SortColumn = 'contactlastname'
                                                                     AND @SortDirection = 'DESC' THEN ISNULL(contact.LastName, '') + ',' + ISNULL(contact.FirstName, '')
                                                            END DESC
                                                          , CASE
                                                                WHEN @SortColumn = 'lastpostedtip'
                                                                     AND @SortDirection = 'ASC' THEN tip_summary.LastPostedTip
                                                            END ASC
                                                          , CASE
                                                                WHEN @SortColumn = 'lastpostedtip'
                                                                     AND @SortDirection = 'DESC' THEN tip_summary.LastPostedTip
                                                            END DESC
                                                          -- Default sort if column not recognized
                                                          , proj.ProjectCode ASC
                                                       )
           FROM
               tip.Project                  proj
               LEFT JOIN common.Agency      AS agency
                         ON agency.Id = proj.AgencyId
               LEFT JOIN common.UserProfile AS user_profile
                         ON user_profile.UserId = proj.UpdatedById
               LEFT JOIN common.Contact     AS contact
                         ON contact.Id = proj.ContactId
               -- Subquery to get project cost
               LEFT JOIN (
                             SELECT
                                 project_budget.ProjectId
                               , TotalCost = SUM(project_budget.TotalAmount)
                             FROM
                                 tip.ProjectBudget AS project_budget
                             GROUP BY
                                 project_budget.ProjectId
                         )                  cost_summary
                         ON cost_summary.ProjectId = proj.Id
               -- Subquery to get latest TIP description
               OUTER APPLY (
                               SELECT TOP (1)
                                      LastPostedTip = tip.Description
                               FROM
                                   tip.ProjectTipMapping AS proj_tip_mapping
                                   JOIN tip.Tip          AS tip
                                        ON tip.Id = proj_tip_mapping.TipId
                               WHERE
                                   proj_tip_mapping.ProjectId = proj.Id
                               ORDER BY
                                   tip.EndYear DESC -- Gets the most recent TIP by end year
                           )                tip_summary
               OUTER APPLY (
                               SELECT TOP (1)
                                      LastPostedAmendment = amendment.Name
                               FROM
                                   tip.ProjectAmendment         AS proj_amendment
                                   JOIN tip.Amendment           AS amendment
                                        ON amendment.Id         = proj_amendment.AmendmentId
                                   JOIN tip.AmendmentStatusType AS amend_status_type
                                        ON amend_status_type.Id = amendment.AmendmentStatusTypeId
                               WHERE
                                   proj_amendment.ProjectId   = proj.Id
                                   AND amend_status_type.Code = 'posted'
                               ORDER BY
                                   amendment.WsdotPostedDate DESC -- Gets the most recent posted Amendment
                           ) last_posted_amendment
               OUTER APPLY (
                               SELECT OpenAmendments = STRING_AGG(amendment.Name, ', ')
                               FROM
                                   tip.ProjectAmendment         AS proj_amendment
                                   JOIN tip.Amendment           AS amendment
                                        ON amendment.Id         = proj_amendment.AmendmentId
                                   JOIN tip.AmendmentStatusType AS amend_status_type
                                        ON amend_status_type.Id = amendment.AmendmentStatusTypeId
                               WHERE
                                   proj_amendment.ProjectId = proj.Id
                                   AND amend_status_type.Code NOT IN ('posted')
                           ) open_amendments
           WHERE
               -- Text search filter - searches across multiple fields
               (
                   ISNULL(@Search, '') = ''
                   OR proj.Title LIKE '%' + @Search + '%'
                   OR proj.ProjectCode LIKE '%' + @Search + '%'
                   OR proj.Description LIKE '%' + @Search + '%'
                   OR proj.Location LIKE '%' + @Search + '%'
                   OR proj.LocationFrom LIKE '%' + @Search + '%'
                   OR proj.LocationTo LIKE '%' + @Search + '%'
                   OR agency.Name LIKE '%' + @Search + '%'
                   OR contact.FirstName LIKE '%' + @Search + '%'
                   OR contact.LastName LIKE '%' + @Search + '%'
                   OR contact.Email LIKE '%' + @Search + '%'
                   OR contact.Phone LIKE '%' + @Search + '%'
               )
               AND
               -- TIP filter
               (
                   NOT EXISTS (
                                  SELECT 1 FROM @TipIds t
                              )
                   OR EXISTS (
                                 SELECT 1
                                 FROM
                                     tip.ProjectTipMapping ptm
                                 WHERE
                                     ptm.ProjectId = proj.Id
                                     AND ptm.TipId IN (
                                                          SELECT t.Value FROM @TipIds t
                                                      )
                             )
               )
               AND
               -- Project Status filter
               (
                   NOT EXISTS (
                                  SELECT 1 FROM @ProjectStatusIds ps
                              )
                   OR proj.CompletionStatusTypeId IN (
                                                         SELECT ps.Value FROM @ProjectStatusIds ps
                                                     )
               )
               AND
               -- Program Years filter
               (
                   NOT EXISTS (
                                  SELECT 1 FROM @ProgramYears py
                              )
                   OR EXISTS (
                                 SELECT 1
                                 FROM
                                     tip.ProgrammedFunding pf
                                 WHERE
                                     pf.ProjectId    = proj.Id
                                     AND pf.IsActive = 1
                                     AND pf.ProgrammedFundingYear IN (
                                                                         SELECT py.Value FROM @ProgramYears py
                                                                     )
                             )
               )
               AND
               -- Funding Source filter
               (
                   NOT EXISTS (
                                  SELECT 1 FROM @FundingSourceIds fs
                              )
                   OR EXISTS (
                                 SELECT 1
                                 FROM
                                     tip.ProjectBudget pb
                                 WHERE
                                     pb.ProjectId = proj.Id
                                     AND pb.FundingSourceTypeId IN (
                                                                       SELECT fs.Value FROM @FundingSourceIds fs
                                                                   )
                             )
               )
               AND
               -- Agency filter
               (
                   NOT EXISTS (
                                  SELECT 1 FROM @AgencyIds a
                              )
                   OR proj.AgencyId IN (
                                           SELECT a.Value FROM @AgencyIds a
                                       )
               ))
        -- Select only the requested page of results
        INSERT @results
            (RowNum
           , Id
           , ProjectCode
           , AgencyName
           , Title
           , Description
           , TotalCost
           , ContactId
           , ContactFirstName
           , ContactLastName
           , ContactEmail
           , ContactPhone
           , ContactPhoneExt
           , LastPostedTip
           , LastPostedAmendment
           , PendingAmendments
           , LastUpdatedBy)
               SELECT
                   ProjectData.RowNum
                 , ProjectData.Id
                 , ProjectData.ProjectCode
                 , ProjectData.AgencyName
                 , ProjectData.Title
                 , ProjectData.Description
                 , ProjectData.TotalCost
                 , ProjectData.ContactId
                 , ProjectData.ContactFirstName
                 , ProjectData.ContactLastName
                 , ProjectData.ContactEmail
                 , ProjectData.ContactPhone
                 , ProjectData.ContactPhoneExt
                 , ProjectData.LastPostedTip
                 , ProjectData.LastPostedAmendment
                 , ProjectData.PendingAmendments
                 , ProjectData.LastUpdatedBy
               FROM
                   ProjectData
               WHERE
                   ProjectData.RowNum     > @Skip
                   AND ProjectData.RowNum <= @Skip + @PageSize;

        -- =============================================
        -- FILTERED AND PAGED RESULTS
        -- =============================================
        SELECT
            RowNum              = r.RowNum
          , Id                  = r.Id
          , ProjectCode         = r.ProjectCode
          , AgencyName          = r.AgencyName
          , Title               = r.Title
          , Description         = r.Description
          , TotalCost           = r.TotalCost
          , ContactId           = r.ContactId
          , ContactFirstName    = r.ContactFirstName
          , ContactLastName     = r.ContactLastName
          , ContactEmail        = r.ContactEmail
          , ContactPhone        = r.ContactPhone
          , ContactPhoneExt     = r.ContactPhoneExt
          , LastPostedTip       = r.LastPostedTip
          , LastPostedAmendment = r.LastPostedAmendment
          , PendingAmendments   = r.PendingAmendments
          , LastUpdatedBy       = r.LastUpdatedBy
        FROM
            @results AS r;

        -- =============================================
        -- SEPARATE COUNT QUERY (OPTIMIZED)
        -- =============================================
        SELECT TotalCount = COUNT(DISTINCT proj.Id)
        FROM
            tip.Project              AS proj
            LEFT JOIN common.Agency  AS agency
                      ON agency.Id  = proj.AgencyId -- Needed for search
            LEFT JOIN common.Contact AS contact
                      ON contact.Id = proj.ContactId -- Needed for search
        WHERE
            -- Text search filter
            (
                ISNULL(@Search, '') = ''
                OR proj.Title LIKE '%' + @Search + '%'
                OR proj.ProjectCode LIKE '%' + @Search + '%'
                OR proj.Description LIKE '%' + @Search + '%'
                OR proj.Location LIKE '%' + @Search + '%'
                OR proj.LocationFrom LIKE '%' + @Search + '%'
                OR proj.LocationTo LIKE '%' + @Search + '%'
                OR agency.Name LIKE '%' + @Search + '%'
                OR contact.FirstName LIKE '%' + @Search + '%'
                OR contact.LastName LIKE '%' + @Search + '%'
                OR contact.Email LIKE '%' + @Search + '%'
                OR contact.Phone LIKE '%' + @Search + '%'
            )
            AND
            -- Type filters (same as main query)
            (
                NOT EXISTS (
                               SELECT 1 FROM @TipIds t
                           )
                OR EXISTS (
                              SELECT 1
                              FROM
                                  tip.ProjectTipMapping ptm
                              WHERE
                                  ptm.ProjectId = proj.Id
                                  AND ptm.TipId IN (
                                                       SELECT t.Value FROM @TipIds t
                                                   )
                          )
            )
            AND (
                    NOT EXISTS (
                                   SELECT 1 FROM @ProjectStatusIds ps
                               )
                    OR proj.CompletionStatusTypeId IN (
                                                          SELECT ps.Value FROM @ProjectStatusIds ps
                                                      )
                )
            AND (
                    NOT EXISTS (
                                   SELECT 1 FROM @ProgramYears py
                               )
                    OR EXISTS (
                                  SELECT 1
                                  FROM
                                      tip.ProgrammedFunding pf
                                  WHERE
                                      pf.ProjectId    = proj.Id
                                      AND pf.IsActive = 1
                                      AND pf.ProgrammedFundingYear IN (
                                                                          SELECT py.Value FROM @ProgramYears py
                                                                      )
                              )
                )
            AND (
                    NOT EXISTS (
                                   SELECT 1 FROM @FundingSourceIds fs
                               )
                    OR EXISTS (
                                  SELECT 1
                                  FROM
                                      tip.ProjectBudget pb
                                  WHERE
                                      pb.ProjectId = proj.Id
                                      AND pb.FundingSourceTypeId IN (
                                                                        SELECT fs.Value FROM @FundingSourceIds fs
                                                                    )
                              )
                )
            AND (
                    NOT EXISTS (
                                   SELECT 1 FROM @AgencyIds a
                               )
                    OR proj.AgencyId IN (
                                            SELECT a.Value FROM @AgencyIds a
                                        )
                );


    END;
GO
