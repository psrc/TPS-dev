SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2026-02-06
-- Modified:    2026-05-13 - Treat empty/whitespace ProjectNamePrefix as missing (return blank)
-- Description: Generates a suggested project ID for a new project
--              based on agency prefix and project sequence.
--              Format: [AgencyPrefix]-[#]
--              Example: SEA-53, DOT-1
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

    -- Variable declarations
    DECLARE @AgencyNamePrefix NVARCHAR(60);
    DECLARE @NextSequence INT;

    -- Retrieve the agency short name for the given agency ID
    SELECT @AgencyNamePrefix = Agency.ProjectNamePrefix
        FROM common.Agency
        WHERE Id = @AgencyId;

    -- If agency not found, or prefix is missing/blank, return an empty suggestion
    IF @AgencyNamePrefix IS NULL OR LEN(LTRIM(RTRIM(@AgencyNamePrefix))) = 0
        BEGIN
            SELECT ProjectIdSuggestion = '';
            RETURN 0;
        END;

    -- Get the next sequence number for this agency.
    -- Uses MAX of existing numeric suffixes to avoid gaps/collisions from deletions.
    -- The LIKE guard ensures we only parse suffixes from codes that match
    -- the expected pattern, avoiding TRY_CONVERT errors on malformed data.
    SELECT @NextSequence = ISNULL(MAX(
                                          TRY_CONVERT(INT,
                                                  CASE
                                                      WHEN ProjectCode LIKE @AgencyNamePrefix + N'-[0-9]%'
                                                          THEN SUBSTRING(ProjectCode, LEN(@AgencyNamePrefix) + 2, LEN(ProjectCode))
                                                  END
                                          )
                                  ), 0) + 1
        FROM tip.Project
        WHERE AgencyId = @AgencyId;

    -- Return the suggested project ID: AgencyPrefix-#
    SELECT ProjectIdSuggestion = @AgencyNamePrefix + N'-'
        + CONVERT(NVARCHAR(10), @NextSequence);

    RETURN 0;
END;
GO
