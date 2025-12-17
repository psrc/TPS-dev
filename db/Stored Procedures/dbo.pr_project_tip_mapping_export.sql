SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
/*
==================================================
Stored Procedure: dbo.pr_project_tip_mapping_export
==================================================
Purpose: Retrieves ALL projects mapped to a specific TIP for CSV export.
         Returns all columns needed for the export file without pagination.

Author: john.hunter@triskelle.solutions
Created: 2025-12-11

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID requesting the data (for audit/authorization)
    @TipId (UNIQUEIDENTIFIER) - TIP ID to get mapped projects for

Returns: Single result set with all projects for the TIP:
    - ProjectCode, Title, AgencyName, ContactName, ContactEmail, Status

Dependencies:
    - Tables: tip.ProjectTipMapping, tip.Project, common.Agency, common.Contact, tip.CompletionStatusType

Business Rules:
    - Returns ALL projects mapped to the TIP (no pagination)
    - Sorted by ProjectCode ASC for consistent export ordering
    - ContactName is formatted as "FirstName LastName"
    - Used for CSV export functionality
==================================================
*/
CREATE PROCEDURE [dbo].[pr_project_tip_mapping_export]
(
    @UserId UNIQUEIDENTIFIER -- User making the request
  , @TipId  UNIQUEIDENTIFIER -- TIP to export projects for
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ProjectCode  = proj.ProjectCode
      , Title        = ISNULL(proj.Title, '')
      , AgencyName   = ISNULL(agency.Name, '')
      , ContactName  = RTRIM(LTRIM(ISNULL(contact.FirstName, '') + ' ' + ISNULL(contact.LastName, '')))
      , ContactEmail = ISNULL(contact.Email, '')
      , Status       = ISNULL(status.Description, '')
    FROM
        tip.ProjectTipMapping              AS mapping
        INNER JOIN tip.Project             AS proj
                   ON proj.Id              = mapping.ProjectId
        LEFT JOIN common.Agency            AS agency
                  ON agency.Id             = proj.AgencyId
        LEFT JOIN common.Contact           AS contact
                  ON contact.Id            = proj.ContactId
        LEFT JOIN tip.CompletionStatusType AS status
                  ON status.Id             = proj.CompletionStatusTypeId
    WHERE
        mapping.TipId = @TipId
    ORDER BY
        proj.ProjectCode ASC;
END;
GO
