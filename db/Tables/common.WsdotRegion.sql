CREATE TABLE [common].[WsdotRegion]
(
[Id] [uniqueidentifier] NOT NULL,
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Name] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_WsdotRegion_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_WsdotRegion_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[WsdotRegion] ADD CONSTRAINT [PK_WsdotRegion_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
