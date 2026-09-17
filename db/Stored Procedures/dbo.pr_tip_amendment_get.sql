SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2025-07-24
-- Description: Retrieves a single TIP amendment record by ID
-- Modified:    2026-09-09 - PSRC-kikm - return TipId so the Add-Project dialog can inherit the
--                           amendment's TIP instead of guessing the current one.
-- Modified:    2026-09-12 - PSRC-mte.1 tenancy scoping (@TenantAgencyId/@BypassTenancy)
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_amendment_get]
    @UserId      UNIQUEIDENTIFIER -- User requesting the data (currently unused but may be for future authorization)
  , @AmendmentId UNIQUEIDENTIFIER -- The unique identifier of the amendment to retrieve
  , @TenantAgencyId UNIQUEIDENTIFIER = NULL -- PSRC-mte.1: caller's agency (NULL = none)
  , @BypassTenancy  BIT              = 0    -- PSRC-mte.1: 1 = internal caller, no scoping
AS
    BEGIN
        SET NOCOUNT ON;
        -- PSRC-mte.1: internal-only. This object has no owning agency, so a scoped caller has no
        -- rows here at all; refusing beats guessing.
        IF @BypassTenancy = 0
            THROW 50403, 'Tenancy: pr_tip_amendment_get is internal-only.', 1;

        -- Retrieve all fields for the specified amendment
        -- Note: Column aliases match the source column names for clarity
        SELECT
            Id                            = amendment.Id
          , AmendmentStatusTypeId         = amendment.AmendmentStatusTypeId
          , TipId                         = amendment.TipId                         -- The TIP this amendment belongs to
          , Name                          = amendment.Name
          , PsrcDueDate                   = amendment.PsrcDueDate                   -- Due date for PSRC (Puget Sound Regional Council)
          , TpbReviewDate                 = amendment.TpbReviewDate                 -- Transportation Policy Board review date
          , WsdotDueDate                  = amendment.WsdotDueDate                  -- Washington State DOT due date
          , WsdotSubmittedDate            = amendment.WsdotSubmittedDate            -- Date submitted to WSDOT
          , WsdotPostedDate               = amendment.WsdotPostedDate               -- Date posted by WSDOT
          , AmendmentMappedTypeId         = amendment.AmendmentMappedTypeId         -- Indicates if Mapping is complete for all projects
          , IsAdministrativeAmendmentFlag = amendment.IsAdministrativeAmendmentFlag -- Indicates if this is an administrative amendment
          , CreatedById                   = amendment.CreatedById                   -- User who created the record
          , CreatedOn                     = amendment.CreatedOn                     -- Record creation timestamp
          , UpdatedById                   = amendment.UpdatedById                   -- User who last updated the record
          , UpdatedOn                     = amendment.UpdatedOn                     -- Last update timestamp
        FROM
            tip.Amendment AS amendment
        WHERE
            amendment.Id = @AmendmentId;
    END;


GO
