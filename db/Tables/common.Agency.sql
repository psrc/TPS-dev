CREATE TABLE [common].[Agency]
(
[Id] [uniqueidentifier] NOT NULL,
[AgencyTypeId] [uniqueidentifier] NULL,
[Name] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ShortName] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProjectNamePrefix] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WsdotName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[WsdotCountyId] [uniqueidentifier] NULL,
[WsdotRegionId] [uniqueidentifier] NULL,
[AppendixAGroup] [smallint] NULL,
[PlaceAggregated] [nvarchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Agency__CreatedB__6F8A7843] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Agency__CreatedO__707E9C7C] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[Agency] ADD CONSTRAINT [PK_Agency_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [common].[Agency] ADD CONSTRAINT [FK_Agency_AgencyType] FOREIGN KEY ([AgencyTypeId]) REFERENCES [common].[AgencyType] ([Id])
GO
ALTER TABLE [common].[Agency] ADD CONSTRAINT [FK_Agency_WsdotRegion] FOREIGN KEY ([WsdotRegionId]) REFERENCES [common].[WsdotRegion] ([Id])
GO
