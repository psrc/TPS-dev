CREATE TABLE [forms].[FormTemplateStatusType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormTemplateStatusType_Id] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormTemplateStatusType_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormTemplateStatusType_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormTemplateStatusType] ADD CONSTRAINT [PK_FormTemplateStatusType] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormTemplateStatusType] ADD CONSTRAINT [UQ_FormTemplateStatusType_Code] UNIQUE NONCLUSTERED ([Code]) ON [PRIMARY]
GO
