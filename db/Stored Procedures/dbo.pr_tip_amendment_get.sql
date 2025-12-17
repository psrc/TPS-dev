SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2025-07-24
-- Description: Retrieves a single TIP amendment record by ID
-- =============================================
CREATE   PROCEDURE [dbo].[pr_tip_amendment_get]
    @UserId      UNIQUEIDENTIFIER -- User requesting the data (currently unused but may be for future authorization)
  , @AmendmentId UNIQUEIDENTIFIER -- The unique identifier of the amendment to retrieve
AS
    BEGIN
        SET NOCOUNT ON;

        -- Retrieve all fields for the specified amendment
        -- Note: Column aliases match the source column names for clarity
        SELECT
            Id                            = amendment.Id
          , AmendmentStatusTypeId         = amendment.AmendmentStatusTypeId
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
