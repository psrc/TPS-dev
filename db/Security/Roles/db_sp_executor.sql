CREATE ROLE [db_sp_executor]
AUTHORIZATION [dbo]
GO
ALTER ROLE [db_sp_executor] ADD MEMBER [TPS_web_dev]
GO
GRANT EXECUTE TO [db_sp_executor]
