use TPS_dev
go

/*********************
Copy a single field from one form response, titled "A" in this example,
to a different response under the same form template.

The destination response title is simply "B" in this example,
and the form template has the pithy name "cpeak field testing 26.09.21"
******************/

---------
declare @FormAssignmentId UNIQUEIDENTIFIER

-- get the GUID for the destination form response
select @FormAssignmentId = fa.[Id]
from forms.FormTemplate ft 
    join forms.FormAssignment fa on ft.[ID] = fa.FormTemplateId
where ft.[Name] = 'cpeak field testing 26.09.21'
    and fa.LabelContext = 'B'

select @FormAssignmentId

-- copy response value for field TEXT_1 from response titled "test 26.10.01 A"
INSERT INTO forms.FormResponseValue (
    [Id],
    FormAssignmentId,
    FormFieldId,
    ValueJson,
    CreatedById,
    CreatedOn,
    UpdatedById,
    UpdatedOn,
    AgencyId
)
select 
    newid() as [Id],
    @FormAssignmentId,
    frv.FormFieldId,
    frv.ValueJson,
    frv.CreatedById,
    frv.CreatedOn,
    frv.UpdatedById,
    frv.UpdatedOn,
    frv.AgencyId
from forms.FormTemplate ft 
    join forms.FormAssignment fa on ft.[ID] = fa.FormTemplateId
    join forms.FormResponseValue frv on frv.FormAssignmentId = fa.[Id]
    join forms.FormField ff on frv.FormFieldId = ff.[Id]
where ft.[Name] = 'cpeak field testing 26.09.21'
    and fa.LabelContext = 'A'
    and ff.Code = 'TEXT_1'
