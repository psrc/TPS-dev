CREATE TABLE [tip].[ProjectAmendmentLog]
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectAmendmentId] [uniqueidentifier] NOT NULL,
[ProjectAmendmentLogTypeId] [uniqueidentifier] NULL,
[SourceRecordId] [uniqueidentifier] NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RawChanges] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ProjectAmendmentLog_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ProjectAmendmentLog_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectAmendmentLog] ADD CONSTRAINT [PK_ProjectAmendmentLog_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ProjectAmendmentLog_CreatedById] ON [tip].[ProjectAmendmentLog] ([CreatedById]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ProjectAmendmentLog_ProjectAmendmentId_CreatedOn] ON [tip].[ProjectAmendmentLog] ([ProjectAmendmentId], [CreatedOn] DESC) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectAmendmentLog] ADD CONSTRAINT [FK_ProjectAmendmentLog_ProjectAmendment] FOREIGN KEY ([ProjectAmendmentId]) REFERENCES [tip].[ProjectAmendment] ([Id]) ON DELETE CASCADE
GO
ALTER TABLE [tip].[ProjectAmendmentLog] ADD CONSTRAINT [FK_ProjectAmendmentLog_ProjectAmendmentLogType] FOREIGN KEY ([ProjectAmendmentLogTypeId]) REFERENCES [tip].[ProjectAmendmentLogType] ([Id])
GO
