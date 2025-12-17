CREATE TABLE [tip].[EnvironmentalStatusType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Environmenta__Id__2C938683] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Environme__Creat__2D87AABC] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Environme__Creat__2E7BCEF5] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[EnvironmentalStatusType] ADD CONSTRAINT [PK_EnvironmentalStatusType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
