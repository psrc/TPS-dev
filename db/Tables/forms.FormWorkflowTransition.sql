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
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[ProcedureName] [nvarchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ClearsHiddenAnswers] [bit] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_Clear] DEFAULT ((0)),
[RequiresCompleteReview] [bit] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_RequiresCompleteReview] DEFAULT ((0)),
[BlockedByAnyRejection] [bit] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_BlockedByAnyRejection] DEFAULT ((0)),
[RequiresAtLeastOneRejection] [bit] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_RequiresAtLeastOneRejection] DEFAULT ((0)),
[EmailTemplateId] [uniqueidentifier] NULL,
[EmailRecipientsJson] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RequiresReviewAddressed] [bit] NOT NULL CONSTRAINT [DF_FormWorkflowTransition_RequiresReviewAddressed] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [CK_FormWorkflowTransition_Recipients_IsJson] CHECK (([EmailRecipientsJson] IS NULL OR isjson([EmailRecipientsJson])=(1)))
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [CK_FormWorkflowTransition_RejectionGuards] CHECK (([BlockedByAnyRejection]=(0) OR [RequiresAtLeastOneRejection]=(0)))
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [CK_FormWorkflowTransition_Roles_IsJson] CHECK ((isjson([RolesJson])=(1)))
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [PK_FormWorkflowTransition] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormWorkflowTransition_Template_From] ON [forms].[FormWorkflowTransition] ([FormTemplateId], [FromStatusTypeId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [FK_FormWorkflowTransition_EmailTemplate] FOREIGN KEY ([EmailTemplateId]) REFERENCES [common].[EmailTemplate] ([Id])
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [FK_FormWorkflowTransition_FormTemplate] FOREIGN KEY ([FormTemplateId]) REFERENCES [forms].[FormTemplate] ([Id]) ON DELETE CASCADE
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [FK_FormWorkflowTransition_FromStatus] FOREIGN KEY ([FromStatusTypeId]) REFERENCES [forms].[FormStatusType] ([Id])
GO
ALTER TABLE [forms].[FormWorkflowTransition] ADD CONSTRAINT [FK_FormWorkflowTransition_ToStatus] FOREIGN KEY ([ToStatusTypeId]) REFERENCES [forms].[FormStatusType] ([Id])
GO
