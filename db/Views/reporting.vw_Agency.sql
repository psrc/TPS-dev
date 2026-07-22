SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [reporting].[vw_Agency]
AS
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
LEFT JOIN common.WsdotRegion wr ON a.WsdotRegionId = wr.Id;
GO
