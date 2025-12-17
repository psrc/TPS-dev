CREATE TABLE [tip].[FundFamilyType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__FundFamilyTy__Id__3FA65AF7] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__FundFamil__Creat__409A7F30] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__FundFamil__Creat__418EA369] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[FundFamilyType] ADD CONSTRAINT [PK_FundFamilyType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
