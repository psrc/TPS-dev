CREATE TABLE [tip].[ImprovementType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ImprovementT__Id__492FC531] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[StipImprovementTypeId] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Improveme__Creat__4A23E96A] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Improveme__Creat__4B180DA3] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ImprovementType] ADD CONSTRAINT [PK_ImprovementType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
