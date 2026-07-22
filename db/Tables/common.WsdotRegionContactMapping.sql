CREATE TABLE [common].[WsdotRegionContactMapping]
(
[Id] [uniqueidentifier] NOT NULL,
[WsdotRegionId] [uniqueidentifier] NOT NULL,
[ContactId] [uniqueidentifier] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_WsdotRegionContactMapping_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_WsdotRegionContactMapping_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[WsdotRegionContactMapping] ADD CONSTRAINT [PK_WsdotRegionContactMapping_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [common].[WsdotRegionContactMapping] ADD CONSTRAINT [UQ_WsdotRegionContactMapping_WsdotRegionId_ContactId] UNIQUE NONCLUSTERED ([WsdotRegionId], [ContactId]) ON [PRIMARY]
GO
ALTER TABLE [common].[WsdotRegionContactMapping] ADD CONSTRAINT [FK_WsdotRegionContactMapping_Contact] FOREIGN KEY ([ContactId]) REFERENCES [common].[Contact] ([Id])
GO
ALTER TABLE [common].[WsdotRegionContactMapping] ADD CONSTRAINT [FK_WsdotRegionContactMapping_WsdotRegion] FOREIGN KEY ([WsdotRegionId]) REFERENCES [common].[WsdotRegion] ([Id])
GO
