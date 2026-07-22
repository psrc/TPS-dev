CREATE TABLE [forms].[FormField]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormField_Id] DEFAULT (newid()),
[FormSectionId] [uniqueidentifier] NOT NULL,
[FormTemplateId] [uniqueidentifier] NOT NULL,
[FormFieldTypeId] [uniqueidentifier] NOT NULL,
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Label] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[HelpText] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsRequired] [bit] NOT NULL CONSTRAINT [DF_FormField_IsRequired] DEFAULT ((0)),
[SortOrder] [int] NOT NULL CONSTRAINT [DF_FormField_SortOrder] DEFAULT ((0)),
[SettingsJson] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormField_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormField_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormField] ADD CONSTRAINT [PK_FormField] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormField_FormSectionId] ON [forms].[FormField] ([FormSectionId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormField_FormTemplateId] ON [forms].[FormField] ([FormTemplateId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormField] ADD CONSTRAINT [UQ_FormField_FormTemplate_Code] UNIQUE NONCLUSTERED ([FormTemplateId], [Code]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormField] ADD CONSTRAINT [FK_FormField_FormFieldType] FOREIGN KEY ([FormFieldTypeId]) REFERENCES [forms].[FormFieldType] ([Id])
GO
ALTER TABLE [forms].[FormField] ADD CONSTRAINT [FK_FormField_FormSection] FOREIGN KEY ([FormSectionId]) REFERENCES [forms].[FormSection] ([Id]) ON DELETE CASCADE
GO
ALTER TABLE [forms].[FormField] ADD CONSTRAINT [FK_FormField_FormTemplate] FOREIGN KEY ([FormTemplateId]) REFERENCES [forms].[FormTemplate] ([Id])
GO
