IF NOT EXISTS (SELECT * FROM master.dbo.syslogins WHERE loginname = N'PSRC\MStepleton')
CREATE LOGIN [PSRC\MStepleton] FROM WINDOWS
GO
CREATE USER [PSRC\MStepleton] FOR LOGIN [PSRC\MStepleton]
GO
