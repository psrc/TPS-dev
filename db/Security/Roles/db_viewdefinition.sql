CREATE ROLE [db_viewdefinition]
AUTHORIZATION [dbo]
GO
ALTER ROLE [db_viewdefinition] ADD MEMBER [PSRC\MStepleton]
GO
ALTER ROLE [db_viewdefinition] ADD MEMBER [PSRC\ONg]
GO
GRANT VIEW DEFINITION TO [db_viewdefinition]
