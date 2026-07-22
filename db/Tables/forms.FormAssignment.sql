CREATE TABLE [forms].[FormAssignment]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormAssignment_Id] DEFAULT (newid()),
[FormTemplateId] [uniqueidentifier] NOT NULL,
[AgencyId] [uniqueidentifier] NOT NULL,
[LabelContext] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Year] [int] NOT NULL,
[StatusTypeId] [uniqueidentifier] NOT NULL,
[AssignedById] [uniqueidentifier] NOT NULL,
[AssignedToUserId] [uniqueidentifier] NULL,
[AssignmentDate] [datetime2] NOT NULL CONSTRAINT [DF_FormAssignment_AssignmentDate] DEFAULT (getutcdate()),
[LastUpdated] [datetime2] NOT NULL CONSTRAINT [DF_FormAssignment_LastUpdated] DEFAULT (getutcdate()),
[IsDeleted] [bit] NOT NULL CONSTRAINT [DF_FormAssignment_IsDeleted] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormAssignment_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormAssignment_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormAssignment] ADD CONSTRAINT [PK_FormAssignment] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormAssignment_FormTemplateId_AgencyId] ON [forms].[FormAssignment] ([FormTemplateId], [AgencyId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormAssignment_StatusTypeId] ON [forms].[FormAssignment] ([StatusTypeId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormAssignment_Year_AgencyId_IsDeleted] ON [forms].[FormAssignment] ([Year], [AgencyId], [IsDeleted]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormAssignment_Year_FormTemplateId_IsDeleted] ON [forms].[FormAssignment] ([Year], [FormTemplateId], [IsDeleted]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormAssignment] ADD CONSTRAINT [FK_FormAssignment_Agency] FOREIGN KEY ([AgencyId]) REFERENCES [common].[Agency] ([Id])
GO
ALTER TABLE [forms].[FormAssignment] ADD CONSTRAINT [FK_FormAssignment_FormStatusType] FOREIGN KEY ([StatusTypeId]) REFERENCES [forms].[FormStatusType] ([Id])
GO
ALTER TABLE [forms].[FormAssignment] ADD CONSTRAINT [FK_FormAssignment_FormTemplate] FOREIGN KEY ([FormTemplateId]) REFERENCES [forms].[FormTemplate] ([Id])
GO
