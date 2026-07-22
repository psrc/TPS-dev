CREATE TABLE [forms].[FormFieldType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormFieldType_Id] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormFieldType_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormFieldType_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormFieldType] ADD CONSTRAINT [PK_FormFieldType] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormFieldType] ADD CONSTRAINT [UQ_FormFieldType_Code] UNIQUE NONCLUSTERED ([Code]) ON [PRIMARY]
GO
