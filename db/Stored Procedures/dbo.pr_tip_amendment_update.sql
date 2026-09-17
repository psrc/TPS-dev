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
    2026-09-09  PSRC-tvb0 / Asana TIP-006 - guard: refuse to set the TIP Webmap Update Status
                (AmendmentMappedTypeId) to Yes while any project in the amendment is still
                'Not Yet Mapped'. Throws 50002 with a message naming the count.
    2026-09-09  PSRC-kikm - added @TipId. Two deliberate differences from every other parameter
                here. It is declared "= NULL", a real default, not the bare "NULL" the others use
                (which only declares nullability and leaves the parameter REQUIRED) - so a caller
                written before this parameter existed still works. And NULL PRESERVES the existing
                value rather than clearing it, because an amendment must keep a TIP.

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
    @AmendmentMappedTypeId (UNIQUEIDENTIFIER) - TIP Webmap Update Status (Yes/No). Setting it to
        Yes is refused while any project in the amendment is still 'Not Yet Mapped' (TIP-006)
    @IsAdministrativeAmendmentFlag (BIT) - Indicates if this is an administrative amendment
    @TipId (UNIQUEIDENTIFIER) - TIP the amendment belongs to; NULL leaves the existing value alone

Returns: No result set (update operation only)

Notes:
    - All date parameters are nullable to allow partial updates
    - @TipId is the one exception to "NULL sets NULL" - see the 2026-09-09 note above
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
-- Modified:    2026-09-12 - PSRC-mte.1 tenancy scoping (@TenantAgencyId/@BypassTenancy)
CREATE PROCEDURE [dbo].[pr_tip_amendment_update]
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
  , @TipId                         UNIQUEIDENTIFIER = NULL -- TIP the amendment belongs to; NULL preserves
  , @TenantAgencyId UNIQUEIDENTIFIER = NULL -- PSRC-mte.1: caller's agency (NULL = none)
  , @BypassTenancy  BIT              = 0    -- PSRC-mte.1: 1 = internal caller, no scoping
AS
    BEGIN
        -- Prevent extra result sets from interfering with the update
        SET NOCOUNT ON;
        -- PSRC-mte.1: internal-only. This object has no owning agency, so a scoped caller has no
        -- rows here at all; refusing beats guessing.
        IF @BypassTenancy = 0
            THROW 50403, 'Tenancy: pr_tip_amendment_update is internal-only.', 1;

        -- Prevent direct status change to "Posted" via update.
        -- Posting must go through pr_tip_amendment_post for proper validation and data promotion.
        DECLARE @PostedStatusId UNIQUEIDENTIFIER;
        SELECT @PostedStatusId = Id FROM tip.AmendmentStatusType WHERE Code = 'posted';

        IF @AmendmentStatusTypeId = @PostedStatusId
        BEGIN
            ;THROW 50001, 'Cannot set amendment status to Posted via update. Use the Post Amendment function instead.', 1;
        END

        -- Asana TIP-006: an amendment cannot claim the webmap is updated while any of its
        -- projects is still awaiting geocoding. Project status is read pending-then-posted,
        -- because inside an open amendment the pending row is the one being edited.
        -- Codes are matched against both the live spellings and the seed's, which differ.
        IF @AmendmentMappedTypeId IS NOT NULL
           AND EXISTS (SELECT 1
                       FROM tip.AmendmentMappedType
                       WHERE Id = @AmendmentMappedTypeId
                         AND Code IN ('Yes', 'mapped'))
        BEGIN
            DECLARE @NotYetMapped INT =
            (
                SELECT COUNT(*)
                FROM tip.ProjectAmendment AS pa
                    LEFT JOIN tip.Project         AS p  ON p.Id  = pa.ProjectId
                    LEFT JOIN tip.Project_Pending AS pp ON pp.ProjectAmendmentId = pa.Id
                    INNER JOIN tip.MappedType     AS mt ON mt.Id = COALESCE(pp.MappedTypeId, p.MappedTypeId)
                                                       AND mt.Code IN ('Not Yet Mapped', 'not-yet-mapped')
                WHERE pa.AmendmentId = @AmendmentId
            );

            IF @NotYetMapped > 0
            BEGIN
                DECLARE @NotMappedMsg NVARCHAR(400) =
                    CONCAT('Cannot set TIP Webmap Update Status to Yes: ', @NotYetMapped,
                           ' project(s) in this amendment are still Not Yet Mapped. ',
                           'Set each project''s Geocoding Status first.');
                ;THROW 50002, @NotMappedMsg, 1;
            END
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
                                     -- Deliberately NOT "NULL sets NULL": an amendment keeps its
                                     -- TIP unless the caller names a new one.
          , TipId = COALESCE(@TipId, TipId)
                                     -- Audit trail fields - automatically set
          , UpdatedById = @UserId    -- Track who made the update
          , UpdatedOn = GETUTCDATE() -- Track when update occurred (UTC)
        WHERE
            Id = @AmendmentId;

    END;


GO
