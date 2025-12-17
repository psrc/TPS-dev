SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
/*
==================================================
Stored Procedure: dbo.pr_tip_project_dashboard_get
==================================================
Purpose: Retrieves dashboard card information for the TIP (Transportation Improvement Program)
         projects section. Returns basic information for all TIPS

Author: john.hunter@triskelle.solutions
Created: 2025-07-29

Modified: [Date] - [Reason for modification]

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID requesting the dashboard data (for audit trail)

Example Usage:
    EXEC dbo.pr_tip_project_dashboard_get 
        @UserId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'

==================================================
*/

CREATE PROCEDURE [dbo].[pr_tip_project_dashboard_get]
(
    @UserId UNIQUEIDENTIFIER -- User requesting dashboard data
)
AS
    BEGIN
        SET NOCOUNT ON;

        -- Return static dashboard card information for TIP projects
        SELECT
            Id             = tip.Id
          , Name           = tip.Description
          , BeginYear      = tip.BeginYear
          , EndYear        = tip.EndYear
          , ProjectCount   = COUNT(DISTINCT proj.Id)
          , AmendmentCount = COUNT(DISTINCT amendment.Id)
        FROM
            tip.Tip                         AS tip
            LEFT JOIN tip.ProjectTipMapping AS proj_tip
                      ON proj_tip.TipId                              = tip.Id
            LEFT JOIN tip.Project           AS proj
                      ON proj.Id                                     = proj_tip.ProjectId
            LEFT JOIN tip.ProjectAmendment  AS proj_amend
                      ON proj_amend.ProjectId                        = proj.Id
            LEFT JOIN tip.Amendment         AS amendment
                      ON amendment.Id                                = proj_amend.AmendmentId
                         AND amendment.IsAdministrativeAmendmentFlag = 0  
        WHERE
            1 = 1
        GROUP BY
            tip.Id
          , tip.Description
          , tip.BeginYear
          , tip.EndYear
        ORDER BY
            tip.EndYear DESC
          , tip.BeginYear DESC;
    END;


GO
