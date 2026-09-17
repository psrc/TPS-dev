CREATE TABLE [forms].[FormResponseFile]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormResponseFile_Id] DEFAULT (newid()),
[FormAssignmentId] [uniqueidentifier] NOT NULL,
[FormFieldId] [uniqueidentifier] NOT NULL,
[AgencyId] [uniqueidentifier] NOT NULL,
[StorageKey] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OriginalFileName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ContentType] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Extension] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SizeBytes] [bigint] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormResponseFile_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormResponseFile] ADD CONSTRAINT [PK_FormResponseFile] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormResponseFile_AgencyId] ON [forms].[FormResponseFile] ([AgencyId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormResponseFile_Assignment_Field] ON [forms].[FormResponseFile] ([FormAssignmentId], [FormFieldId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormResponseFile] ADD CONSTRAINT [UQ_FormResponseFile_StorageKey] UNIQUE NONCLUSTERED ([StorageKey]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormResponseFile] ADD CONSTRAINT [FK_FormResponseFile_FormAssignment] FOREIGN KEY ([FormAssignmentId]) REFERENCES [forms].[FormAssignment] ([Id]) ON DELETE CASCADE
GO
ALTER TABLE [forms].[FormResponseFile] ADD CONSTRAINT [FK_FormResponseFile_FormField] FOREIGN KEY ([FormFieldId]) REFERENCES [forms].[FormField] ([Id])
GO
