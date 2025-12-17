CREATE TABLE [tip].[ProjectCountyMapping_Pending]
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectId] [uniqueidentifier] NOT NULL,
[CountyId] [uniqueidentifier] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ProjectCo__Creat__22D5121F] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__ProjectCo__Creat__23C93658] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectCountyMapping_Pending] ADD CONSTRAINT [PK_ProjectCountyMapping_Pending] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectCountyMapping_Pending] ADD CONSTRAINT [PK_ProjectCountyMapping_Pending_ProjectId_CountyId] UNIQUE NONCLUSTERED ([ProjectId], [CountyId]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectCountyMapping_Pending] ADD CONSTRAINT [FK_ProjectCountyMapping_Pending_County] FOREIGN KEY ([CountyId]) REFERENCES [common].[County] ([Id])
GO
ALTER TABLE [tip].[ProjectCountyMapping_Pending] ADD CONSTRAINT [FK_ProjectCountyMapping_Pending_Project] FOREIGN KEY ([ProjectId]) REFERENCES [tip].[Project_Pending] ([Id])
GO
