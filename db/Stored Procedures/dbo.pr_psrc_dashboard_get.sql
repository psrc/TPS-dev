SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
/*
================================================================================
STORED PROCEDURE: dbo.pr_psrc_dashboard_get
================================================================================
PURPOSE: 
    Retrieves dashboard data for PSRC (Puget Sound Regional Council) including:
    - Dashboard tiles with navigation links
    - Project information (TIP and RCP projects)
    - Amendment details with status and due dates
    - Report listings
    - Application data with metrics

PARAMETERS:
    @UserId UNIQUEIDENTIFIER - User identifier for potential future personalization

RETURNS:
    Five result sets:
    1. Tile information for dashboard layout
    2. Project metrics and links
    3. Amendment details with status tracking
    4. Available reports
    5. Application data with due dates

AUTHOR: john.hunter@triskelle.solutions
CREATED: 2025-07-03
MODIFIED: 7/3/2025 - Added comprehensive comments and cleaned formatting
================================================================================
*/
CREATE PROCEDURE [dbo].[pr_psrc_dashboard_get]
(
    @UserId UNIQUEIDENTIFIER
) AS
BEGIN
    SET NOCOUNT ON;

    /*
    ============================================================================
    DECLARE TABLE VARIABLES FOR STRUCTURED DATA COLLECTION
    ============================================================================
    These table variables act as temporary storage for organizing different
    types of dashboard data before returning as separate result sets.
    */

    -- Main dashboard tiles configuration
    DECLARE @tile_information TABLE
                              (
                                  Heading     NVARCHAR(MAX) NOT NULL -- Primary tile heading
                                  ,
                                  SubHeading  NVARCHAR(MAX) NOT NULL -- Secondary information/date
                                  ,
                                  Description NVARCHAR(MAX) NOT NULL -- Tile description text
                                  ,
                                  TypeId      INT           NOT NULL -- Tile type identifier
                                  ,
                                  Link1Text   NVARCHAR(MAX) NOT NULL -- Primary action link text
                                  ,
                                  Link1Route  NVARCHAR(MAX) NOT NULL -- Primary action route/URL
                                  ,
                                  Link2Text   NVARCHAR(MAX) NOT NULL -- Secondary action link text (optional)
                                  ,
                                  Link2Route  NVARCHAR(MAX) NOT NULL -- Secondary action route/URL (optional)
                                  ,
                                  SortId      INT           NOT NULL -- Display order
                              );

    -- Project-related metrics and links
    DECLARE @project_information TABLE
                                 (
                                     Title      NVARCHAR(MAX) NOT NULL -- Project category title
                                     ,
                                     Link       NVARCHAR(MAX) NOT NULL -- Navigation link
                                     ,
                                     Metric     NVARCHAR(MAX) NOT NULL -- Metric value (count or amount)
                                     ,
                                     TileTypeId INT           NOT NULL -- Associated tile type
                                     ,
                                     SortId     INT           NOT NULL -- Display order
                                 );

    -- Amendment tracking information
    DECLARE @amendment_information TABLE
                                   (
                                       Title      NVARCHAR(MAX) NOT NULL -- Amendment identifier
                                       ,
                                       DueDate    NVARCHAR(MAX) NULL     -- Due date for amendment
                                       ,
                                       Metric     NVARCHAR(MAX) NOT NULL -- Associated metric/count (project count)
                                       ,
                                       Metric2    NVARCHAR(MAX) NOT NULL -- Count of unresolved projects
                                       ,
                                       StatusId   UNIQUEIDENTIFIER NOT NULL -- Amendment status type ID (GUID)
                                       ,
                                       Link       NVARCHAR(MAX) NOT NULL -- Navigation link
                                       ,
                                       TileTypeId INT           NOT NULL -- Associated tile type
                                       ,
                                       SortId     INT           NOT NULL -- Display order
                                   );

    -- Report listings and navigation
    DECLARE @report_information TABLE
                                (
                                    Text       NVARCHAR(MAX) NOT NULL -- Report name/description
                                    ,
                                    Link       NVARCHAR(MAX) NOT NULL -- Direct download/view link
                                    ,
                                    Route      NVARCHAR(MAX) NOT NULL -- Application route
                                    ,
                                    TileTypeId INT           NOT NULL -- Associated tile type
                                    ,
                                    SortId     INT           NOT NULL -- Display order
                                );

    -- Application submission tracking
    DECLARE @application_information TABLE
                                     (
                                         Title      NVARCHAR(MAX) NOT NULL -- Application name/period
                                         ,
                                         DueDate    NVARCHAR(MAX) NOT NULL -- Submission due date
                                         ,
                                         Metric     NVARCHAR(MAX) NOT NULL -- Count of submissions
                                         ,
                                         Link       NVARCHAR(MAX) NOT NULL -- Management link
                                         ,
                                         TileTypeId INT           NOT NULL -- Associated tile type
                                         ,
                                         SortId     INT           NOT NULL -- Display order
                                     );

    -- Declarations
    DECLARE @as_of_date_string NVARCHAR(MAX) = N'As of ' + CONVERT(NVARCHAR(10), GETDATE(), 101);

    /*
    ============================================================================
    POPULATE DASHBOARD TILES
    ============================================================================
    Main navigation tiles for the dashboard. Each tile represents a major
    functional area with links to detailed views.
    
    TypeId mapping:
    1 = TIP Projects, 2 = TIP Amendments, 3 = RCP Projects, 
    4 = RCP Amendments, 5 = Reports, 6 = Applications
    */
    INSERT
        INTO @tile_information
            (Heading, SubHeading, Description, TypeId, Link1Text, Link1Route, Link2Text, Link2Route, SortId)
    SELECT
        Heading     = 'TIP Projects'
      , SubHeading  = @as_of_date_string
      , Description = 'Transportation Improvement Program project tracking and management'
      , TypeId      = 1
      , Link1Text   = 'More'
      , Link1Route  = '/psrc/tip/projects/dashboard'
      , Link2Text   = ''
      , Link2Route  = ''
      , SortId      = 1
    UNION ALL
    SELECT
        Heading     = 'TIP Amendments'
      , SubHeading  = CAST(COUNT(*) AS NVARCHAR(10)) + ' Active Amendments'
      , Description = 'Current amendments to the Transportation Improvement Program'
      , TypeId      = 2
      , Link1Text   = 'More'
      , Link1Route  = '/psrc/tip/amendments/dashboard'
      , Link2Text   = ''
      , Link2Route  = ''
      , SortId      = 2
        FROM
            tip.Amendment AS amendment
            JOIN tip.AmendmentStatusType AS status_type
                 ON status_type.Id = amendment.AmendmentStatusTypeId
            JOIN tip.AmendmentMappedType AS mapped_type
                 ON mapped_type.Id = amendment.AmendmentMappedTypeId
        WHERE
             status_type.Code NOT IN ('posted')
          OR mapped_type.Code IN ('Not Yet Mapped')
    UNION ALL
    SELECT
        Heading     = 'RCP Projects'
      , SubHeading  = @as_of_date_string
      , Description = 'Regional Capital Program project tracking and oversight'
      , TypeId      = 3
      , Link1Text   = 'More'
      , Link1Route  = '/psrc/rcp/projects'
      , Link2Text   = ''
      , Link2Route  = ''
      , SortId      = 3
    UNION ALL
    SELECT
        Heading     = 'RCP Amendments'
      , SubHeading  = 'Count Not Available'
      , Description = 'Current amendments to the Regional Capital Program'
      , TypeId      = 4
      , Link1Text   = 'More'
      , Link1Route  = '/psrc/rcp/amendments'
      , Link2Text   = ''
      , Link2Route  = ''
      , SortId      = 4
    UNION ALL
    SELECT
        Heading     = 'Reports'
      , SubHeading  = ''
      , Description = 'Access to generated reports and documentation'
      , TypeId      = 5
      , Link1Text   = 'More'
      , Link1Route  = '/psrc/reports'
      , Link2Text   = ''
      , Link2Route  = ''
      , SortId      = 5
    UNION ALL
    SELECT
        Heading     = 'Applications'
      , SubHeading  = ''
      , Description = 'Manage application submissions and deadlines'
      , TypeId      = 6
      , Link1Text   = 'More'
      , Link1Route  = '/psrc/applications'
      , Link2Text   = ''
      , Link2Route  = ''
      , SortId      = 6;

    /*
    ============================================================================
    POPULATE PROJECT METRICS
    ============================================================================
    Key performance indicators for both TIP and RCP projects including
    active project counts, obligations, and financial programming totals.
    */
    INSERT
        INTO @project_information
            (Title, Link, Metric, TileTypeId, SortId)
    SELECT
        Title      = 'Active Projects'
      , Link       = '/projects?status=active'
      , Metric     = CAST(COUNT(*) AS NVARCHAR(10)) -- Current count of active TIP projects
      , TileTypeId = 1 -- TIP Projects tile
      , SortId     = 1
        FROM
            tip.Project AS p
            JOIN tip.CompletionStatusType AS status_type
                 ON status_type.Id = p.CompletionStatusTypeId
        WHERE
            status_type.Code IN ('Active')
    UNION ALL
    SELECT
        Title      = 'Upcoming Obligations'
      , Link       = ''
      , Metric     = '--' -- Projects with pending obligations
      , TileTypeId = 1
      , SortId     = 2
    UNION ALL
    SELECT
        Title      = 'Total Programming'
      , Link       = ''
      , Metric     = dbo.fn_FormatCurrency(SUM(funding.FundingAmount)) -- Total TIP programming amount
      , TileTypeId = 1
      , SortId     = 3
        FROM
            tip.Project AS p
            JOIN tip.CompletionStatusType AS status_type
                 ON status_type.Id = p.CompletionStatusTypeId
            JOIN tip.ProgrammedFunding AS funding
                 ON funding.ProjectId = p.Id AND funding.IsObligatedFlag = 1
        WHERE
            status_type.Code IN ('Active')
    UNION ALL
    SELECT
        Title      = 'Active Projects'
      , Link       = '/projects?status=active'
      , Metric     = 'Not Available' -- Current count of active RCP projects
      , TileTypeId = 3 -- RCP Projects tile
      , SortId     = 4
    UNION ALL
    SELECT
        Title      = 'Total Programming'
      , Link       = ''
      , Metric     = 'Not Available' -- Total RCP programming amount
      , TileTypeId = 3
      , SortId     = 5;

    /*
    ============================================================================
    POPULATE AMENDMENT TRACKING
    ============================================================================
    Active amendments for both TIP and RCP with status tracking.
    
    StatusId now contains the actual AmendmentStatusTypeId (GUID) for lookup matching
    */
    INSERT
        INTO @amendment_information
            (Title, DueDate, Metric, Metric2, StatusId, Link, TileTypeId, SortId)
    SELECT TOP (3)
        Title      = amendment.Name -- Amendment number
      , DueDate    = amendment.WsdotDueDate
      , Metric     = COUNT(*) -- Number of affected projects
      , Metric2    = SUM(CASE WHEN review_status.Code <> 'complete' THEN 1 ELSE 0 END) -- Count of unresolved projects
      , StatusId   = amendment.AmendmentStatusTypeId -- Use actual status type ID for lookup
      , Link       = '/psrc/tip/amendments/' + LOWER(CAST(amendment.Id AS NVARCHAR(36)))
      , TileTypeId = 2 -- TIP Amendments
      , SortId     = DENSE_RANK() OVER (ORDER BY amendment.WsdotDueDate DESC)
        FROM
            tip.Amendment AS amendment
            JOIN tip.AmendmentStatusType AS status_type
                 ON status_type.Id = amendment.AmendmentStatusTypeId
            JOIN tip.AmendmentMappedType AS mapped_type
                 ON mapped_type.Id = amendment.AmendmentMappedTypeId
            LEFT JOIN tip.ProjectAmendment AS project_amendment
                 ON project_amendment.AmendmentId = amendment.Id
            LEFT JOIN tip.ProjectAmendmentReviewStatusType AS review_status
                 ON review_status.Id = project_amendment.ProjectAmendmentReviewStatusTypeId
        WHERE
            1 = 1
        GROUP BY
            amendment.Id
          , amendment.AmendmentStatusTypeId
          , amendment.Name, amendment.WsdotDueDate
        ORDER BY DENSE_RANK() OVER (ORDER BY amendment.WsdotDueDate DESC);

    -- RCP Amendments (mirror structure for Regional Capital Program)
    INSERT @amendment_information
        (Title, DueDate, Metric, Metric2, StatusId, Link, TileTypeId, SortId)
    SELECT
        Title      = 'Not Available'
      , DueDate    = NULL
      , Metric     = 'Not Available'
      , Metric2    = 'Not Available'
      , StatusId   = '9129ba3c-3b0b-4236-a500-218f449bfdf1' -- Posted status (from seed data)
      , Link       = ''
      , TileTypeId = 4 -- RCP Amendments
      , SortId     = 4;


    /*
    ============================================================================
    POPULATE AVAILABLE REPORTS
    ============================================================================
    Standard reports available for download or viewing.
    */
    INSERT
        INTO @report_information
            (Text, Link, Route, TileTypeId, SortId)
    SELECT
        Text       = 'TIP Appendix A'
      , Link       = '' -- TODO: Add actual report link
      , Route      = ''
      , TileTypeId = 5 -- Reports tile
      , SortId     = 1
    UNION ALL
    SELECT
        Text       = 'TBP Memo and Exhibit'
      , Link       = '' -- TODO: Add actual report link
      , Route      = ''
      , TileTypeId = 5
      , SortId     = 2;

    /*
    ============================================================================
    POPULATE APPLICATION DEADLINES
    ============================================================================
    Upcoming application periods and submission deadlines.
    */
    INSERT
        INTO @application_information
            (Title, DueDate, Metric, Link, TileTypeId, SortId)
    SELECT
        Title      = 'TIP - DEC 24' -- December 2024 TIP application period
      , DueDate    = '01/01/2025'
      , Metric     = '34' -- Number of submissions
      , Link       = ''
      , TileTypeId = 6 -- Applications tile
      , SortId     = 1
    UNION ALL
    SELECT
        Title      = 'TIP - JAN 25' -- January 2025 TIP application period
      , DueDate    = '01/26/2025'
      , Metric     = '5'
      , Link       = ''
      , TileTypeId = 6
      , SortId     = 2
    UNION ALL
    SELECT
        Title      = 'Collection ABC' -- Generic collection period
      , DueDate    = '03/15/2025'
      , Metric     = '34'
      , Link       = ''
      , TileTypeId = 6
      , SortId     = 3;

    /*
    ============================================================================
    RETURN RESULT SETS
    ============================================================================
    Return all collected data as separate result sets for the dashboard.
    Each result set corresponds to a different section of the dashboard UI.
    */

    -- Result Set 1: Dashboard Tiles
    SELECT
        Heading     = t.Heading
      , SubHeading  = t.SubHeading
      , Description = t.Description
      , TypeId      = t.TypeId
      , Link1Text   = t.Link1Text
      , Link1Route  = t.Link1Route
      , Link2Text   = t.Link2Text
      , Link2Route  = t.Link2Route
      , SortId      = t.SortId
        FROM
            @tile_information AS t
        ORDER BY t.SortId;

    -- Result Set 2: Project Information
    SELECT
        Title      = p.Title
      , Link       = p.Link
      , Metric     = p.Metric
      , TileTypeId = p.TileTypeId
      , SortId     = p.SortId
        FROM
            @project_information AS p
        ORDER BY p.SortId;

    -- Result Set 3: Amendment Information
    SELECT
        Title      = a.Title
      , DueDate    = a.DueDate
      , Metric     = a.Metric
      , Metric2    = a.Metric2
      , StatusId   = a.StatusId
      , Link       = a.Link
      , TileTypeId = a.TileTypeId
      , SortId     = a.SortId
        FROM
            @amendment_information AS a
        ORDER BY a.TileTypeId, a.SortId;

    -- Result Set 4: Report Information
    SELECT
        Text       = r.Text
      , Link       = r.Link
      , Route      = r.Route
      , TileTypeId = r.TileTypeId
      , SortId     = r.SortId
        FROM
            @report_information AS r
        ORDER BY r.SortId;

    -- Result Set 5: Application Information
    SELECT
        Title      = a.Title
      , DueDate    = a.DueDate
      , Metric     = a.Metric
      , Link       = a.Link
      , TileTypeId = a.TileTypeId
      , SortId     = a.SortId
        FROM
            @application_information AS a
        ORDER BY a.SortId;

END;
GO
