SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
-- =============================================
-- Author:      [Author Name]
-- Create date: [Creation Date]
-- Description: Generates a suggested project ID for a new project
--              based on agency short name, current year, and project sequence.
--              Format: [AgencyShortName]-[YY]-[###]
--              Example: DOT-25-001, METRO-25-002
-- Parameters:  @UserId   - User requesting the suggestion (for auditing)
--              @AgencyId - Agency ID for which to generate project suggestion
-- Returns:     Single column result set with suggested project ID
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_id_suggestion]
(
    @UserId   UNIQUEIDENTIFIER
,   @AgencyId UNIQUEIDENTIFIER
) AS
BEGIN
    SET NOCOUNT ON;

    -- =============================================
    -- SECTION 1: Variable Declarations
    -- =============================================
    DECLARE @AgencyShortName NVARCHAR(60);
    DECLARE @Suggestion NVARCHAR(30);
    DECLARE @ProjectCount INT;
    DECLARE @Sequence NVARCHAR(10);
    DECLARE @Year NVARCHAR(2);

    -- =============================================
    -- SECTION 2: Agency Validation
    -- =============================================
    -- Retrieve the agency short name for the given agency ID
    SELECT @AgencyShortName = ShortName FROM common.Agency WHERE Id = @AgencyId;

    -- If agency not found, return empty suggestion
    IF @AgencyShortName IS NULL
        BEGIN
            SELECT ProjectIdSuggestion = '';
            RETURN 0;
        END;

    -- =============================================
    -- SECTION 3: Generate Project ID Components
    -- =============================================
    -- Get total project count to determine next sequence number
    SELECT @ProjectCount = COUNT(*) FROM tip.Project;

    -- Format sequence as 3-digit zero-padded number (001, 002, etc.)
    -- Use NVARCHAR(10) for conversion to handle large project counts
    SET @Sequence = RIGHT('000' + CONVERT(NVARCHAR(10), @ProjectCount + 1), 3);

    -- Get current year as 2-digit format (25 for 2025)
    SET @Year = RIGHT(CONVERT(NVARCHAR(4), YEAR(GETUTCDATE())), 2);

    -- =============================================
    -- SECTION 4: Build and Return Suggestion
    -- =============================================
    -- Construct the suggested project ID: AgencyShortName-YY-### 
    SET @Suggestion = @AgencyShortName + N'-' + @Year + N'-' + @Sequence;

    -- Return the suggested project ID
    SELECT ProjectIdSuggestion = @Suggestion;

    RETURN 0;

END;
GO
