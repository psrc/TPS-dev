SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
==================================================
Stored Procedure: dbo.pr_contact_get_by_agency_id
==================================================
Purpose: Retrieves all contact records associated with a specific agency.
         This procedure provides a complete list of contacts for an agency including audit fields.

Author: john.hunter@triskelle.solutions
Created: 2025-08-02

Modified: [Date] - [Reason for modification]

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID requesting the contact information (for audit trail)
    @AgencyId (UNIQUEIDENTIFIER) - Agency ID to retrieve contacts for

Returns: Multiple rows with complete contact information for all contacts in the agency,
         or no rows if no contacts exist for the agency

Example Usage:
    EXEC dbo.pr_contact_get_by_agency_id 
        @UserId = 'A1B2C3D4-E5F6-7890-A3CD-EF1234567890',
        @AgencyId = 'B2C3D4E5-F6A7-8901-B3DE-F23456789012'

Dependencies: 
    - Table: common.Contact

Business Rules:
    - Returns all contacts for the specified agency including inactive contacts
    - Returns complete contact records including all audit fields
    - Returns empty result set if no contacts exist for the agency
    - No security filtering applied - assumes authorization handled at application layer
==================================================
*/
-- Modified:    2026-09-12 - PSRC-mte.1 tenancy scoping (@TenantAgencyId/@BypassTenancy)
CREATE PROCEDURE [dbo].[pr_contact_get_by_agency_id]
(
    @UserId   UNIQUEIDENTIFIER -- User requesting contact information
  , @AgencyId UNIQUEIDENTIFIER -- Agency ID to retrieve contacts for
  , @TenantAgencyId UNIQUEIDENTIFIER = NULL -- PSRC-mte.1: caller's agency (NULL = none)
  , @BypassTenancy  BIT              = 0    -- PSRC-mte.1: 1 = internal caller, no scoping
)
AS
    BEGIN
        SET NOCOUNT ON;
        -- PSRC-mte.1: a scoped caller may only name their own agency.
        IF @BypassTenancy = 0 AND (@TenantAgencyId IS NULL OR @AgencyId IS NULL OR @AgencyId <> @TenantAgencyId)
            THROW 50403, 'Tenancy: agency is not the caller''s agency.', 1;
        -- Prevent extra result sets from interfering with SELECT statements

        -- Retrieve all contacts associated with the specified agency
        SELECT
            Id
          , FirstName
          , LastName
          , Email
          , Phone
          , PhoneExt
          , AgencyId
          , IsActive
          , Notes
          , CreatedById
          , CreatedOn
          , UpdatedById
          , UpdatedOn
        FROM
            common.Contact
        WHERE
            AgencyId = @AgencyId
		ORDER BY
			FirstName, LastName;
    END;


GO
