CREATE TABLE [common].[FaqVote]
(
[Id] [uniqueidentifier] NOT NULL,
[FaqItemId] [uniqueidentifier] NOT NULL,
[UserId] [uniqueidentifier] NOT NULL,
[IsHelpful] [bit] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FaqVote_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FaqVote_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[FaqVote] ADD CONSTRAINT [PK_FaqVote] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_FaqVote_FaqItem_User] ON [common].[FaqVote] ([FaqItemId], [UserId]) ON [PRIMARY]
GO
ALTER TABLE [common].[FaqVote] ADD CONSTRAINT [FK_FaqVote_FaqItem] FOREIGN KEY ([FaqItemId]) REFERENCES [common].[FaqItem] ([Id]) ON DELETE CASCADE
GO
EXEC sp_addextendedproperty N'MS_Description', N'A single user''s helpful/not-helpful vote on a FAQ item. One row per (FaqItemId, UserId) via the unique index UX_FaqVote_FaqItem_User; deleted automatically when the parent FaqItem is removed.', 'SCHEMA', N'common', 'TABLE', N'FaqVote', NULL, NULL
GO
