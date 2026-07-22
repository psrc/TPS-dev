CREATE TABLE [forms].[FormResponseValue]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormResponseValue_Id] DEFAULT (newid()),
[FormAssignmentId] [uniqueidentifier] NOT NULL,
[FormFieldId] [uniqueidentifier] NOT NULL,
[ValueJson] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ValueText] AS (json_value([ValueJson],'$.v')) PERSISTED,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormResponseValue_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormResponseValue_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormResponseValue] ADD CONSTRAINT [CK_FormResponseValue_ValueJson_IsJson] CHECK ((isjson([ValueJson])=(1)))
GO
ALTER TABLE [forms].[FormResponseValue] ADD CONSTRAINT [PK_FormResponseValue] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormResponseValue] ADD CONSTRAINT [UQ_FormResponseValue_Assignment_Field] UNIQUE NONCLUSTERED ([FormAssignmentId], [FormFieldId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormResponseValue_FormFieldId] ON [forms].[FormResponseValue] ([FormFieldId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormResponseValue] ADD CONSTRAINT [FK_FormResponseValue_FormAssignment] FOREIGN KEY ([FormAssignmentId]) REFERENCES [forms].[FormAssignment] ([Id]) ON DELETE CASCADE
GO
ALTER TABLE [forms].[FormResponseValue] ADD CONSTRAINT [FK_FormResponseValue_FormField] FOREIGN KEY ([FormFieldId]) REFERENCES [forms].[FormField] ([Id])
GO
