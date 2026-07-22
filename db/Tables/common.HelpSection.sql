CREATE TABLE [common].[HelpSection]
(
[Id] [uniqueidentifier] NOT NULL,
[Name] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Icon] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NOT NULL CONSTRAINT [DF_HelpSection_SortId] DEFAULT ((0)),
[IsHidden] [bit] NOT NULL CONSTRAINT [DF_HelpSection_IsHidden] DEFAULT ((0)),
[IsSystem] [bit] NOT NULL CONSTRAINT [DF_HelpSection_IsSystem] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_HelpSection_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_HelpSection_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[HelpSection] ADD CONSTRAINT [PK_HelpSection] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'A Help Center section that groups related help topics on the public Help page. Sections are ordered by SortId, can be hidden from the public page (IsHidden), and may be protected from deletion (IsSystem, e.g. the User Guide section).', 'SCHEMA', N'common', 'TABLE', N'HelpSection', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Feather icon name (e.g. book-open) shown next to the section name, rendered via the app-icon component.', 'SCHEMA', N'common', 'TABLE', N'HelpSection', 'COLUMN', N'Icon'
GO
EXEC sp_addextendedproperty N'MS_Description', N'When 1, the section is retained but excluded from the public Help Center.', 'SCHEMA', N'common', 'TABLE', N'HelpSection', 'COLUMN', N'IsHidden'
GO
EXEC sp_addextendedproperty N'MS_Description', N'When 1, the section is protected and cannot be deleted (e.g. the User Guide section).', 'SCHEMA', N'common', 'TABLE', N'HelpSection', 'COLUMN', N'IsSystem'
GO
