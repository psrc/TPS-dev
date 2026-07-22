SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*************************************************************************************************
-- =============================================
-- Author:        john.hunter@triskelle.solutions
-- Create date:   2025-07-23
-- Modified:      2026-05-11 - Exclude voided amendments from all dashboard filter views
-- Modified:      2026-05-13 - Drop 'voided' filter (amendments are now hard-deleted instead of voided)
-- Description:   Retrieves TIP amendment dashboard data with project count aggregations
-- =============================================
-- Business Context:
--   Powers the TIP Amendment Dashboard displaying amendment processing status.
--
-- Filter Logic:
--   1 = Open Amendments (non-administrative, not posted or unmapped)
--   2 = All Regular Amendments (non-administrative)
--   3 = All Administrative Amendments
--
-- Returns:
--   Result Set 1: Amendment details with aggregated counts
--   Result Set 2: Project status distribution by amendment
-- =============================================
*************************************************************************************************/
CREATE PROCEDURE [dbo].[pr_tip_amendment_dashboard_get]
    @UserId UNIQUEIDENTIFIER -- Reserved for future security implementation
  , @Filter NVARCHAR(100)    -- Filter type: 'open', 'open-and-closed', 'administrative'
AS
    BEGIN
        SET NOCOUNT ON;

        -- =============================================
        -- Main Query: Retrieve amendments with aggregated metrics
        -- Using CTEs for cleaner logic and better performance
        -- =============================================
        WITH AmendmentCTE
          AS
          (SELECT
               Id                    = amendment.Id
             , AmendmentStatusTypeId = amendment.AmendmentStatusTypeId
             , AmendmentMappedTypeId = amendment.AmendmentMappedTypeId
             , Name                  = amendment.Name
             , PsrcDueDate           = amendment.PsrcDueDate
             , TpbReviewDate         = amendment.TpbReviewDate
             , WsdotDueDate          = amendment.WsdotDueDate
             , WsdotPostedDate       = amendment.WsdotPostedDate
             -- Aggregate project counts using window functions for efficiency
             , ProjectCount          = COUNT(proj_amendment.Id) OVER (PARTITION BY amendment.Id)
             -- Count unresolved projects (those not marked 'complete')
             , UnresolvedCount       = SUM(   CASE
                                                  WHEN proj_amendment.ProjectAmendmentReviewStatusTypeId IS NULL THEN 0
                                                  WHEN proj_amend_review_status_type.Code <> 'complete' THEN 1
                                                  ELSE 0
                                              END
                                          ) OVER (PARTITION BY amendment.Id)
           FROM
               tip.Amendment                                  AS amendment
               INNER JOIN tip.AmendmentStatusType             AS amend_status_type
                          ON amend_status_type.Id            = amendment.AmendmentStatusTypeId
               LEFT JOIN tip.AmendmentMappedType              AS amend_mapped_type
                         ON amend_mapped_type.Id             = amendment.AmendmentMappedTypeId
               LEFT JOIN tip.ProjectAmendment                 AS proj_amendment
                         ON proj_amendment.AmendmentId       = amendment.Id
               LEFT JOIN tip.ProjectAmendmentReviewStatusType AS proj_amend_review_status_type
                         ON proj_amend_review_status_type.Id = proj_amendment.ProjectAmendmentReviewStatusTypeId
           WHERE
                   -- Apply filter conditions directly without variable lookups
                   (
                       @Filter                                        = 'open'
                       AND amendment.IsAdministrativeAmendmentFlag    = 0
                       AND (
                               amend_status_type.Code                 <> 'posted'
                               OR amend_mapped_type.Code              = 'not-yet-mapped'
                           )
                   )
                   OR (
                          @Filter                                     = 'open-and-closed'
                          AND amendment.IsAdministrativeAmendmentFlag = 0
                      )
                   OR (
                          @Filter                                     = 'administrative'
                          AND amendment.IsAdministrativeAmendmentFlag = 1
                      )
               )
        -- Result Set 1: Distinct amendments with their metrics
        SELECT DISTINCT
               Id                    = AmendmentCTE.Id
             , AmendmentStatusTypeId = AmendmentCTE.AmendmentStatusTypeId
             , AmendmentMappedTypeId = AmendmentCTE.AmendmentMappedTypeId
             , Name                  = AmendmentCTE.Name
             , PsrcDueDate           = AmendmentCTE.PsrcDueDate
             , TpbReviewDate         = AmendmentCTE.TpbReviewDate
             , WsdotDueDate          = AmendmentCTE.WsdotDueDate
             , WsdotPostedDate       = AmendmentCTE.WsdotPostedDate
             , ProjectCount          = ISNULL(AmendmentCTE.ProjectCount, 0)
             , UnresolvedCount       = ISNULL(AmendmentCTE.UnresolvedCount, 0)
        FROM
            AmendmentCTE
        ORDER BY
            AmendmentCTE.Name DESC;

        -- =============================================
        -- Result Set 2: Project status distribution
        -- Only include amendments from filtered results
        -- =============================================
        SELECT
            AmendmentId                        = proj_amendment.AmendmentId
          , ProjectAmendmentReviewStatusTypeId = proj_amendment.ProjectAmendmentReviewStatusTypeId
          , ProjectAmendmentReviewStatusName   = proj_amendment_review_status_type.Description
          , Count                              = COUNT(*)
        FROM
            tip.ProjectAmendment                      AS proj_amendment
            JOIN tip.ProjectAmendmentReviewStatusType AS proj_amendment_review_status_type
                 ON proj_amendment_review_status_type.Id = proj_amendment.ProjectAmendmentReviewStatusTypeId
        WHERE
            EXISTS (
                       SELECT 1
                       FROM
                           tip.Amendment                      AS amendment
                           INNER JOIN tip.AmendmentStatusType AS amend_status_type
                                      ON amend_status_type.Id = amendment.AmendmentStatusTypeId
                           LEFT JOIN tip.AmendmentMappedType  AS amend_mapped_type
                                     ON amend_mapped_type.Id  = amendment.AmendmentMappedTypeId
                       WHERE
                           amendment.Id                                               = proj_amendment.AmendmentId
                           AND (
                                   (
                                       @Filter                                        = 'open'
                                       AND amendment.IsAdministrativeAmendmentFlag    = 0
                                       AND (
                                               amend_status_type.Code                 <> 'posted'
                                               OR amend_mapped_type.Code              = 'not-yet-mapped'
                                           )
                                   )
                                   OR (
                                          @Filter                                     = 'open-and-closed'
                                          AND amendment.IsAdministrativeAmendmentFlag = 0
                                      )
                                   OR (
                                          @Filter                                     = 'administrative'
                                          AND amendment.IsAdministrativeAmendmentFlag = 1
                                      )
                               )
                   )
        GROUP BY
            proj_amendment.AmendmentId
          , proj_amendment.ProjectAmendmentReviewStatusTypeId
          , proj_amendment_review_status_type.Description
        ORDER BY
            proj_amendment.AmendmentId
          , proj_amendment_review_status_type.Description
          , proj_amendment.ProjectAmendmentReviewStatusTypeId;
    END;
GO
