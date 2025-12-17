SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
/*
==================================================
Stored Procedure: dbo.pr_tip_project_find
==================================================
Purpose: **MOCK DATA IMPLEMENTATION** - Provides mock TIP project data for testing purposes.
         This procedure returns hardcoded project data and does not query actual database tables.
         This appears to be a temporary implementation for development/testing.

Author: [Author Name]
Created: [Date]
Modified: [Date] - [Reason for modification]

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID requesting the search (for audit trail)
    @PageSize (INT) - Number of records to return per page
    @Skip (INT) - Number of records to skip (for pagination)
    @Search (VARCHAR(200)) - Search text filter (NOT CURRENTLY IMPLEMENTED)
    @ProjectIds (UniqueIdentifierArrayType) - Specific project IDs to filter (NOT CURRENTLY IMPLEMENTED)
    @ProjectStatusIds (UniqueIdentifierArrayType) - Project status filters (NOT CURRENTLY IMPLEMENTED)
    @ProgramYears (UniqueIdentifierArrayType) - Program year filters (NOT CURRENTLY IMPLEMENTED)
    @FundingSourceIds (UniqueIdentifierArrayType) - Funding source filters (NOT CURRENTLY IMPLEMENTED)
    @AgencyIds (UniqueIdentifierArrayType) - Agency filters (NOT CURRENTLY IMPLEMENTED)

Returns: Two result sets:
         1. Project data with Id and Title columns (mock data)
         2. Total count of available projects (hardcoded to 30)

Example Usage:
    EXEC dbo.pr_tip_project_find 
        @UserId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
        @PageSize = 10,
        @Skip = 0,
        @Search = NULL,
        @ProjectIds = NULL,
        @ProjectStatusIds = NULL,
        @ProgramYears = NULL,
        @FundingSourceIds = NULL,
        @AgencyIds = NULL

Dependencies: None (returns mock data)

Business Rules:
    - **THIS IS MOCK DATA** - Not connected to actual database tables
    - Returns 30 hardcoded project records with street address titles
    - All filter parameters are ignored in current implementation
    - Pagination parameters are ignored in current implementation
    - Total count is hardcoded to 30
    - Each project gets a random GUID for Id

WARNING: This procedure needs to be replaced with actual database queries before production use.
==================================================
*/

CREATE PROCEDURE [dbo].[pr_tip_project_find]
(
    @UserId           UNIQUEIDENTIFIER -- User requesting the search
,   @PageSize         INT -- Records per page (currently ignored)
,   @Skip             INT -- Records to skip (currently ignored)
,   @Search           VARCHAR(200) = NULL -- Search filter (currently ignored)
,   @ProjectStatusIds UniqueIdentifierArrayType READONLY -- Project ID filter (currently ignored)
,   @ProgramYears     UniqueIdentifierArrayType READONLY -- Status filter (currently ignored)
,   @FundingSourceIds UniqueIdentifierArrayType READONLY -- Program year filter (currently ignored)
,   @AgencyIds        UniqueIdentifierArrayType READONLY -- Funding source filter (currently ignored)
,   @ProjectIds       UniqueIdentifierArrayType READONLY -- Agency filter (currently ignored)
) AS
BEGIN
    SET NOCOUNT ON;
    -- Prevent extra result sets from interfering with SELECT statements

    -- **MOCK DATA IMPLEMENTATION** - Return hardcoded project data
    -- TODO: Replace with actual database queries
    SELECT
        Id    = NEWID()
      , Title = '123 Main St'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '456 Elm St'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '789 Oak Ave'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '101 Pine Rd'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '202 Birch Ln'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '303 Cedar St'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '404 Walnut Dr'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '505 Chestnut Ave'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '606 Willow Blvd'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '707 Maple St'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '808 Spruce Ct'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '909 Aspen Way'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '1001 Sycamore Pl'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '1102 Redwood Trl'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '1203 Hickory Blvd'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '1304 Magnolia St'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '1405 Dogwood Ln'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '1506 Poplar St'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '1607 Laurel Ave'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '1708 Beech Rd'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '1809 Cypress St'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '1900 Juniper Ct'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '2001 Palm Blvd'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '2102 Myrtle St'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '2203 Ash Ln'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '2304 Alder Rd'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '2405 Fir Blvd'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '2506 Elmwood Ave'
    UNION ALL
    SELECT
        Id    = NEWID()
      , Title = '2607 Maplewood Dr';

    -- Return hardcoded total count
    SELECT TotalCount = 30;
END;
GO
