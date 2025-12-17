SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
/*
==================================================
Stored Procedure: dbo.pr_tip_project_create
==================================================
Purpose: Creates a new TIP (Transportation Improvement Program) project with basic information
         and returns the complete project record including all fields and default values.

Author: [Author Name]
Created: [Date]
Modified: [Date] - [Reason for modification]

Parameters:
    @UserId (UNIQUEIDENTIFIER) - User ID creating the project (for audit trail)
    @AgencyId (UNIQUEIDENTIFIER) - Agency responsible for the project
    @ProjectCode (NVARCHAR(50)) - Unique project identifier/code
    @Title (NVARCHAR(255)) - Project title/name
    @Description (NVARCHAR(50)) - Brief project description
    @TipId (UNIQUEIDENTIFIER) - Optional TIP ID to add the project to

Returns: Single row with complete project information including all fields,
         system-generated values, and default/null values for unspecified fields

Example Usage:
    EXEC dbo.pr_tip_project_create
        @UserId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
        @AgencyId = 'B2C3D4E5-F6A7-8901-BCDE-F23456789012',
        @ProjectCode = 'DOT-25-001',
        @Title = 'Highway 99 Bridge Replacement',
        @Description = 'Replace aging bridge structure',
        @TipId = 'C3D4E5F6-A7B8-9012-CDEF-345678901234'

Dependencies:
    - Table: tip.Project
    - Table: tip.TipProjectMapping

Business Rules:
    - Creates minimal project record with only basic required fields
    - All optional fields (ContactId, WsDotPin, etc.) are left as NULL/default
    - Project ID is auto-generated using NEWID()
    - CreatedOn timestamp uses UTC time
    - If TipId is provided, creates a TipProjectMapping to associate project with TIP
    - Returns complete project record for client use
    - No validation on ProjectCode uniqueness (handled by database constraints)
==================================================
*/

CREATE PROCEDURE [dbo].[pr_tip_project_create]
(
    @UserId      UNIQUEIDENTIFIER -- User creating the project
,   @AgencyId    UNIQUEIDENTIFIER -- Agency responsible for project
,   @ProjectCode NVARCHAR(50) -- Unique project identifier
,   @Title       NVARCHAR(255) -- Project title
,   @Description NVARCHAR(50) -- Brief project description
,   @TipId       UNIQUEIDENTIFIER = NULL -- Optional TIP to add project to
) AS
BEGIN
    SET NOCOUNT ON;
    -- Prevent extra result sets from interfering with SELECT statements

    -- Generate unique identifier for the new project
    DECLARE @Id UNIQUEIDENTIFIER = NEWID();

    -- Insert new project record with basic information
    INSERT
        INTO
            tip.Project
            (Id, AgencyId, ProjectCode, Title, Description, CreatedById, CreatedOn)
        VALUES
            (@Id, @AgencyId, @ProjectCode, @Title, @Description, @UserId, GETUTCDATE());

    -- If TipId is provided, create the TipProjectMapping to associate project with the TIP
    IF @TipId IS NOT NULL
    BEGIN
        INSERT
            INTO
                tip.ProjectTipMapping
                (Id, ProjectId, TipId, CreatedById, CreatedOn)
            VALUES
                (NEWID(), @Id, @TipId, @UserId, GETUTCDATE());
    END;

    -- Return complete project record including all fields
    SELECT
        Id
      , AgencyId
      , ProjectCode
      , Title
      , ContactId
      , WsDotPin
      , DemoId
      , Location
      , LocationFrom
      , LocationTo
      , Length
      , FunctionalClassTypeId
      , PrimaryImprovementTypeId
      , Description
      , DateFullyImplemented
      , RcpStatusTypeId
      , ConstantDollarProjectYear
      , MappedTypeId
      , EnvironmentalStatusTypeId
      , RegionalSignificanceTypeId
      , YearCompPL
      , YearCompPE
      , YearCompROW
      , YearCompCN
      , YearCompOther
      , DateCompProject
      , CaSponsorAgencyId
      , CompletionStatusTypeId
      , UpwpObjective
      , UpwpTasks
      , UpwpProducts
      , UpwpPolicy
      , UpwpIsEquipmentPurchaseFlag
      , PsrcComments
      , CreatedById
      , CreatedOn
      , UpdatedById
      , UpdatedOn
        FROM
            tip.Project
        WHERE
            Id = @Id;
END;
GO
