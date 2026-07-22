SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
==================================================
Stored Procedure: dbo.pr_contact_create
==================================================
Purpose: Creates a new contact record in the system and returns the complete contact information.
         This procedure is used to add new contacts associated with agencies for project management.

Author: [Author Name]
Created: [Date]
Modified: [Date] - [Reason for modification]

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID of the person creating the contact (for audit trail)
    @AgencyId (UNIQUEIDENTIFIER) - Agency ID to associate the contact with (required)
    @FirstName (NVARCHAR(255)) - Contact's first name (required)
    @LastName (NVARCHAR(255)) - Contact's last name (required)
    @Email (NVARCHAR(255)) - Contact's email address (optional)
    @Phone (NVARCHAR(15)) - Contact's phone number (optional)
    @PhoneExt (NVARCHAR(50)) - Contact's phone extension (optional)
    @Notes (NVARCHAR(MAX)) - Additional notes about the contact (optional)

Returns: Single row with the newly created contact's complete information

Example Usage:
    EXEC dbo.pr_contact_create 
        @UserId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
        @AgencyId = 'B2C3D4E5-F6A7-8901-BCDE-F23456789012',
        @FirstName = 'John',
        @LastName = 'Doe',
        @Email = 'john.doe@example.com',
        @Phone = '555-123-4567',
        @PhoneExt = '123',
        @Notes = 'Primary contact for project coordination'

Dependencies: 
    - Table: common.Contact

Business Rules:
    - Each contact must be associated with an agency
    - Email and phone are optional but recommended
    - IsActive is defaulted to true in the table schema
    - CreatedOn timestamp uses UTC time
==================================================
*/

CREATE PROCEDURE [dbo].[pr_contact_create]
(
    @UserId    UNIQUEIDENTIFIER -- User performing the create operation
,   @AgencyId  UNIQUEIDENTIFIER -- Agency this contact belongs to
,   @FirstName NVARCHAR(255) -- Contact's first name
,   @LastName  NVARCHAR(255) -- Contact's last name
,   @Email     NVARCHAR(255) = NULL -- Contact's email (optional)
,   @Phone     NVARCHAR(15) = NULL -- Contact's phone number (optional)
,   @PhoneExt  NVARCHAR(50) = NULL -- Phone extension (optional)
,   @Notes     NVARCHAR(MAX) = NULL -- Additional notes (optional)
) AS
BEGIN
    SET NOCOUNT ON;
    -- Prevent extra result sets from interfering with SELECT statements

    -- Generate new unique identifier for the contact
    DECLARE @Id UNIQUEIDENTIFIER = NEWID();

    -- Insert the new contact record
    INSERT
        INTO
            common.Contact
            (Id, AgencyId, FirstName, LastName, Email, Phone, PhoneExt, Notes, CreatedById, CreatedOn)
        VALUES
            (@Id, @AgencyId, @FirstName, @LastName, @Email, @Phone, @PhoneExt, @Notes, @UserId, GETUTCDATE());

    -- Return the complete contact record including system-generated fields
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
            Id = @Id;
END;
GO
