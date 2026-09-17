CREATE TABLE [forms].[SkipRule]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SkipRule_Id] DEFAULT (newid()),
[FormTemplateId] [uniqueidentifier] NOT NULL,
[TargetFormFieldId] [uniqueidentifier] NULL,
[TargetFormSectionId] [uniqueidentifier] NULL,
[Action] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Match] [nvarchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ElseBehavior] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SortOrder] [int] NOT NULL CONSTRAINT [DF_SkipRule_SortOrder] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_SkipRule_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[SkipRule] ADD CONSTRAINT [CK_SkipRule_OneTarget] CHECK (([TargetFormFieldId] IS NOT NULL AND [TargetFormSectionId] IS NULL OR [TargetFormFieldId] IS NULL AND [TargetFormSectionId] IS NOT NULL))
GO
ALTER TABLE [forms].[SkipRule] ADD CONSTRAINT [PK_SkipRule] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_SkipRule_FormTemplateId] ON [forms].[SkipRule] ([FormTemplateId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[SkipRule] ADD CONSTRAINT [FK_SkipRule_FormTemplate] FOREIGN KEY ([FormTemplateId]) REFERENCES [forms].[FormTemplate] ([Id])
GO
ALTER TABLE [forms].[SkipRule] ADD CONSTRAINT [FK_SkipRule_TargetFormField] FOREIGN KEY ([TargetFormFieldId]) REFERENCES [forms].[FormField] ([Id])
GO
ALTER TABLE [forms].[SkipRule] ADD CONSTRAINT [FK_SkipRule_TargetFormSection] FOREIGN KEY ([TargetFormSectionId]) REFERENCES [forms].[FormSection] ([Id])
GO
