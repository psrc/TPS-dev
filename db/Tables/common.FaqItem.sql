CREATE TABLE [common].[FaqItem]
(
[Id] [uniqueidentifier] NOT NULL,
[FaqCategoryId] [uniqueidentifier] NOT NULL,
[Question] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Answer] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[HelpfulYes] [int] NOT NULL CONSTRAINT [DF_FaqItem_HelpfulYes] DEFAULT ((0)),
[HelpfulNo] [int] NOT NULL CONSTRAINT [DF_FaqItem_HelpfulNo] DEFAULT ((0)),
[SortId] [int] NOT NULL CONSTRAINT [DF_FaqItem_SortId] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FaqItem_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FaqItem_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[FaqItem] ADD CONSTRAINT [PK_FaqItem] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FaqItem_FaqCategoryId] ON [common].[FaqItem] ([FaqCategoryId]) ON [PRIMARY]
GO
ALTER TABLE [common].[FaqItem] ADD CONSTRAINT [FK_FaqItem_FaqCategory] FOREIGN KEY ([FaqCategoryId]) REFERENCES [common].[FaqCategory] ([Id])
GO
EXEC sp_addextendedproperty N'MS_Description', N'A FAQ question/answer item belonging to a FaqCategory. Answer is plain text. HelpfulYes/HelpfulNo are denormalized running vote totals kept in sync with common.FaqVote. Items are ordered by SortId.', 'SCHEMA', N'common', 'TABLE', N'FaqItem', NULL, NULL
GO
