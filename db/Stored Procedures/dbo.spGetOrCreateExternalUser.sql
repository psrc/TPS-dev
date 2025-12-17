SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
/*
==================================================
Stored Procedure: dbo.spGetOrCreateExternalUser
==================================================
Purpose: Gets an existing user or creates a new user based on external authentication provider ID.
         This procedure handles Auth0 user synchronization by matching external IDs or email addresses
         and creating users when they don't exist in the system.

Author: [Author Name]
Created: [Date]
Modified: [Date] - [Reason for modification]

Parameters:
    @ExternalId (VARCHAR(32)) - External authentication provider user ID (Auth0)
    @Email (NVARCHAR(256)) - User's email address (optional, defaults to empty string)

Returns: Single row with user information including:
         - Id: Internal user ID
         - ExternalId: External authentication provider ID
         - CreatedOn: User creation timestamp
         - LastAccessedOn: Most recent access timestamp

Example Usage:
    EXEC dbo.spGetOrCreateExternalUser 
        @ExternalId = 'auth0|1234567890abcdef',
        @Email = 'user@example.com'

Dependencies: 
    - Table: common.User
    - Table: common.UserIdentity
    - Table: common.UserProfile

Business Rules:
    - First attempts to find user by ExternalId
    - If not found, attempts to find by email address
    - If found by email, adds new UserIdentity record
    - If not found at all, creates new User and UserIdentity records
    - Updates LastAccessedOn for existing users
    - Uses transactions to ensure data consistency
    - Provider is hardcoded to 'AUTH0'
    - Uses row-level locking (UPDLOCK, HOLDLOCK) to prevent concurrency issues
==================================================
*/

CREATE PROCEDURE [dbo].[spGetOrCreateExternalUser]
(
    @ExternalId VARCHAR(32) -- External authentication provider user ID
,   @Email      NVARCHAR(256) = '' -- User's email address (optional)
) AS
BEGIN
    SET NOCOUNT ON; -- Prevent extra result sets from interfering with SELECT statements

    BEGIN TRANSACTION;

    -- =============================================
    -- SECTION 1: VARIABLE DECLARATIONS
    -- =============================================
    -- Declare variables for the result
    DECLARE @Id UNIQUEIDENTIFIER;
    DECLARE @UserIdentityId UNIQUEIDENTIFIER = NEWID();
    DECLARE @CreatedOn DATETIME2;
    DECLARE @LastAccessedOn DATETIME2;

    BEGIN TRY
        -- =============================================
        -- SECTION 2: ATTEMPT TO FIND USER BY EXTERNAL ID
        -- =============================================
        -- Attempt to find the user using external authentication ID
        -- Uses locking hints to prevent concurrency issues
        SELECT
            @Id = u.Id
          , @CreatedOn = u.CreatedOn
          , @LastAccessedOn = u.LastAccessedOn
            FROM
                common.[User] AS u WITH (UPDLOCK, HOLDLOCK)
                JOIN common.UserIdentity AS ui
                     ON u.Id = ui.UserId
            WHERE
                ui.ExternalId = @ExternalId;

        -- =============================================
        -- SECTION 3: HANDLE USER NOT FOUND BY EXTERNAL ID
        -- =============================================
        -- Check if the user was found
        IF @Id IS NULL
            BEGIN
                -- Try to find user by email address if external ID not found
                IF (SELECT COUNT(1) FROM common.UserProfile WHERE LOWER(Email) = LOWER(@Email)) > 0
                    BEGIN
                        -- User found by email - link external ID to existing user
                        SELECT TOP 1
                            @Id = u.Id
                            FROM
                                common.[User] AS u WITH (UPDLOCK, HOLDLOCK)
                                JOIN common.UserProfile AS up
                                     ON u.Id = up.UserId
                            WHERE
                                LOWER(up.Email) = LOWER(@Email);

                        -- Create new UserIdentity record to link external ID
                        INSERT
                            INTO
                                common.UserIdentity
                                (UserId, ExternalId, Provider, CreatedOn)
                            VALUES
                                (@Id, @ExternalId, 'AUTH0', GETUTCDATE());
                    END;
                ELSE
                    BEGIN
                        -- User not found by email or external ID - create new user
                        SET @Id = NEWID();

                        -- Create new User record
                        INSERT
                            INTO
                                common.[User]
                                (Id, CreatedOn, LastAccessedOn)
                            VALUES
                                (@Id, GETUTCDATE(), GETUTCDATE());

                        -- Create new UserIdentity record
                        INSERT
                            INTO
                                common.UserIdentity
                                (Id, UserId, ExternalId, Provider, CreatedOn)
                            VALUES
                                (@UserIdentityId, @Id, @ExternalId, 'AUTH0', GETUTCDATE());
                    END;

                -- Set timestamps for new user
                SELECT @CreatedOn = GETUTCDATE(), @LastAccessedOn = NULL;
            END;
        ELSE
            BEGIN
                -- =============================================
                -- SECTION 4: HANDLE EXISTING USER
                -- =============================================
                -- User found - update last accessed time
                SET @LastAccessedOn = GETUTCDATE();

                UPDATE common.[User] SET LastAccessedOn = @LastAccessedOn WHERE Id = @Id;

                -- Ensure UserIdentity record exists for this external ID
                IF (SELECT COUNT(1) FROM common.UserIdentity WHERE UserId = @Id AND ExternalId = @ExternalId) = 0
                    BEGIN
                        -- Create missing UserIdentity record
                        INSERT
                            INTO
                                common.UserIdentity
                                (Id, UserId, ExternalId, Provider, CreatedOn)
                            VALUES
                                (@UserIdentityId, @Id, @ExternalId, 'AUTH0', GETUTCDATE());
                    END;
            END;

        -- =============================================
        -- SECTION 5: RETURN RESULT
        -- =============================================
        -- Return user information
        SELECT Id = @Id, ExternalId = @ExternalId, CreatedOn = @CreatedOn, LastAccessedOn = @LastAccessedOn;

        -- Commit transaction if all operations succeeded
        COMMIT TRANSACTION;
    END TRY BEGIN CATCH
        -- =============================================
        -- SECTION 6: ERROR HANDLING
        -- =============================================
        -- Rollback transaction on any error
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        -- Re-throw the original error to the calling application
        THROW;
    END CATCH;
END;
GO
