CREATE TABLE [tip].[AmendmentSectionType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__AmendmentSec__Id__0B3292B8] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsBoardReviewedFlag] [bit] NULL CONSTRAINT [DF__Amendment__IsBoa__0C26B6F1] DEFAULT ((0)),
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Amendment__Creat__0D1ADB2A] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Amendment__Creat__0E0EFF63] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[AmendmentSectionType] ADD CONSTRAINT [PK_AmendmentSectionType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
