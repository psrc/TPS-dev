SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*************************************************************************************************
-- =============================================
-- Author:        john.hunter@triskelle.solutions
-- Create date:   2025-07-23
-- Description:   Retrieves all TIP (Transportation Improvement Program) projects from the system
--                with comprehensive project details including location, funding, and status information.
-- =============================================
-- Business Context:
--   This procedure serves as the primary data retrieval mechanism for TIP project listings used
--   on the Programmed Funding tab "Move" funds functionality.
--
-- Dependencies:
--   - Table: 
--            tip.Project (source table containing all TIP project records)
--            common.Agency (used to filter results if search term provided)
--
-- =============================================
-- Change History:
-- Date         Author              Description
-- ----------   ----------------    -------------------------------------------------------------
-- [Date]       [Author]            Initial creation
-- =============================================
*************************************************************************************************/
CREATE   PROCEDURE [dbo].[pr_tip_project_get_all]
    @UserId     UNIQUEIDENTIFIER -- User identifier passed for potential future security/filtering needs
  , @SearchTerm NVARCHAR(200)    -- Optional search term used to filter results on ProjectCode, Name, Agency
AS
    BEGIN
        SET NOCOUNT ON; -- Suppress row count messages to improve performance and reduce network traffic

        -- Retrieve comprehensive TIP project data ordered by creation timestamp
        -- Note: Returns all columns to support various downstream consumption patterns
        SELECT
            -- Primary Identifiers
            project.Id                          -- Unique project identifier
          , project.AgencyId                    -- Managing agency reference
                                                -- Project Details
          , project.ProjectCode                 -- Project code for external reference
          , project.Title                       -- Project name/description
          , project.ContactId                   -- Primary project contact reference
          , project.WsDotPin                    -- Washington State DOT Project Identification Number
          , project.DemoId                      -- Demonstration project identifier (if applicable)
                                                -- Location Information
          , project.Location                    -- General project location description
          , project.LocationFrom                -- Project start point (for linear projects)
          , project.LocationTo                  -- Project end point (for linear projects)
          , project.Length                      -- Project length (typically in miles for roadway projects)
                                                -- Classification and Type Codes
          , project.FunctionalClassTypeId       -- Federal functional classification of the facility
          , project.PrimaryImprovementTypeId    -- Main type of improvement (e.g., widening, new construction)
          , project.MappedTypeId                -- Geographic mapping classification
                                                -- Project Description and Status
          , project.Description                 -- Detailed project description
          , project.DateFullyImplemented        -- Project completion date
          , project.RcpStatusTypeId             -- Regional Capital Plan status
          , project.CompletionStatusTypeId      -- Overall project completion status
                                                -- Financial Information
          , project.ConstantDollarProjectYear   -- Base year for constant dollar calculations
                                                -- Environmental and Planning
          , project.EnvironmentalStatusTypeId   -- NEPA/SEPA environmental review status
          , project.RegionalSignificanceTypeId  -- Regional significance designation
                                                -- Project Phase Completion Years
          , project.YearCompPL                  -- Planning phase completion year
          , project.YearCompPE                  -- Preliminary Engineering completion year
          , project.YearCompROW                 -- Right-of-Way acquisition completion year
          , project.YearCompCN                  -- Construction phase completion year
          , project.YearCompOther               -- Other phases completion year
                                                -- Administrative Information
          , project.CaSponsorAgencyId           -- Co-sponsoring agency (if applicable)
                                                -- UPWP (Unified Planning Work Program) Related Fields
          , project.UpwpObjective               -- UPWP objective alignment
          , project.UpwpTasks                   -- Associated UPWP tasks
          , project.UpwpProducts                -- Expected UPWP deliverables
          , project.UpwpPolicy                  -- Related UPWP policies
          , project.UpwpIsEquipmentPurchaseFlag -- Indicates if project includes equipment purchase
                                                -- Comments and Metadata
          , project.PsrcComments                -- Puget Sound Regional Council comments
                                                -- Audit Trail
          , project.CreatedById                 -- User who created the record
          , project.CreatedOn                   -- Record creation timestamp
          , project.UpdatedById                 -- User who last updated the record
          , project.UpdatedOn                   -- Last update timestamp
        FROM
            tip.Project             AS project
            LEFT JOIN common.Agency AS agy
                      ON agy.Id = project.AgencyId
        WHERE
            ISNULL(@SearchTerm, '') = ''
            OR project.ProjectCode LIKE '%' + @SearchTerm + '%'
            OR project.Title LIKE '%' + @SearchTerm + '%'
            OR agy.Name LIKE '%' + @SearchTerm + '%'
        ORDER BY
            project.ProjectCode;
    END;
GO
