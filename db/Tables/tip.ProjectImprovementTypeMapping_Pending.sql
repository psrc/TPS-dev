CREATE TABLE [tip].[ProjectImprovementTypeMapping_Pending]
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectId] [uniqueidentifier] NOT NULL,
[ImprovementTypeId] [uniqueidentifier] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ProjectImprovementTypeMapping_Pending_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ProjectImprovementTypeMapping_Pending_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectImprovementTypeMapping_Pending] ADD CONSTRAINT [PK_ProjectImprovementTypeMapping] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectImprovementTypeMapping_Pending] ADD CONSTRAINT [PK_ProjectImprovementTypeMapping_Pending_Project_Pending_ImprovementType] UNIQUE NONCLUSTERED ([ProjectId], [ImprovementTypeId]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectImprovementTypeMapping_Pending] ADD CONSTRAINT [FK_ProjectImprovementTypeMapping_Pending_ImprovementType] FOREIGN KEY ([ImprovementTypeId]) REFERENCES [tip].[ImprovementType] ([Id])
GO
ALTER TABLE [tip].[ProjectImprovementTypeMapping_Pending] ADD CONSTRAINT [FK_ProjectImprovementTypeMapping_Pending_Project] FOREIGN KEY ([ProjectId]) REFERENCES [tip].[Project_Pending] ([Id])
GO
