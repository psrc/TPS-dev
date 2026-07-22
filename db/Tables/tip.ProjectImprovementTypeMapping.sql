CREATE TABLE [tip].[ProjectImprovementTypeMapping]
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectId] [uniqueidentifier] NOT NULL,
[ImprovementTypeId] [uniqueidentifier] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ProjectImprovementTypeMapping_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ProjectImprovementTypeMapping_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectImprovementTypeMapping] ADD CONSTRAINT [PK_ProjectImprovementType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectImprovementTypeMapping] ADD CONSTRAINT [UQ_ProjectImprovementTypeMapping_ProjectId_ImprovementTypeId] UNIQUE NONCLUSTERED ([ProjectId], [ImprovementTypeId]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectImprovementTypeMapping] ADD CONSTRAINT [FK_ProjectImprovementTypeMapping_ImprovementType] FOREIGN KEY ([ImprovementTypeId]) REFERENCES [tip].[ImprovementType] ([Id])
GO
ALTER TABLE [tip].[ProjectImprovementTypeMapping] ADD CONSTRAINT [FK_ProjectImprovementTypeMapping_Project] FOREIGN KEY ([ProjectId]) REFERENCES [tip].[Project] ([Id])
GO
