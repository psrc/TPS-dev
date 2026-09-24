
use TPS_dev



-- select the sum of row "amount" value per json string
select ft.[name] as templateName,
    ff.Label as FieldLabel,
    frv.ValueJson,
    frv.ValueText,
    (
        SELECT SUM(j.amount)
        FROM OPENJSON(frv.ValueJson, '$.v.rows')
            WITH (amount bigint '$.amount') AS J
    ) as TotalAmount
from forms.FormResponseValue as frv 
    join forms.FormAssignment fa on frv.FormAssignmentId = fa.Id
    join forms.FormField as ff on ff.Id = frv.FormFieldId
    join forms.FormSection as fs on ff.FormSectionId = fs.Id
    join forms.FormTemplate as ft on fs.FormTemplateId = ft.Id
where ft.[Name] = 'cpeak -- internal review and comment'
    and fa.LabelContext = 'try 26.09.24'


-- using a correlated subquery is cleaner SQL if you want more than one aggregate
--  we use OUTER in order to keep rows whose JSON has no 'rows' array.
select ft.[name] as templateName,
    ff.Label as FieldLabel,
    frv.ValueJson,
    frv.ValueText,
    a.TotalAmount
from forms.FormResponseValue as frv 
    join forms.FormAssignment fa on frv.FormAssignmentId = fa.Id
    join forms.FormField as ff on ff.Id = frv.FormFieldId
    join forms.FormSection as fs on ff.FormSectionId = fs.Id
    join forms.FormTemplate as ft on fs.FormTemplateId = ft.Id
OUTER APPLY (
    SELECT SUM(j.amount)            AS TotalAmount
    FROM OPENJSON(frv.ValueJson, '$.v.rows')
        WITH (
            amount      DECIMAL(18,0) '$.amount'
        ) as j
) as a 
where ft.[Name] = 'cpeak -- internal review and comment'
    and fa.LabelContext = 'try 26.09.24'