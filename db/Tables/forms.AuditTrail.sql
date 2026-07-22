CREATE TABLE [forms].[AuditTrail]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormsAuditTrail_Id] DEFAULT (newid()),
[Timestamp] [datetime2] NOT NULL CONSTRAINT [DF_FormsAuditTrail_Timestamp] DEFAULT (getutcdate()),
[ActorUserId] [uniqueidentifier] NULL,
[ActorName] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ActionType] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TargetEntityType] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[TargetEntityId] [uniqueidentifier] NULL,
[TargetEntityName] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Details] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Outcome] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormsAuditTrail_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormsAuditTrail_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[AuditTrail] ADD CONSTRAINT [PK_FormsAuditTrail] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormsAuditTrail_ActionType] ON [forms].[AuditTrail] ([ActionType]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormsAuditTrail_ActorUserId] ON [forms].[AuditTrail] ([ActorUserId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormsAuditTrail_TargetEntityType] ON [forms].[AuditTrail] ([TargetEntityType]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormsAuditTrail_Timestamp] ON [forms].[AuditTrail] ([Timestamp] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormsAuditTrail_Timestamp_ActionType] ON [forms].[AuditTrail] ([Timestamp] DESC, [ActionType]) ON [PRIMARY]
GO
