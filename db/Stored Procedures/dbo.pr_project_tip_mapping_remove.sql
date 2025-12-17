SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
/*
==================================================
Stored Procedure: dbo.pr_project_tip_mapping_remove
==================================================
Purpose: Removes one or more projects from a TIP by deleting ProjectTipMapping records.
         Creates audit log entries in ProjectTipLog BEFORE deleting the mappings.

Author: john.hunter@triskelle.solutions
Created: 2025-12-11

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID performing the operation (for audit trail)
    @TipId (UNIQUEIDENTIFIER) - TIP ID to remove projects from
    @ProjectIds (UniqueIdentifierArrayType) - List of project IDs to remove from the TIP

Returns: Single row with count of projects successfully removed

Dependencies:
    - Tables: tip.ProjectTipMapping, tip.ProjectTipLog, tip.ProjectTipLogType
    - User-defined types: UniqueIdentifierArrayType

Business Rules:
    - Creates a ProjectTipLog entry BEFORE deleting each mapping (to preserve history)
    - Uses PROJECT_REMOVED log type for audit entries
    - Wrapped in transaction for atomic operation
    - Returns 0 if no projects were found to remove
    - Log entries reference ProjectId and TipId directly since mapping will be deleted
==================================================
*/
CREATE PROCEDURE [dbo].[pr_project_tip_mapping_remove]
(
    @UserId     UNIQUEIDENTIFIER                   -- User performing the operation
  , @TipId      UNIQUEIDENTIFIER                   -- TIP to remove projects from
  , @ProjectIds UniqueIdentifierArrayType READONLY -- Projects to remove
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RemovedCount INT = 0;
    DECLARE @LogTypeId UNIQUEIDENTIFIER;

    -- Get the PROJECT_REMOVED log type ID
    SELECT @LogTypeId = Id
    FROM tip.ProjectTipLogType
    WHERE Code = 'PROJECT_REMOVED';

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Create temp table to store mappings to be removed
        DECLARE @MappingsToRemove TABLE
        (
            MappingId UNIQUEIDENTIFIER NOT NULL
          , ProjectId UNIQUEIDENTIFIER NOT NULL
        );

        -- Find mappings that will be removed
        INSERT INTO @MappingsToRemove (MappingId, ProjectId)
        SELECT
            m.Id
          , m.ProjectId
        FROM
            tip.ProjectTipMapping AS m
            INNER JOIN @ProjectIds AS p
                       ON p.Value = m.ProjectId
        WHERE
            m.TipId = @TipId;

        -- Create log entries BEFORE deleting (to preserve audit trail)
        INSERT INTO tip.ProjectTipLog
            (Id, ProjectTipMappingId, ProjectTipLogTypeId, ProjectId, TipId, Description, CreatedById, CreatedOn)
        SELECT
            NEWID()
          , NULL  -- Set to NULL since mapping will be deleted and FK is SET NULL on delete
          , @LogTypeId
          , r.ProjectId
          , @TipId
          , 'Project removed from TIP'
          , @UserId
          , GETUTCDATE()
        FROM
            @MappingsToRemove AS r;

        -- Delete the mappings
        DELETE FROM tip.ProjectTipMapping
        WHERE
            Id IN (SELECT MappingId FROM @MappingsToRemove);

        -- Get count of removed mappings
        SET @RemovedCount = @@ROWCOUNT;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    -- Return count of projects removed
    SELECT RemovedCount = @RemovedCount;
END;
GO
