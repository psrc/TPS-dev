CREATE TABLE [tip].[FinancialSummaryGroupType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__FinancialSum__Id__31583BA0] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Financial__Creat__324C5FD9] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Financial__Creat__33408412] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[FinancialSummaryGroupType] ADD CONSTRAINT [PK_FinancialSummaryGroupType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
