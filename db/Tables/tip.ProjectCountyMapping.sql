CREATE TABLE [tip].[ProjectCountyMapping]
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectId] [uniqueidentifier] NOT NULL,
[CountyId] [uniqueidentifier] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ProjectCo__Creat__1E105D02] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__ProjectCo__Creat__1F04813B] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectCountyMapping] ADD CONSTRAINT [PK_ProjectCountyMapping] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectCountyMapping] ADD CONSTRAINT [UQ_ProjectCountyMapping_CountyId_ProjectId] UNIQUE NONCLUSTERED ([ProjectId], [CountyId]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectCountyMapping] ADD CONSTRAINT [FK_ProjectCountyMapping_County] FOREIGN KEY ([CountyId]) REFERENCES [common].[County] ([Id])
GO
ALTER TABLE [tip].[ProjectCountyMapping] ADD CONSTRAINT [FK_ProjectCountyMapping_Project] FOREIGN KEY ([ProjectId]) REFERENCES [tip].[Project] ([Id])
GO
