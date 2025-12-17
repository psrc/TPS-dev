SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create Date: 2025-07-24
-- Description: Creates a new amendment record in the TIP (Transportation Improvement Program) system
-- 
-- Purpose:     This procedure creates a new entry in the tip.Amendment table with various
--              administrative and timeline details. It generates a new GUID for the record
--              and returns it to the caller.
-- =============================================
CREATE   PROCEDURE [dbo].[pr_tip_amendment_create]
    @UserId                        UNIQUEIDENTIFIER        -- ID of the user creating the amendment
  , @Name                          NVARCHAR(50)            -- Name/description of the amendment
  , @AmendmentStatusTypeId         UNIQUEIDENTIFIER = NULL -- Current status of the amendment (optional)
  , @AmendmentMappedTypeId         UNIQUEIDENTIFIER = NULL -- Type/category of amendment (optional)
  , @PsrcDueDate                   DATE             = NULL -- PSRC (Puget Sound Regional Council) due date (optional)
  , @TpbReviewDate                 DATE             = NULL -- TPB (Transportation Policy Board) review date (optional)
  , @WsdotDueDate                  DATE             = NULL -- WSDOT (Washington State DOT) due date (optional)
  , @WsdotSubmittedDate            DATE             = NULL -- Date submitted to WSDOT (optional)
  , @WsdotPostedDate               DATE             = NULL -- Date posted by WSDOT (optional)
  , @IsAdministrativeAmendmentFlag BIT                     -- Flag indicating if this is an administrative amendment
AS
    BEGIN
        -- Prevent the count of affected rows from being returned
        SET NOCOUNT ON;

        -- Generate a new unique identifier for this amendment record
        DECLARE @Id UNIQUEIDENTIFIER = NEWID();

        -- Insert the new amendment record with all provided details
        INSERT tip.Amendment
            (Id
           , AmendmentStatusTypeId
           , Name
           , PsrcDueDate
           , TpbReviewDate
           , WsdotDueDate
           , WsdotSubmittedDate
           , WsdotPostedDate
           , AmendmentMappedTypeId
           , IsAdministrativeAmendmentFlag
           , CreatedById
           , CreatedOn)
        VALUES
            (@Id
           , @AmendmentStatusTypeId
           , @Name
           , @PsrcDueDate
           , @TpbReviewDate
           , @WsdotDueDate
           , @WsdotSubmittedDate
           , @WsdotPostedDate
           , @AmendmentMappedTypeId
           , @IsAdministrativeAmendmentFlag
           , @UserId      -- Track who created this record
           , GETUTCDATE() -- Track when this record was created (UTC time)
            );

        -- Return the newly generated ID to the caller
        SELECT @Id;
    END;
GO
