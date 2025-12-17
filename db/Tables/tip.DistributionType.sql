CREATE TABLE [tip].[DistributionType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Distribution__Id__27CED166] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Distribut__Creat__28C2F59F] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Distribut__Creat__29B719D8] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[DistributionType] ADD CONSTRAINT [PK_DistributionType] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
