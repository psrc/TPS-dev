CREATE TABLE [tip].[ProjectRcpProjectMapping]
(
[Id] [uniqueidentifier] NOT NULL,
[TipProjectId] [uniqueidentifier] NOT NULL,
[RcpProjectId] [uniqueidentifier] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ProjectRc__Creat__31233176] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__ProjectRc__Creat__321755AF] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectRcpProjectMapping] ADD CONSTRAINT [PK_ProjectRcpProjectMapping_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectRcpProjectMapping] ADD CONSTRAINT [UQ_ProjectRcpProjectMapping_RcpProjectId_TipProjectId] UNIQUE NONCLUSTERED ([TipProjectId], [RcpProjectId]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectRcpProjectMapping] ADD CONSTRAINT [FK_ProjectRcpProjectMapping_RcpProject] FOREIGN KEY ([RcpProjectId]) REFERENCES [rcp].[Project] ([Id])
GO
ALTER TABLE [tip].[ProjectRcpProjectMapping] ADD CONSTRAINT [FK_ProjectRcpProjectMapping_TipProject] FOREIGN KEY ([TipProjectId]) REFERENCES [tip].[Project] ([Id])
GO
