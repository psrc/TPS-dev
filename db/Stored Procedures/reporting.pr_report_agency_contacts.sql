SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [reporting].[pr_report_agency_contacts]
AS
BEGIN
    SET NOCOUNT ON;

    -- Result Set 1: Metadata (Tab Names)
    SELECT 'Agencies' AS TabName
    UNION ALL
    SELECT 'Contacts';

    -- Result Set 2: Agencies
    SELECT
        a.Id,
        a.Name,
        a.ShortName,
        a.ProjectNamePrefix,
        at.Code AS AgencyTypeCode,
        at.Description AS AgencyType,
        a.WsdotName,
        c.Code AS WsdotCounty,
        wr.Code AS WsdotRegion,
        a.AppendixAGroup,
        a.PlaceAggregated,
        a.IsActive,
        a.CreatedOn,
        a.UpdatedOn
    FROM common.Agency a
    LEFT JOIN common.AgencyType at ON a.AgencyTypeId = at.Id
    LEFT JOIN common.County c ON a.WsdotCountyId = c.Id
    LEFT JOIN common.WsdotRegion wr ON a.WsdotRegionId = wr.Id
    ORDER BY a.Name;

    -- Result Set 3: Contacts
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
    LEFT JOIN common.Agency a ON c.AgencyId = a.Id
    ORDER BY c.LastName, c.FirstName;
END;
GO
