SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2025-12-18
-- Description: Updates a review area record for a project amendment.
--              Validates that the amendment is not posted before allowing updates.
--              Sets audit fields, auto-calculates the overall review status,
--              and returns the updated record with joined data.
--
-- Modified:
--   2026-02-19  Auto-calculate ProjectAmendment.ProjectAmendmentReviewStatusTypeId
--               after each review area update. Logic: all OK → complete,
--               any issue → issues, otherwise → incomplete.
-- =============================================
CREATE   PROCEDURE [dbo].[pr_tip_project_amendment_review_area_update]
    @UserId            UNIQUEIDENTIFIER -- User performing the update (for audit trail)
  , @AmendmentId       UNIQUEIDENTIFIER -- Amendment containing the project
  , @ProjectAmendmentId UNIQUEIDENTIFIER -- ProjectAmendment record ID
  , @ReviewAreaId      UNIQUEIDENTIFIER -- Review area record to update
  , @StatusTypeId      UNIQUEIDENTIFIER -- New status type for the review area
  , @ReviewerComments  NVARCHAR(MAX) = NULL -- Reviewer's comments (HTML content)
  , @FollowUpComments  NVARCHAR(MAX) = NULL -- Follow-up comments (HTML content)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- =============================================
    -- VALIDATE AMENDMENT STATUS
    -- =============================================
    -- Check that the amendment is not posted (posted amendments are read-only)
    DECLARE @AmendmentStatusCode NVARCHAR(100);

    SELECT @AmendmentStatusCode = ast.Code
    FROM tip.Amendment AS a
    INNER JOIN tip.AmendmentStatusType AS ast ON ast.Id = a.AmendmentStatusTypeId
    WHERE a.Id = @AmendmentId;

    IF @AmendmentStatusCode = 'posted'
    BEGIN
        RAISERROR('Cannot update review area for a posted amendment.', 16, 1);
        RETURN 0;
    END;

    -- =============================================
    -- VALIDATE REVIEW AREA BELONGS TO PROJECT AMENDMENT
    -- =============================================
    IF NOT EXISTS (
        SELECT 1
        FROM tip.ProjectAmendmentReviewArea AS para
        WHERE para.Id = @ReviewAreaId
          AND para.ProjectAmendmentId = @ProjectAmendmentId
    )
    BEGIN
        RAISERROR('Review area does not belong to the specified project amendment.', 16, 1);
        RETURN 0;
    END;

    BEGIN TRANSACTION;

    BEGIN TRY
        -- =============================================
        -- UPDATE REVIEW AREA RECORD
        -- =============================================
        UPDATE tip.ProjectAmendmentReviewArea
        SET
            ProjectAmendmentReviewAreaStatusTypeId = @StatusTypeId
          , ReviewerComments                       = @ReviewerComments
          , FollowUpComments                       = @FollowUpComments
          , UpdatedById                            = @UserId
          , UpdatedOn                              = GETUTCDATE()
        WHERE
            Id = @ReviewAreaId;

        -- =============================================
        -- AUTO-CALCULATE OVERALL REVIEW STATUS
        -- =============================================
        -- Logic: any 'issue' → issues, all 'ok' → complete, otherwise → incomplete
        DECLARE @IssueStatusId UNIQUEIDENTIFIER;
        DECLARE @OkStatusId UNIQUEIDENTIFIER;
        DECLARE @NewOverallStatusId UNIQUEIDENTIFIER;

        SELECT @IssueStatusId = Id FROM tip.ProjectAmendmentReviewAreaStatusType WHERE Code = 'issue';
        SELECT @OkStatusId    = Id FROM tip.ProjectAmendmentReviewAreaStatusType WHERE Code = 'ok';

        IF EXISTS (
            SELECT 1
            FROM tip.ProjectAmendmentReviewArea
            WHERE ProjectAmendmentId = @ProjectAmendmentId
              AND ProjectAmendmentReviewAreaStatusTypeId = @IssueStatusId
        )
        BEGIN
            -- At least one area has an issue
            SELECT @NewOverallStatusId = Id FROM tip.ProjectAmendmentReviewStatusType WHERE Code = 'issues';
        END
        ELSE IF NOT EXISTS (
            SELECT 1
            FROM tip.ProjectAmendmentReviewArea
            WHERE ProjectAmendmentId = @ProjectAmendmentId
              AND ProjectAmendmentReviewAreaStatusTypeId <> @OkStatusId
        )
        BEGIN
            -- All areas are OK
            SELECT @NewOverallStatusId = Id FROM tip.ProjectAmendmentReviewStatusType WHERE Code = 'complete';
        END
        ELSE
        BEGIN
            -- Mixed statuses (pending, unreviewed, etc.)
            SELECT @NewOverallStatusId = Id FROM tip.ProjectAmendmentReviewStatusType WHERE Code = 'incomplete';
        END;

        UPDATE tip.ProjectAmendment
        SET
            ProjectAmendmentReviewStatusTypeId = @NewOverallStatusId
          , UpdatedById                        = @UserId
          , UpdatedOn                          = GETUTCDATE()
        WHERE
            Id = @ProjectAmendmentId;

        COMMIT TRANSACTION;

        -- =============================================
        -- RETURN UPDATED RECORD WITH JOINED DATA
        -- =============================================
        SELECT
            Id                                     = para.Id
          , ProjectAmendmentId                     = para.ProjectAmendmentId
          , ProjectAmendmentReviewAreaTypeId       = para.ProjectAmendmentReviewAreaTypeId
          , ProjectAmendmentReviewAreaStatusTypeId = para.ProjectAmendmentReviewAreaStatusTypeId
          , ReviewerComments                       = para.ReviewerComments
          , FollowUpComments                       = para.FollowUpComments
          , CreatedById                            = para.CreatedById
          , CreatedOn                              = para.CreatedOn
          , UpdatedById                            = para.UpdatedById
          , UpdatedOn                              = para.UpdatedOn
          , UpdatedByName                          = u.UserName
          , AreaTypeCode                           = parat.Code
          , AreaTypeDescription                    = parat.Description
          , AreaTypeSortId                         = parat.SortId
          , StatusTypeCode                         = parast.Code
          , StatusTypeDescription                  = parast.Description
          , IsReadOnly                             = CAST(0 AS BIT) -- Not read-only since we just updated
          , OverallReviewStatusTypeId              = pa.ProjectAmendmentReviewStatusTypeId
        FROM
            tip.ProjectAmendmentReviewArea AS para
            INNER JOIN tip.ProjectAmendmentReviewAreaType AS parat
                    ON parat.Id = para.ProjectAmendmentReviewAreaTypeId
            INNER JOIN tip.ProjectAmendmentReviewAreaStatusType AS parast
                    ON parast.Id = para.ProjectAmendmentReviewAreaStatusTypeId
            INNER JOIN tip.ProjectAmendment AS pa
                    ON pa.Id = para.ProjectAmendmentId
            LEFT JOIN common.Users AS u
                   ON u.Id = para.UpdatedById
        WHERE
            para.Id = @ReviewAreaId;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
