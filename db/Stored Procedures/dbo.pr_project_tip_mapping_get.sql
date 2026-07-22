SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
==================================================
Stored Procedure: dbo.pr_project_tip_mapping_get
==================================================
Purpose: Retrieves paginated TIP project mappings for a specific TIP with sorting capabilities.
         Returns projects that are currently mapped to the given TIP along with their
         agency, contact, and status information.

Author: john.hunter@triskelle.solutions
Created: 2025-12-11

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID requesting the data (for audit/authorization)
    @TipId (UNIQUEIDENTIFIER) - TIP ID to get mapped projects for
    @PageSize (INT) - Number of records to return per page
    @Skip (INT) - Number of records to skip (for pagination)
    @SortBy (SortByArrayType) - Dynamic sort configuration (column and direction)

Returns: Two result sets:
    1. Paginated project data with ProjectId, ProjectCode, Title, AgencyName, ContactName, ContactEmail, Status
    2. Total count of all matching records (for pagination UI)

Dependencies:
    - Tables: tip.ProjectTipMapping, tip.Project, common.Agency, common.Contact, tip.CompletionStatusType
    - User-defined types: SortByArrayType

Business Rules:
    - Returns only projects mapped to the specified TIP
    - Supports single-column sorting on ProjectCode, Title, AgencyName, ContactName, Status
    - ContactName is formatted as "FirstName LastName"
    - Default sort by ProjectCode ASC if no sort specified
==================================================
*/
CREATE PROCEDURE [dbo].[pr_project_tip_mapping_get]
(
    @UserId   UNIQUEIDENTIFIER                   -- User making the request
  , @TipId    UNIQUEIDENTIFIER                   -- TIP to get projects for
  , @PageSize INT                                -- Records per page
  , @Skip     INT                                -- Records to skip for pagination
  , @SortBy   SortByArrayType           READONLY -- Dynamic sort configuration
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Variables for sorting (defaults used if no valid sort provided)
    DECLARE
        @SortColumn    NVARCHAR(128) = N'projectcode'
      , @SortDirection VARCHAR(4)    = 'ASC';

    -- Get sort column and direction from parameter (case-insensitive comparison)
    SELECT TOP (1)
           @SortColumn    = LOWER(sb.SortColumn)
         , @SortDirection = CASE
                                WHEN UPPER(sb.SortDirection) = 'DESC' THEN 'DESC'
                                ELSE 'ASC'
                            END
    FROM
        @SortBy sb
    WHERE
        LOWER(sb.SortColumn) IN ('projectcode', 'title', 'agencyname', 'contactname', 'status');

    -- Main query with CTE for pagination
    WITH ProjectData AS
    (
        SELECT
            ProjectId    = proj.Id
          , ProjectCode  = proj.ProjectCode
          , Title        = ISNULL(proj.Title, '')
          , AgencyName   = ISNULL(agency.Name, '')
          , ContactName  = RTRIM(LTRIM(ISNULL(contact.FirstName, '') + ' ' + ISNULL(contact.LastName, '')))
          , ContactEmail = ISNULL(contact.Email, '')
          , Status       = ISNULL(status.Description, '')
          , RowNum      = ROW_NUMBER() OVER (ORDER BY
                              CASE
                                  WHEN @SortColumn = 'projectcode'
                                       AND @SortDirection = 'ASC' THEN proj.ProjectCode
                              END ASC
                            , CASE
                                  WHEN @SortColumn = 'projectcode'
                                       AND @SortDirection = 'DESC' THEN proj.ProjectCode
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
                                  WHEN @SortColumn = 'agencyname'
                                       AND @SortDirection = 'ASC' THEN ISNULL(agency.Name, '')
                              END ASC
                            , CASE
                                  WHEN @SortColumn = 'agencyname'
                                       AND @SortDirection = 'DESC' THEN ISNULL(agency.Name, '')
                              END DESC
                            , CASE
                                  WHEN @SortColumn = 'contactname'
                                       AND @SortDirection = 'ASC' THEN ISNULL(contact.FirstName, '') + ' ' + ISNULL(contact.LastName, '')
                              END ASC
                            , CASE
                                  WHEN @SortColumn = 'contactname'
                                       AND @SortDirection = 'DESC' THEN ISNULL(contact.FirstName, '') + ' ' + ISNULL(contact.LastName, '')
                              END DESC
                            , CASE
                                  WHEN @SortColumn = 'status'
                                       AND @SortDirection = 'ASC' THEN ISNULL(status.Description, '')
                              END ASC
                            , CASE
                                  WHEN @SortColumn = 'status'
                                       AND @SortDirection = 'DESC' THEN ISNULL(status.Description, '')
                              END DESC
                            -- Default sort
                            , proj.ProjectCode ASC
                          )
        FROM
            tip.ProjectTipMapping            AS mapping
            INNER JOIN tip.Project           AS proj
                       ON proj.Id            = mapping.ProjectId
            LEFT JOIN common.Agency          AS agency
                      ON agency.Id           = proj.AgencyId
            LEFT JOIN common.Contact         AS contact
                      ON contact.Id          = proj.ContactId
            LEFT JOIN tip.CompletionStatusType AS status
                      ON status.Id           = proj.CompletionStatusTypeId
        WHERE
            mapping.TipId = @TipId
    )
    -- Return paginated results
    SELECT
        ProjectId
      , ProjectCode
      , Title
      , AgencyName
      , ContactName
      , ContactEmail
      , Status
    FROM
        ProjectData
    WHERE
        RowNum > @Skip
        AND RowNum <= @Skip + @PageSize
    ORDER BY
        RowNum;

    -- Return total count
    SELECT TotalCount = COUNT(*)
    FROM
        tip.ProjectTipMapping
    WHERE
        TipId = @TipId;
END;
GO
