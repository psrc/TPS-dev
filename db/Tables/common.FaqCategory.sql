CREATE TABLE [common].[FaqCategory]
(
[Id] [uniqueidentifier] NOT NULL,
[Name] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SortId] [int] NOT NULL CONSTRAINT [DF_FaqCategory_SortId] DEFAULT ((0)),
[IsHidden] [bit] NOT NULL CONSTRAINT [DF_FaqCategory_IsHidden] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FaqCategory_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FaqCategory_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[FaqCategory] ADD CONSTRAINT [PK_FaqCategory] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'A category that groups related FAQ items on the public FAQ page. Categories are ordered by SortId and can be hidden from the public page (IsHidden).', 'SCHEMA', N'common', 'TABLE', N'FaqCategory', NULL, NULL
GO
