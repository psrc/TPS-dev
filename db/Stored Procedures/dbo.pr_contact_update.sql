SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
/*
==================================================
Stored Procedure: dbo.pr_contact_update
==================================================
Purpose: Updates an existing contact record with new information and returns the updated contact.
         This procedure handles transactional updates with proper error handling and audit trail.

Author: [Author Name]
Created: [Date]
Modified: [Date] - [Reason for modification]

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID performing the update (for audit trail)
    @Id (UNIQUEIDENTIFIER) - Contact ID to update
    @AgencyId (UNIQUEIDENTIFIER) - Agency ID to associate the contact with
    @FirstName (NVARCHAR(255)) - Contact's first name
    @LastName (NVARCHAR(255)) - Contact's last name
    @Email (NVARCHAR(255)) - Contact's email address (optional)
    @Phone (NVARCHAR(15)) - Contact's phone number (optional)
    @PhoneExt (NVARCHAR(50)) - Contact's phone extension (optional)
    @Notes (NVARCHAR(MAX)) - Additional notes about the contact (optional)

Returns: Single row with the updated contact's complete information

Example Usage:
    EXEC dbo.pr_contact_update 
        @UserId = 'A1B2C3D4-E5F6-7890-A3CD-EF1234567890',
        @Id = 'C3D4E5F6-A7B8-9012-C3EF-345678901234',
        @AgencyId = 'B2C3D4E5-F6A7-8901-B3DE-F23456789012',
        @FirstName = 'Jane',
        @LastName = 'Smith',
        @Email = 'jane.smith@example.com',
        @Phone = '555-987-6543',
        @PhoneExt = '456',
        @Notes = 'Updated contact information'

Dependencies: 
    - Table: common.Contact

Business Rules:
    - Updates all provided fields for the specified contact
    - Maintains audit trail with UpdatedById and UpdatedOn fields
    - Transaction is rolled back on any error
    - Notes field is NOT updated by this procedure (excluded from UPDATE statement)
    - Returns complete updated contact record including system-generated fields
==================================================
*/

CREATE PROCEDURE [dbo].[pr_contact_update]
(
    @UserId    UNIQUEIDENTIFIER -- User performing the update
,   @Id        UNIQUEIDENTIFIER -- Contact ID to update
,   @AgencyId  UNIQUEIDENTIFIER -- Agency to associate contact with
,   @FirstName NVARCHAR(255) -- Contact's first name
,   @LastName  NVARCHAR(255) -- Contact's last name
,   @Email     NVARCHAR(255) = NULL -- Contact's email (optional)
,   @Phone     NVARCHAR(15) = NULL -- Contact's phone number (optional)
,   @PhoneExt  NVARCHAR(50) = NULL -- Phone extension (optional)
,   @Notes     NVARCHAR(MAX) = NULL -- Additional notes (optional)
) AS
BEGIN
    SET NOCOUNT ON; -- Prevent extra result sets from interfering with SELECT statements
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Update the contact record with new information
        UPDATE common.Contact
        SET
            AgencyId    = @AgencyId
          , FirstName   = @FirstName
          , LastName    = @LastName
          , Email       = @Email
          , Phone       = @Phone
          , PhoneExt    = @PhoneExt
          , UpdatedById = @UserId
          , UpdatedOn   = GETUTCDATE()
            WHERE
                Id = @Id;

        -- Commit the transaction if update was successful
        COMMIT;

        -- Return the updated contact record with all fields
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
    END TRY BEGIN CATCH
        -- Rollback transaction on error
        ROLLBACK;

        -- Re-throw the original error to the calling application
        THROW;
    END CATCH;
END;
GO
