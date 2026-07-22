SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2026-02-19
-- Description: Moves a project from one amendment to another by updating the
--              AmendmentId (and optionally AmendmentSectionTypeId) on the
--              existing ProjectAmendment record. All child records (budgets,
--              funding, mappings, review areas) reference ProjectAmendmentId
--              and are preserved automatically.
--
-- Parameters:
--    @UserId (UNIQUEIDENTIFIER)              - User ID performing the operation (for audit trail)
--    @SourceAmendmentId (UNIQUEIDENTIFIER)   - Current amendment the project belongs to
--    @ProjectPendingId (UNIQUEIDENTIFIER)    - Project_Pending ID to move
--    @TargetAmendmentId (UNIQUEIDENTIFIER)   - Amendment to move the project to
--    @AmendmentSectionTypeId (UNIQUEIDENTIFIER) - New section type for the target amendment
--
-- Returns: Success indicator (1 = success, 0 = failure) with message
--
-- Dependencies:
--    - Tables: tip.ProjectAmendment, tip.Project_Pending, tip.Amendment
--
-- Business Rules:
--    - Source amendment must not be posted
--    - Target amendment must exist and not be posted
--    - Project must not already exist in the target amendment
--    - Updates AmendmentId, AmendmentSectionTypeId, and audit fields
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_amendment_move]
(
    @UserId                UNIQUEIDENTIFIER
  , @SourceAmendmentId     UNIQUEIDENTIFIER
  , @ProjectPendingId      UNIQUEIDENTIFIER
  , @TargetAmendmentId     UNIQUEIDENTIFIER
  , @AmendmentSectionTypeId UNIQUEIDENTIFIER
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProjectAmendmentId UNIQUEIDENTIFIER;
    DECLARE @ProjectId UNIQUEIDENTIFIER;
    DECLARE @UpdatedCount INT = 0;

    -- Get the ProjectAmendment ID and ProjectId from Project_Pending
    SELECT @ProjectAmendmentId = pp.ProjectAmendmentId,
           @ProjectId = pa.ProjectId
    FROM tip.Project_Pending AS pp
    INNER JOIN tip.ProjectAmendment AS pa ON pa.Id = pp.ProjectAmendmentId
    WHERE pp.Id = @ProjectPendingId
      AND pa.AmendmentId = @SourceAmendmentId;

    -- If no Project_Pending found, return 0
    IF @ProjectAmendmentId IS NULL
    BEGIN
        SELECT Success = 0, Message = 'Project amendment not found in source amendment';
        RETURN 0;
    END;

    -- Validate source amendment is not posted
    IF EXISTS (
        SELECT 1 FROM tip.Amendment a
        INNER JOIN tip.AmendmentStatusType ast ON ast.Id = a.AmendmentStatusTypeId
        WHERE a.Id = @SourceAmendmentId AND ast.Code = 'posted'
    )
    BEGIN
        SELECT Success = 0, Message = 'Cannot move project from a posted amendment';
        RETURN 0;
    END;

    -- Validate target amendment exists and is not posted
    IF NOT EXISTS (SELECT 1 FROM tip.Amendment WHERE Id = @TargetAmendmentId)
    BEGIN
        SELECT Success = 0, Message = 'Target amendment does not exist';
        RETURN 0;
    END;

    IF EXISTS (
        SELECT 1 FROM tip.Amendment a
        INNER JOIN tip.AmendmentStatusType ast ON ast.Id = a.AmendmentStatusTypeId
        WHERE a.Id = @TargetAmendmentId AND ast.Code = 'posted'
    )
    BEGIN
        SELECT Success = 0, Message = 'Cannot move project to a posted amendment';
        RETURN 0;
    END;

    -- Validate project is not already in the target amendment
    IF EXISTS (
        SELECT 1 FROM tip.ProjectAmendment
        WHERE ProjectId = @ProjectId AND AmendmentId = @TargetAmendmentId
    )
    BEGIN
        SELECT Success = 0, Message = 'Project already exists in the target amendment';
        RETURN 0;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Update the ProjectAmendment record to point to the target amendment
        UPDATE tip.ProjectAmendment
        SET AmendmentId = @TargetAmendmentId,
            AmendmentSectionTypeId = @AmendmentSectionTypeId,
            UpdatedById = @UserId,
            UpdatedOn = GETUTCDATE()
        WHERE Id = @ProjectAmendmentId;

        SET @UpdatedCount = @@ROWCOUNT;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    -- Return success indicator
    SELECT
        Success = IIF(@UpdatedCount > 0, 1, 0)
      , Message = IIF(@UpdatedCount > 0, 'Project moved to target amendment successfully', 'No records updated');
END;
GO
