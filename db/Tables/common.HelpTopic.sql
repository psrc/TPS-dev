CREATE TABLE [common].[HelpTopic]
(
[Id] [uniqueidentifier] NOT NULL,
[HelpSectionId] [uniqueidentifier] NOT NULL,
[Title] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Url] [nvarchar] (2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AccessCount] [int] NOT NULL CONSTRAINT [DF_HelpTopic_AccessCount] DEFAULT ((0)),
[SortId] [int] NOT NULL CONSTRAINT [DF_HelpTopic_SortId] DEFAULT ((0)),
[IsSystem] [bit] NOT NULL CONSTRAINT [DF_HelpTopic_IsSystem] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_HelpTopic_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[StorageKey] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OriginalFileName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ContentType] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Extension] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SizeBytes] [bigint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[HelpTopic] ADD CONSTRAINT [CK_HelpTopic_LinkOrDocument] CHECK (([Url] IS NOT NULL AND [StorageKey] IS NULL OR [Url] IS NULL AND [StorageKey] IS NOT NULL))
GO
ALTER TABLE [common].[HelpTopic] ADD CONSTRAINT [PK_HelpTopic] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_HelpTopic_HelpSectionId] ON [common].[HelpTopic] ([HelpSectionId]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_HelpTopic_StorageKey] ON [common].[HelpTopic] ([StorageKey]) WHERE ([StorageKey] IS NOT NULL) ON [PRIMARY]
GO
ALTER TABLE [common].[HelpTopic] ADD CONSTRAINT [FK_HelpTopic_HelpSection] FOREIGN KEY ([HelpSectionId]) REFERENCES [common].[HelpSection] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'A help topic (an outbound link) belonging to a HelpSection. Topics are ordered by SortId, carry an AccessCount incremented when opened, and may be protected from deletion (IsSystem, e.g. the User Guide topic).', 'SCHEMA', N'common', 'TABLE', N'HelpTopic', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Running count of how often the topic has been opened; surfaced to administrators for content curation.', 'SCHEMA', N'common', 'TABLE', N'HelpTopic', 'COLUMN', N'AccessCount'
GO
EXEC sp_addextendedproperty N'MS_Description', N'Destination URL opened when the topic is selected on the public Help Center.', 'SCHEMA', N'common', 'TABLE', N'HelpTopic', 'COLUMN', N'Url'
GO
