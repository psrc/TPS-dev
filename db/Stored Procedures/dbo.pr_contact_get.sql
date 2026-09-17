SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
==================================================
Stored Procedure: dbo.pr_contact_get
==================================================
Purpose: Retrieves a single contact record by its unique identifier.
         This procedure provides complete contact information including audit fields.

Author: [Author Name]
Created: [Date]
Modified: [Date] - [Reason for modification]

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID requesting the contact information (for audit trail)
    @ContactId (UNIQUEIDENTIFIER) - Unique identifier of the contact to retrieve

Returns: Single row with complete contact information, or no rows if contact not found

Example Usage:
    EXEC dbo.pr_contact_get 
        @UserId = 'A1B2C3D4-E5F6-7890-A3CD-EF1234567890',
        @ContactId = 'B2C3D4E5-F6A7-8901-3CDE-F23456789012'

Dependencies: 
    - Table: common.Contact

Business Rules:
    - Returns complete contact record including all audit fields
    - Returns empty result set if contact ID not found
    - No security filtering applied - assumes authorization handled at application layer
==================================================
*/
-- Modified:    2026-09-12 - PSRC-mte.1 tenancy scoping (@TenantAgencyId/@BypassTenancy)
CREATE PROCEDURE [dbo].[pr_contact_get]
(
    @UserId    UNIQUEIDENTIFIER -- User requesting contact information
,   @ContactId UNIQUEIDENTIFIER -- Contact ID to retrieve
,   @TenantAgencyId UNIQUEIDENTIFIER = NULL -- PSRC-mte.1: caller's agency (NULL = none)
,   @BypassTenancy  BIT              = 0    -- PSRC-mte.1: 1 = internal caller, no scoping
) AS
BEGIN
    SET NOCOUNT ON;
    -- PSRC-mte.1: a scoped caller may only touch a contact in their own agency.
    IF @BypassTenancy = 0 AND NOT EXISTS (SELECT 1 FROM common.Contact WHERE Id = @ContactId AND AgencyId = @TenantAgencyId)
        THROW 50403, 'Tenancy: contact is not in the caller''s agency.', 1;
    -- Prevent extra result sets from interfering with SELECT statements

    -- Retrieve complete contact information by unique identifier
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
            Id = @ContactId;
END;


GO
