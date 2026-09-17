CREATE TABLE [forms].[SkipRuleCondition]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SkipRuleCondition_Id] DEFAULT (newid()),
[SkipRuleId] [uniqueidentifier] NOT NULL,
[TriggerFormFieldId] [uniqueidentifier] NULL,
[Operator] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ValuesJson] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SortOrder] [int] NOT NULL CONSTRAINT [DF_SkipRuleCondition_SortOrder] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_SkipRuleCondition_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[TriggerKind] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_SkipRuleCondition_TriggerKind] DEFAULT ('Field')
) ON [PRIMARY]
GO
ALTER TABLE [forms].[SkipRuleCondition] ADD CONSTRAINT [CK_SkipRuleCondition_OneTrigger] CHECK (([TriggerKind]='Field' AND [TriggerFormFieldId] IS NOT NULL OR [TriggerKind]='Status' AND [TriggerFormFieldId] IS NULL))
GO
ALTER TABLE [forms].[SkipRuleCondition] ADD CONSTRAINT [PK_SkipRuleCondition] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_SkipRuleCondition_SkipRuleId] ON [forms].[SkipRuleCondition] ([SkipRuleId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[SkipRuleCondition] ADD CONSTRAINT [FK_SkipRuleCondition_SkipRule] FOREIGN KEY ([SkipRuleId]) REFERENCES [forms].[SkipRule] ([Id]) ON DELETE CASCADE
GO
ALTER TABLE [forms].[SkipRuleCondition] ADD CONSTRAINT [FK_SkipRuleCondition_TriggerFormField] FOREIGN KEY ([TriggerFormFieldId]) REFERENCES [forms].[FormField] ([Id])
GO
