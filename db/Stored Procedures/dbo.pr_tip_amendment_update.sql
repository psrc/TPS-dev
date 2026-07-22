SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
==================================================
Stored Procedure: dbo.pr_tip_amendment_update
==================================================
Purpose: Updates an existing TIP (Transportation Improvement Program) amendment record
         with new values and tracks the user and timestamp of the update.

Author: john.hunter@triskelle.solutions
Created: 2025-07-24

Modified:
    2026-02-19  Added guard to prevent setting status to "Posted" via direct update.
                Posting must go through pr_tip_amendment_post for validation and data promotion.

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID performing the update (required for audit trail)
    @AmendmentId (UNIQUEIDENTIFIER) - Unique identifier of the amendment to update
    @Name (NVARCHAR(50)) - Amendment name/title
    @AmendmentStatusTypeId (UNIQUEIDENTIFIER) - Status type of the amendment (e.g., Draft, In Review, Approved)
    @PsrcDueDate (DATE) - Due date for PSRC (Puget Sound Regional Council) review
    @TpbReviewDate (DATE) - Transportation Policy Board review date
    @WsdotDueDate (DATE) - Washington State DOT due date
    @WsdotSubmittedDate (DATE) - Date submitted to WSDOT
    @WsdotPostedDate (DATE) - Date posted by WSDOT
    @AmendmentMappedTypeId (UNIQUEIDENTIFIER) - Type mapping for the amendment
    @IsAdministrativeAmendmentFlag (BIT) - Indicates if this is an administrative amendment

Returns: No result set (update operation only)

Notes:
    - All date parameters are nullable to allow partial updates
    - Automatically sets UpdatedById and UpdatedOn for audit trail
    - UpdatedOn uses GETUTCDATE() for consistent timezone handling
    - No validation is performed - assumes calling code handles validation

Dependencies:
    - Table: tip.Amendment
    - Columns must exist: Id, Name, AmendmentStatusTypeId, PsrcDueDate, TpbReviewDate,
                         WsdotDueDate, WsdotSubmittedDate, WsdotPostedDate,
                         AmendmentMappedTypeId, IsAdministrativeAmendmentFlag,
                         UpdatedById, UpdatedOn

Example Usage:
    EXEC dbo.pr_tip_amendment_update 
        @UserId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
        @AmendmentId = 'B2C3D4E5-F6A7-8901-BCDE-F23456789012',
        @Name = 'Q1 2025 TIP Amendment',
        @AmendmentStatusTypeId = 'C3D4E5F6-A7B8-9012-CDEF-F34567890123',
        @PsrcDueDate = '2025-03-15',
        @TpbReviewDate = '2025-03-20',
        @WsdotDueDate = '2025-03-25',
        @WsdotSubmittedDate = NULL,
        @WsdotPostedDate = NULL,
        @AmendmentMappedTypeId = 'D4E5F6A7-B8C9-0123-DEFA-F45678901234',
        @IsAdministrativeAmendmentFlag = 0;
==================================================
*/
CREATE    PROCEDURE [dbo].[pr_tip_amendment_update]
    @UserId                        UNIQUEIDENTIFIER      -- User performing the update (required)
  , @AmendmentId                   UNIQUEIDENTIFIER      -- Amendment to update (required)
  , @Name                          NVARCHAR(50)          -- Amendment name (required)
  , @AmendmentStatusTypeId         UNIQUEIDENTIFIER NULL -- Current status of amendment
  , @PsrcDueDate                   DATE NULL             -- PSRC review due date
  , @TpbReviewDate                 DATE NULL             -- TPB review scheduled date
  , @WsdotDueDate                  DATE NULL             -- WSDOT submission due date
  , @WsdotSubmittedDate            DATE NULL             -- Actual WSDOT submission date
  , @WsdotPostedDate               DATE NULL             -- WSDOT posting date
  , @AmendmentMappedTypeId         UNIQUEIDENTIFIER NULL -- Amendment type classification
  , @IsAdministrativeAmendmentFlag BIT NULL              -- Administrative vs full amendment
AS
    BEGIN
        -- Prevent extra result sets from interfering with the update
        SET NOCOUNT ON;

        -- Prevent direct status change to "Posted" via update.
        -- Posting must go through pr_tip_amendment_post for proper validation and data promotion.
        DECLARE @PostedStatusId UNIQUEIDENTIFIER;
        SELECT @PostedStatusId = Id FROM tip.AmendmentStatusType WHERE Code = 'posted';

        IF @AmendmentStatusTypeId = @PostedStatusId
        BEGIN
            ;THROW 50001, 'Cannot set amendment status to Posted via update. Use the Post Amendment function instead.', 1;
        END

        -- Update the amendment record with all provided values
        -- NULL parameters will update the corresponding fields to NULL
        UPDATE tip.Amendment
        SET
            Name = @Name
          , AmendmentStatusTypeId = @AmendmentStatusTypeId
          , PsrcDueDate = @PsrcDueDate
          , TpbReviewDate = @TpbReviewDate
          , WsdotDueDate = @WsdotDueDate
          , WsdotSubmittedDate = @WsdotSubmittedDate
          , WsdotPostedDate = @WsdotPostedDate
          , AmendmentMappedTypeId = @AmendmentMappedTypeId
          , IsAdministrativeAmendmentFlag = @IsAdministrativeAmendmentFlag
                                     -- Audit trail fields - automatically set
          , UpdatedById = @UserId    -- Track who made the update
          , UpdatedOn = GETUTCDATE() -- Track when update occurred (UTC)
        WHERE
            Id = @AmendmentId;

    END;
GO
