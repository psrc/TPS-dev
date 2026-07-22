CREATE TABLE [forms].[FormSection]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormSection_Id] DEFAULT (newid()),
[FormTemplateId] [uniqueidentifier] NOT NULL,
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Title] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortOrder] [int] NOT NULL CONSTRAINT [DF_FormSection_SortOrder] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormSection_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormSection_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormSection] ADD CONSTRAINT [PK_FormSection] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormSection_FormTemplateId] ON [forms].[FormSection] ([FormTemplateId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormSection] ADD CONSTRAINT [UQ_FormSection_FormTemplate_Code] UNIQUE NONCLUSTERED ([FormTemplateId], [Code]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormSection] ADD CONSTRAINT [FK_FormSection_FormTemplate] FOREIGN KEY ([FormTemplateId]) REFERENCES [forms].[FormTemplate] ([Id]) ON DELETE CASCADE
GO
