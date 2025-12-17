SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
/*
==================================================
Stored Procedure: dbo.pr_project_tip_mapping_add
==================================================
Purpose: Adds one or more projects to a TIP by creating ProjectTipMapping records.
         Skips projects that are already mapped to the TIP.
         Creates audit log entries in ProjectTipLog for each successfully added project.

Author: john.hunter@triskelle.solutions
Created: 2025-12-11

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID performing the operation (for audit trail)
    @TipId (UNIQUEIDENTIFIER) - TIP ID to add projects to
    @ProjectIds (UniqueIdentifierArrayType) - List of project IDs to add to the TIP

Returns: Single row with count of projects successfully added

Dependencies:
    - Tables: tip.ProjectTipMapping, tip.ProjectTipLog, tip.ProjectTipLogType, tip.Project
    - User-defined types: UniqueIdentifierArrayType

Business Rules:
    - Skips projects already mapped to the TIP (using NOT EXISTS check)
    - Creates a ProjectTipLog entry for each newly added project
    - Uses PROJECT_ADDED log type for audit entries
    - Wrapped in transaction for atomic operation
    - Returns 0 if all projects were already mapped
==================================================
*/
CREATE PROCEDURE [dbo].[pr_project_tip_mapping_add]
(
    @UserId     UNIQUEIDENTIFIER                   -- User performing the operation
  , @TipId      UNIQUEIDENTIFIER                   -- TIP to add projects to
  , @ProjectIds UniqueIdentifierArrayType READONLY -- Projects to add
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @AddedCount INT = 0;
    DECLARE @LogTypeId UNIQUEIDENTIFIER;

    -- Get the PROJECT_ADDED log type ID
    SELECT @LogTypeId = Id
    FROM tip.ProjectTipLogType
    WHERE Code = 'PROJECT_ADDED';

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Create temp table to store new mappings
        DECLARE @NewMappings TABLE
        (
            MappingId UNIQUEIDENTIFIER NOT NULL
          , ProjectId UNIQUEIDENTIFIER NOT NULL
        );

        -- Insert new mappings for projects not already in the TIP
        INSERT INTO tip.ProjectTipMapping
            (Id, ProjectId, TipId, CreatedById, CreatedOn)
        OUTPUT
            INSERTED.Id
          , INSERTED.ProjectId
        INTO @NewMappings (MappingId, ProjectId)
        SELECT
            NEWID()
          , p.Value
          , @TipId
          , @UserId
          , GETUTCDATE()
        FROM
            @ProjectIds AS p
        WHERE
            p.Value IS NOT NULL
            AND NOT EXISTS (
                SELECT 1
                FROM tip.ProjectTipMapping m
                WHERE m.ProjectId = p.Value
                  AND m.TipId = @TipId
            );

        -- Get count of added mappings
        SET @AddedCount = @@ROWCOUNT;

        -- Create log entries for each added project
        INSERT INTO tip.ProjectTipLog
            (Id, ProjectTipMappingId, ProjectTipLogTypeId, ProjectId, TipId, Description, CreatedById, CreatedOn)
        SELECT
            NEWID()
          , nm.MappingId
          , @LogTypeId
          , nm.ProjectId
          , @TipId
          , 'Project added to TIP'
          , @UserId
          , GETUTCDATE()
        FROM
            @NewMappings AS nm;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    -- Return count of projects added
    SELECT AddedCount = @AddedCount;
END;
GO
