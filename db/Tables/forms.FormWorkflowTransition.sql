CREATE TABLE [forms].[FormWorkflowTransition]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_Id] DEFAULT (newid()),
[FormTemplateId] [uniqueidentifier] NOT NULL,
[FromStatusTypeId] [uniqueidentifier] NOT NULL,
[ToStatusTypeId] [uniqueidentifier] NOT NULL,
[RolesJson] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ButtonLabel] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortOrder] [int] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_SortOrder] DEFAULT ((0)),
[RequiresCompleteResponses] [bit] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_Guard] DEFAULT ((0)),
[IsAutomatic] [bit] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_Auto] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[SendEmail] [bit] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_SendEmail] DEFAULT ((0)),
[EmailRecipient] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ProcedureName] [nvarchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [CK_FormWorkflowTransition_Roles_IsJson] CHECK ((isjson([RolesJson])=(1)))
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [PK_FormWorkflowTransition] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormWorkflowTransition_Template_From] ON [forms].[FormWorkflowTransition] ([FormTemplateId], [FromStatusTypeId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [FK_FormWorkflowTransition_FormTemplate] FOREIGN KEY ([FormTemplateId]) REFERENCES [forms].[FormTemplate] ([Id]) ON DELETE CASCADE
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [FK_FormWorkflowTransition_FromStatus] FOREIGN KEY ([FromStatusTypeId]) REFERENCES [forms].[FormStatusType] ([Id])
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [FK_FormWorkflowTransition_ToStatus] FOREIGN KEY ([ToStatusTypeId]) REFERENCES [forms].[FormStatusType] ([Id])
GO
