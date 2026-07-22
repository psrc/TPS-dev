CREATE TABLE [forms].[FormStatusType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormStatusType_Id] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormStatusType_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormStatusType_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[DisplayName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[StyleKey] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[IsComplete] [bit] NOT NULL CONSTRAINT [DF_FormStatusType_IsComplete] DEFAULT ((0)),
[IsSystem] [bit] NOT NULL CONSTRAINT [DF_FormStatusType_IsSystem] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormStatusType] ADD CONSTRAINT [PK_FormStatusType] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormStatusType] ADD CONSTRAINT [UQ_FormStatusType_Code] UNIQUE NONCLUSTERED ([Code]) ON [PRIMARY]
GO
