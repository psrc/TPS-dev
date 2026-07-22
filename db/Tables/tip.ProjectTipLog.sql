CREATE TABLE [tip].[ProjectTipLog]
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectTipMappingId] [uniqueidentifier] NULL,
[ProjectTipLogTypeId] [uniqueidentifier] NULL,
[ProjectId] [uniqueidentifier] NULL,
[TipId] [uniqueidentifier] NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RawChanges] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ProjectTipLog_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ProjectTipLog_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectTipLog] ADD CONSTRAINT [PK_ProjectTipLog_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectTipLog] ADD CONSTRAINT [FK_ProjectTipLog_ProjectTipLogType] FOREIGN KEY ([ProjectTipLogTypeId]) REFERENCES [tip].[ProjectTipLogType] ([Id])
GO
ALTER TABLE [tip].[ProjectTipLog] ADD CONSTRAINT [FK_ProjectTipLog_ProjectTipMapping] FOREIGN KEY ([ProjectTipMappingId]) REFERENCES [tip].[ProjectTipMapping] ([Id]) ON DELETE SET NULL
GO
