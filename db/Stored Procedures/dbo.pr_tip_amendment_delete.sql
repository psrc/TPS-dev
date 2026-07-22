SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2026-05-11
-- Modified:    2026-05-13 - Replace 'void' (status flip) with hard delete of Amendment row
-- Description: Hard-deletes a non-posted TIP Amendment and all pending project
--              data attached to it, including the Amendment row itself.
--
-- Parameters:
--    @UserId       (UNIQUEIDENTIFIER) - User performing the delete (reserved for audit)
--    @AmendmentId  (UNIQUEIDENTIFIER) - Amendment ID to delete
--
-- Returns:
--    Success (BIT)              - 1 if deleted, 0 if validation failed
--    Errors  (NVARCHAR(MAX))    - JSON array of error messages, or NULL
--
-- Business Rules:
--    - Amendment must exist
--    - Amendment must NOT be in 'posted' status (already finalized — cannot delete)
--    - All ProjectAmendment, Project_Pending, and related _Pending rows for
--      the amendment are bulk-deleted (cascade)
--    - ProjectAmendmentLog and ProjectAmendmentReviewArea rows are also removed
--    - The Amendment row itself is deleted
--    - All work runs in a single transaction
--
-- Dependencies:
--    - Tables: tip.Amendment, tip.AmendmentStatusType, tip.ProjectAmendment,
--              tip.ProjectAmendmentLog, tip.ProjectAmendmentReviewArea,
--              tip.Project_Pending, tip.ProjectBudget_Pending,
--              tip.ProgrammedFunding_Pending, tip.ProjectCountyMapping_Pending,
--              tip.ProjectImprovementTypeMapping_Pending
-- =============================================
CREATE   PROCEDURE [dbo].[pr_tip_amendment_delete]
    @UserId      UNIQUEIDENTIFIER
, @AmendmentId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @AmendmentStatusCode NVARCHAR(50);

    IF NOT EXISTS (SELECT 1 FROM tip.Amendment WHERE Id = @AmendmentId)
        BEGIN
            SELECT Success = CAST(0 AS BIT), Errors = N'["Amendment not found."]';
            RETURN 0;
        END;

    -- Look up amendment current status
    SELECT @AmendmentStatusCode = ast.Code
        FROM
            tip.Amendment                      AS a
            LEFT  JOIN tip.AmendmentStatusType AS ast
                       ON ast.Id = a.AmendmentStatusTypeId
        WHERE
            a.Id = @AmendmentId;

    IF @AmendmentStatusCode = 'posted'
        BEGIN
            SELECT
                Success = CAST(0 AS BIT)
              , Errors  = N'["Amendment has been posted and cannot be deleted."]';
            RETURN 0;
        END;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- Snapshot the ProjectAmendment + Project_Pending ids tied to this amendment
        DECLARE @ProjectAmendmentIds TABLE
                                     (
                                         ProjectAmendmentId UNIQUEIDENTIFIER NOT NULL
                                     );
        DECLARE @ProjectPendingIds   TABLE
                                     (
                                         ProjectPendingId UNIQUEIDENTIFIER NOT NULL
                                     );

        INSERT INTO @ProjectAmendmentIds (ProjectAmendmentId)
        SELECT Id FROM tip.ProjectAmendment WHERE AmendmentId = @AmendmentId;

        INSERT INTO @ProjectPendingIds (ProjectPendingId)
        SELECT pp.Id
               FROM
                   tip.Project_Pending          AS pp
                   INNER JOIN @ProjectAmendmentIds AS pai
                              ON pai.ProjectAmendmentId = pp.ProjectAmendmentId;

        -- Cascade delete pending child rows (children first, then parents)

        -- 1. ProgrammedFunding_Pending
        DELETE
            pfp
            FROM
                tip.ProgrammedFunding_Pending AS pfp
                INNER JOIN @ProjectPendingIds AS ppi
                           ON ppi.ProjectPendingId = pfp.Project_PendingId
            WHERE
                1 = 1;

        -- 2. ProjectBudget_Pending
        DELETE
            pbp
            FROM
                tip.ProjectBudget_Pending     AS pbp
                INNER JOIN @ProjectPendingIds AS ppi
                           ON ppi.ProjectPendingId = pbp.Project_PendingId
            WHERE
                1 = 1;

        -- 3. ProjectCountyMapping_Pending (FK is ProjectId, references Project_Pending.Id)
        DELETE
            pcmp
            FROM
                tip.ProjectCountyMapping_Pending AS pcmp
                INNER JOIN @ProjectPendingIds    AS ppi
                           ON ppi.ProjectPendingId = pcmp.ProjectId
            WHERE
                1 = 1;

        -- 4. ProjectImprovementTypeMapping_Pending (FK is ProjectId, references Project_Pending.Id)
        DELETE
            pitmp
            FROM
                tip.ProjectImprovementTypeMapping_Pending AS pitmp
                INNER JOIN @ProjectPendingIds             AS ppi
                           ON ppi.ProjectPendingId = pitmp.ProjectId
            WHERE
                1 = 1;

        -- 5. Project_Pending
        DELETE
            pp
            FROM
                tip.Project_Pending           AS pp
                INNER JOIN @ProjectPendingIds AS ppi
                           ON ppi.ProjectPendingId = pp.Id
            WHERE
                1 = 1;

        -- 6. ProjectAmendmentReviewArea
        DELETE
            para
            FROM
                tip.ProjectAmendmentReviewArea  AS para
                INNER JOIN @ProjectAmendmentIds AS pai
                           ON pai.ProjectAmendmentId = para.ProjectAmendmentId
            WHERE
                1 = 1;

        -- 7. ProjectAmendmentLog
        DELETE
            pal
            FROM
                tip.ProjectAmendmentLog         AS pal
                INNER JOIN @ProjectAmendmentIds AS pai
                           ON pai.ProjectAmendmentId = pal.ProjectAmendmentId
            WHERE
                1 = 1;

        -- 8. ProjectAmendment
        DELETE FROM tip.ProjectAmendment WHERE AmendmentId = @AmendmentId;

        -- 9. Amendment (hard delete)
        DELETE FROM tip.Amendment WHERE Id = @AmendmentId;

        COMMIT TRANSACTION;

        SELECT Success = CAST(1 AS BIT), Errors = CAST(NULL AS NVARCHAR(MAX));
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
