CREATE TABLE [forms].[FormWorkflowStateLockedSection]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormWorkflowStateLockedSection_Id] DEFAULT (newid()),
[FormWorkflowStateId] [uniqueidentifier] NOT NULL,
[FormSectionId] [uniqueidentifier] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormWorkflowStateLockedSection_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormWorkflowStateLockedSection] ADD CONSTRAINT [PK_FormWorkflowStateLockedSection] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormWorkflowStateLockedSection_FormSectionId] ON [forms].[FormWorkflowStateLockedSection] ([FormSectionId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormWorkflowStateLockedSection] ADD CONSTRAINT [UQ_FormWorkflowStateLockedSection_State_Section] UNIQUE NONCLUSTERED ([FormWorkflowStateId], [FormSectionId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormWorkflowStateLockedSection] ADD CONSTRAINT [FK_FormWorkflowStateLockedSection_FormSection] FOREIGN KEY ([FormSectionId]) REFERENCES [forms].[FormSection] ([Id])
GO
ALTER TABLE [forms].[FormWorkflowStateLockedSection] ADD CONSTRAINT [FK_FormWorkflowStateLockedSection_FormWorkflowState] FOREIGN KEY ([FormWorkflowStateId]) REFERENCES [forms].[FormWorkflowState] ([Id]) ON DELETE CASCADE
GO
