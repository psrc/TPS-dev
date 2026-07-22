CREATE TABLE [tip].[FundingSourceType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FundingSourceType_Id] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[GovernmentLevel] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[STIPFundCode] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FinancialSummaryGroupTypeId] [uniqueidentifier] NULL,
[FinancialSummarySortId] [int] NULL,
[FundFamilyTypeId] [uniqueidentifier] NULL,
[GenericFundCodeGroup] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FundingSourceType_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FundingSourceType_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[FundingSourceType] ADD CONSTRAINT [PK_FundingSourceType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[FundingSourceType] ADD CONSTRAINT [FK_FundingSourceType_FinancialSummaryGroupType] FOREIGN KEY ([FinancialSummaryGroupTypeId]) REFERENCES [tip].[FinancialSummaryGroupType] ([Id])
GO
ALTER TABLE [tip].[FundingSourceType] ADD CONSTRAINT [FK_FundingSourceType_FundFamilyType] FOREIGN KEY ([FundFamilyTypeId]) REFERENCES [tip].[FundFamilyType] ([Id])
GO
