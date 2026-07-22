SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2025-12-18
-- Description: Retrieves all review area records for a project amendment
--              including type descriptions, status descriptions, and reviewer information.
--              Also returns the read-only status based on amendment status.
--
--              IMPORTANT: This procedure also performs maintenance on review areas:
--              1. Adds missing review areas for area types that were effective
--                 at the time the amendment was created.
--              2. Removes review areas for area types that had an end date
--                 before the amendment was created.
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_amendment_review_areas_get]
    @UserId      UNIQUEIDENTIFIER
  , @AmendmentId UNIQUEIDENTIFIER
  , @ProjectId   UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Variable to hold ProjectAmendment.Id for related queries
    DECLARE @ProjectAmendmentId UNIQUEIDENTIFIER;
    DECLARE @IsReadOnly BIT;
    DECLARE @AmendmentCreatedOn DATETIME2(7);
    DECLARE @UnreviewedStatusId UNIQUEIDENTIFIER;

    -- Get the ProjectAmendment.Id for this amendment/project combination
    SELECT @ProjectAmendmentId = pa.Id
    FROM tip.ProjectAmendment AS pa
    WHERE pa.AmendmentId = @AmendmentId
      AND pa.ProjectId = @ProjectId;

    -- If no project amendment found, return empty result
    IF @ProjectAmendmentId IS NULL
    BEGIN
        SELECT
            Id                                     = CAST(NULL AS UNIQUEIDENTIFIER)
          , ProjectAmendmentId                     = CAST(NULL AS UNIQUEIDENTIFIER)
          , ProjectAmendmentReviewAreaTypeId       = CAST(NULL AS UNIQUEIDENTIFIER)
          , ProjectAmendmentReviewAreaStatusTypeId = CAST(NULL AS UNIQUEIDENTIFIER)
          , ReviewerComments                       = CAST(NULL AS NVARCHAR(MAX))
          , FollowUpComments                       = CAST(NULL AS NVARCHAR(MAX))
          , CreatedById                            = CAST(NULL AS UNIQUEIDENTIFIER)
          , CreatedOn                              = CAST(NULL AS DATETIME2(7))
          , UpdatedById                            = CAST(NULL AS UNIQUEIDENTIFIER)
          , UpdatedOn                              = CAST(NULL AS DATETIME2(7))
          , UpdatedByName                          = CAST(NULL AS NVARCHAR(256))
          , AreaTypeCode                           = CAST(NULL AS NVARCHAR(100))
          , AreaTypeDescription                    = CAST(NULL AS NVARCHAR(MAX))
          , AreaTypeSortId                         = CAST(NULL AS INT)
          , StatusTypeCode                         = CAST(NULL AS NVARCHAR(100))
          , StatusTypeDescription                  = CAST(NULL AS NVARCHAR(MAX))
          , IsReadOnly                             = CAST(0 AS BIT)
        WHERE 1 = 0; -- Return empty result set with schema
        RETURN;
    END;

    -- Get the amendment's created date and read-only status
    SELECT
        @AmendmentCreatedOn = a.CreatedOn
      , @IsReadOnly = CASE WHEN ast.Code = 'posted' THEN 1 ELSE 0 END
    FROM tip.Amendment AS a
    INNER JOIN tip.AmendmentStatusType AS ast ON ast.Id = a.AmendmentStatusTypeId
    WHERE a.Id = @AmendmentId;

    -- Get the "unreviewed" status type ID for new records
    SELECT @UnreviewedStatusId = Id
    FROM tip.ProjectAmendmentReviewAreaStatusType
    WHERE Code = 'unreviewed';

    -- =============================================
    -- STEP 1: Remove review areas for area types that ended before the amendment was created
    -- Business Rule: If an area type's EndDate is before the amendment's CreatedOn date,
    --                that review area should not exist for this project amendment.
    -- =============================================
    DELETE para
    FROM tip.ProjectAmendmentReviewArea AS para
    INNER JOIN tip.ProjectAmendmentReviewAreaType AS parat
            ON parat.Id = para.ProjectAmendmentReviewAreaTypeId
    WHERE para.ProjectAmendmentId = @ProjectAmendmentId
      AND parat.EndDate IS NOT NULL
      AND parat.EndDate < CAST(@AmendmentCreatedOn AS DATE);

    -- =============================================
    -- STEP 2: Add missing review areas for area types that were effective when amendment was created
    -- Business Rule: If an area type's EffectiveDate is on or before the amendment's CreatedOn date,
    --                and the area type was still active (no EndDate or EndDate >= amendment CreatedOn),
    --                then a review area record should exist.
    -- =============================================
    INSERT INTO tip.ProjectAmendmentReviewArea (
        Id
      , ProjectAmendmentId
      , ProjectAmendmentReviewAreaTypeId
      , ProjectAmendmentReviewAreaStatusTypeId
      , ReviewerComments
      , FollowUpComments
      , CreatedById
      , CreatedOn
    )
    SELECT
        NEWID()
      , @ProjectAmendmentId
      , parat.Id
      , @UnreviewedStatusId
      , NULL
      , NULL
      , @UserId
      , GETUTCDATE()
    FROM tip.ProjectAmendmentReviewAreaType AS parat
    WHERE parat.EffectiveDate <= CAST(@AmendmentCreatedOn AS DATE)
      AND (parat.EndDate IS NULL OR parat.EndDate >= CAST(@AmendmentCreatedOn AS DATE))
      AND NOT EXISTS (
          SELECT 1
          FROM tip.ProjectAmendmentReviewArea AS existing
          WHERE existing.ProjectAmendmentId = @ProjectAmendmentId
            AND existing.ProjectAmendmentReviewAreaTypeId = parat.Id
      );

    -- =============================================
    -- Return all review area records with joined data
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
      , IsReadOnly                             = @IsReadOnly
    FROM
        tip.ProjectAmendmentReviewArea AS para
        INNER JOIN tip.ProjectAmendmentReviewAreaType AS parat
                ON parat.Id = para.ProjectAmendmentReviewAreaTypeId
        INNER JOIN tip.ProjectAmendmentReviewAreaStatusType AS parast
                ON parast.Id = para.ProjectAmendmentReviewAreaStatusTypeId
        LEFT JOIN common.Users AS u
               ON u.Id = para.UpdatedById
    WHERE
        para.ProjectAmendmentId = @ProjectAmendmentId
    ORDER BY
        parat.SortId ASC;
END;
GO
