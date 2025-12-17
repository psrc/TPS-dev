CREATE TABLE [tip].[PhaseType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__PhaseType__Id__52B92F6B] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__PhaseType__Creat__53AD53A4] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__PhaseType__Creat__54A177DD] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[PhaseType] ADD CONSTRAINT [PK_PhaseType] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
