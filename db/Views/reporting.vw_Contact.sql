SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [reporting].[vw_Contact]
AS
SELECT
    c.Id,
    c.FirstName,
    c.LastName,
    c.FirstName + ' ' + c.LastName AS FullName,
    c.Email,
    c.Phone,
    c.PhoneExt,
    a.Name AS AgencyName,
    a.ShortName AS AgencyShortName,
    c.IsActive,
    c.Notes,
    c.CreatedOn,
    c.UpdatedOn
FROM common.Contact c
LEFT JOIN common.Agency a ON c.AgencyId = a.Id;
GO
