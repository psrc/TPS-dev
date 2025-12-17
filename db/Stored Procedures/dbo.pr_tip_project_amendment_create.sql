SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO

-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create Date: 2025-07-24
-- Description: Creates a new project amendment record linking a project to an amendment
-- 
-- Purpose:     This procedure creates a new entry in the tip.ProjectAmendment table
--              with an 'unreviewed' review status. It generates a new GUID for the record
--              and returns it to the caller.
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_amendment_create]
    @UserId                 UNIQUEIDENTIFIER -- ID of the user creating the amendment
  , @AmendmentId            UNIQUEIDENTIFIER -- ID of the amendment being applied to the project
  , @ProjectId              UNIQUEIDENTIFIER -- ID of the project being amended
  , @AmendmentSectionTypeId UNIQUEIDENTIFIER -- ID of the amendment section type (category/area of amendment)
AS
    BEGIN
        -- Prevent the count of affected rows from being returned
        SET NOCOUNT ON;

        -- Generate a new unique identifier for this project amendment record
        DECLARE @new_id UNIQUEIDENTIFIER = NEWID();

        -- Variable to store the ID of the 'unreviewed' review status
        DECLARE @unreviewed_status_type UNIQUEIDENTIFIER;

        -- Retrieve the ID for the 'incomplete' review status type
        -- This ensures all new amendments start with an incomplete status
        SELECT @unreviewed_status_type = Id
        FROM
            tip.ProjectAmendmentReviewStatusType
        WHERE
            Code = 'incomplete';

        -- Insert the new project amendment record
        INSERT INTO tip.ProjectAmendment
            (Id, ProjectId, AmendmentId, AmendmentSectionTypeId, ProjectAmendmentReviewStatusTypeId, CreatedById, CreatedOn)
        VALUES
            (@new_id, @ProjectId, @AmendmentId, @AmendmentSectionTypeId, @unreviewed_status_type, @UserId, GETUTCDATE());

        -- Return the newly generated ID to the caller
        SELECT Id = @new_id;
    END;
GO
