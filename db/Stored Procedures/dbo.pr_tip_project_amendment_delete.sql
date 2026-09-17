SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2025-12-17
-- Modified:    2025-12-23 - Changed to lookup by Project_Pending.Id directly
-- Modified:    2026-09-12 - PSRC-mte.1 tenancy scoping (@TenantAgencyId/@BypassTenancy)
-- Description: Deletes a project from an amendment with cascade delete of all pending data.
--              Removes all related pending records (funding, budget, mappings) before
--              deleting the Project_Pending and ProjectAmendment records.
--
-- Parameters:
--    @UserId (UNIQUEIDENTIFIER) - User ID performing the operation (for audit trail)
--    @AmendmentId (UNIQUEIDENTIFIER) - Amendment ID to remove the project from
--    @ProjectPendingId (UNIQUEIDENTIFIER) - Project_Pending ID to remove from the amendment
--
-- Returns: Success indicator (1 = success, 0 = not found)
--
-- Dependencies:
--    - Tables: tip.ProjectAmendment, tip.Project_Pending, tip.ProjectBudget_Pending,
--              tip.ProgrammedFunding_Pending, tip.ProjectCountyMapping_Pending,
--              tip.ProjectImprovementTypeMapping_Pending
--
-- Business Rules:
--    - Deletes all pending child records before parent records (FK constraints)
--    - Wrapped in transaction for atomic operation
--    - Returns 0 if project amendment not found
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_amendment_delete]
(
    @UserId           UNIQUEIDENTIFIER
  , @AmendmentId      UNIQUEIDENTIFIER
  , @ProjectPendingId UNIQUEIDENTIFIER
  , @TenantAgencyId    UNIQUEIDENTIFIER = NULL -- PSRC-mte.1: caller's agency (NULL = none)
  , @BypassTenancy     BIT              = 0    -- PSRC-mte.1: 1 = internal caller, no scoping
)
AS
BEGIN
    SET NOCOUNT ON;

    -- PSRC-mte.1: a scoped caller may only touch a pending project in their own agency.
    IF @BypassTenancy = 0 AND NOT EXISTS (SELECT 1 FROM tip.Project_Pending WHERE Id = @ProjectPendingId AND AgencyId = @TenantAgencyId)
        THROW 50403, 'Tenancy: pending project is not in the caller''s agency.', 1;

    DECLARE @ProjectAmendmentId UNIQUEIDENTIFIER;
    DECLARE @DeletedCount INT = 0;

    -- Get the ProjectAmendment ID from Project_Pending
    SELECT @ProjectAmendmentId = pp.ProjectAmendmentId
    FROM tip.Project_Pending AS pp
    INNER JOIN tip.ProjectAmendment AS pa ON pa.Id = pp.ProjectAmendmentId
    WHERE pp.Id = @ProjectPendingId
      AND pa.AmendmentId = @AmendmentId;

    -- If no Project_Pending found, return 0
    IF @ProjectAmendmentId IS NULL
    BEGIN
        SELECT Success = 0, Message = 'Project amendment not found';
        RETURN;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- =============================================
        -- CASCADE DELETE PENDING DATA
        -- =============================================
        -- Delete in order: children first, then parent records

        -- 1. Delete programmed funding records
        DELETE FROM tip.ProgrammedFunding_Pending
        WHERE Project_PendingId = @ProjectPendingId;

        -- 2. Delete budget records
        DELETE FROM tip.ProjectBudget_Pending
        WHERE Project_PendingId = @ProjectPendingId;

        -- 3. Delete county mapping records
        DELETE FROM tip.ProjectCountyMapping_Pending
        WHERE ProjectId = @ProjectPendingId;

        -- 4. Delete improvement type mapping records
        DELETE FROM tip.ProjectImprovementTypeMapping_Pending
        WHERE ProjectId = @ProjectPendingId;

        -- 5. Delete the Project_Pending record
        DELETE FROM tip.Project_Pending
        WHERE Id = @ProjectPendingId;

        -- 6. Delete the Review Area records
        DELETE tip.ProjectAmendmentReviewArea
        WHERE ProjectAmendmentId = @ProjectAmendmentId;

        -- =============================================
        -- DELETE PROJECT AMENDMENT
        -- =============================================
        -- 7. Delete the ProjectAmendment record
        DELETE FROM tip.ProjectAmendment
        WHERE Id = @ProjectAmendmentId;

        SET @DeletedCount = @@ROWCOUNT;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    -- Return success indicator
    SELECT
        Success = CASE WHEN @DeletedCount > 0 THEN 1 ELSE 0 END
      , Message = CASE WHEN @DeletedCount > 0 THEN 'Project amendment deleted successfully' ELSE 'No records deleted' END;
END;


GO
