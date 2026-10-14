use TPS_dev
go

-- create a test procedure that we can use to check that the form actions 
-- successfully fire it from the form in the front end


create table forms.test_cpeak (
    field1 int identity,
    field2 UNIQUEIDENTIFIER
)
go


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:     Chris Peak 
-- Create date: 2026-10-14
-- Description: test procedure, used in development and testing phases only
--              modeled on forms.pr_formaction_noop
--              forms.pr_formaction_* procedures: exactly these two parameters.
--              Upserts a json value into field with code='hidden_field_1'.  
--              This can be set to fire automatically when a formAssignment goes through a specific transition
-- Parameters:  @UserId           - the user who executed the transition
--              @FormAssignmentId - the assignment that transitioned
-- Returns:     0
-- =============================================
alter PROCEDURE [forms].[pr_formaction_hidden_field_1]
(
    @UserId           UNIQUEIDENTIFIER
,   @FormAssignmentId UNIQUEIDENTIFIER
) AS
BEGIN
    SET NOCOUNT ON;

    -- insert into forms.test_cpeak (field2) 
    -- values (@FormAssignmentId)

    declare @str_value nvarchar(max) = 'hidden string value for form assignment ' + cast(@FormAssignmentId as nvarchar(100))

    declare @agency_id UNIQUEIDENTIFIER

    select @agency_id = AgencyId
    from common.UserProfile 
    where UserId = @UserId

    declare @FormTemplateID UNIQUEIDENTIFIER

    select @FormTemplateID = FormTemplateId
    from forms.FormAssignment  fa 
    where fa.[Id] = @FormAssignmentId

    ;with cte as (
        select 
            newid() as [Id],
            @FormAssignmentId as FormAssignmentID,
            ff.ID as FormFieldId,
            JSON_OBJECT('v': @str_value) AS ValueJson,
            @userId as CreatedById,
            --frv.CreatedOn,
            @userId as UpdatedById,
            GETUTCDATE() as UpdatedOn,
            @agency_id as AgencyId
        from forms.FormField as ff 
            join forms.FormTemplate ft ON ff.FormTemplateId =  ft.[ID]
        where ft.[Id] = @FormTemplateID
                and ff.Code = 'hidden_field_1'
    )
    MERGE INTO forms.FormResponseValue as target 
    USING cte AS source 
        ON target.FormAssignmentId = source.FormAssignmentId 
            AND target.FormFieldId = source.FormFieldId
    WHEN MATCHED THEN UPDATE SET  
        target.ValueJson = source.ValueJson,
        target.UpdatedById = source.UpdatedById,
        target.UpdatedOn = source.UpdatedOn,
        target.AgencyId = source.AgencyId
    WHEN NOT MATCHED THEN INSERT (
        FormAssignmentId,
        FormFieldId,
        ValueJson,
        CreatedById,
        UpdatedById,
        UpdatedOn,
        AgencyId
    ) VALUES (
        source.FormAssignmentId,
        source.FormFieldId,
        source.ValueJson,
        source.CreatedById,
        source.UpdatedById,
        source.UpdatedOn,
        source.AgencyId
    );


        RETURN 0;
END;
GO
