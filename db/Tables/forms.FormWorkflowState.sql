CREATE TABLE [forms].[FormWorkflowState]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormWorkflowState_Id] DEFAULT (newid()),
[FormTemplateId] [uniqueidentifier] NOT NULL,
[StatusTypeId] [uniqueidentifier] NOT NULL,
[EditRolesJson] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormWorkflowState_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormWorkflowState_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[IsInitial] [bit] NOT NULL CONSTRAINT [DF_FormWorkflowState_IsInitial] DEFAULT ((0)),
[CanvasX] [int] NULL,
[CanvasY] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormWorkflowState] ADD CONSTRAINT [CK_FormWorkflowState_EditRoles_IsJson] CHECK ((isjson([EditRolesJson])=(1)))
GO
ALTER TABLE [forms].[FormWorkflowState] ADD CONSTRAINT [PK_FormWorkflowState] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_FormWorkflowState_Initial] ON [forms].[FormWorkflowState] ([FormTemplateId]) WHERE ([IsInitial]=(1)) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormWorkflowState] ADD CONSTRAINT [UQ_FormWorkflowState_Template_Status] UNIQUE NONCLUSTERED ([FormTemplateId], [StatusTypeId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormWorkflowState] ADD CONSTRAINT [FK_FormWorkflowState_FormStatusType] FOREIGN KEY ([StatusTypeId]) REFERENCES [forms].[FormStatusType] ([Id])
GO
ALTER TABLE [forms].[FormWorkflowState] ADD CONSTRAINT [FK_FormWorkflowState_FormTemplate] FOREIGN KEY ([FormTemplateId]) REFERENCES [forms].[FormTemplate] ([Id]) ON DELETE CASCADE
GO
