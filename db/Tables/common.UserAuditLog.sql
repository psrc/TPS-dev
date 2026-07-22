CREATE TABLE [common].[UserAuditLog]
(
[Id] [bigint] NOT NULL IDENTITY(1, 1),
[EventType] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UserId] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TargetUserId] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IpAddress] [nvarchar] (45) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserAgent] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Timestamp] [datetime2] NOT NULL CONSTRAINT [DF_UserAuditLog_Timestamp] DEFAULT (getutcdate()),
[Metadata] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[UserAuditLog] ADD CONSTRAINT [PK__UserAudi__3214EC077DA7C325] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_UserAuditLog_EventType] ON [common].[UserAuditLog] ([EventType]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_UserAuditLog_Timestamp] ON [common].[UserAuditLog] ([Timestamp]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_UserAuditLog_UserId] ON [common].[UserAuditLog] ([UserId]) ON [PRIMARY]
GO
