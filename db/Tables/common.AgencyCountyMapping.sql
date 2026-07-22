CREATE TABLE [common].[AgencyCountyMapping]
(
[Id] [uniqueidentifier] NOT NULL,
[AgencyId] [uniqueidentifier] NOT NULL,
[CountyId] [uniqueidentifier] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_AgencyCountyMapping_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_AgencyCountyMapping_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[AgencyCountyMapping] ADD CONSTRAINT [PK_AgencyCountyMapping_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [common].[AgencyCountyMapping] ADD CONSTRAINT [UQ_AgencyCountyMapping_CountyId_AgencyId] UNIQUE NONCLUSTERED ([CountyId], [AgencyId]) ON [PRIMARY]
GO
ALTER TABLE [common].[AgencyCountyMapping] ADD CONSTRAINT [FK_AgencyCountyMapping_Agency] FOREIGN KEY ([AgencyId]) REFERENCES [common].[Agency] ([Id])
GO
ALTER TABLE [common].[AgencyCountyMapping] ADD CONSTRAINT [FK_AgencyCountyMapping_County] FOREIGN KEY ([CountyId]) REFERENCES [common].[County] ([Id])
GO
