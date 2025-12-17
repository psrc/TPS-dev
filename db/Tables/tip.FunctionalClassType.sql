CREATE TABLE [tip].[FunctionalClassType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__FunctionalCl__Id__3AE1A5DA] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Functiona__Creat__3BD5CA13] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Functiona__Creat__3CC9EE4C] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[FunctionalClassType] ADD CONSTRAINT [PK_FunctionalClassType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
