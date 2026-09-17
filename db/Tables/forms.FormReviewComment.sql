CREATE TABLE [forms].[FormReviewComment]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormReviewComment_Id] DEFAULT (newid()),
[FormReviewItemId] [uniqueidentifier] NOT NULL,
[AgencyId] [uniqueidentifier] NOT NULL,
[AuthorUserId] [uniqueidentifier] NOT NULL,
[AuthorName] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Body] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormReviewComment_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormReviewComment] ADD CONSTRAINT [PK_FormReviewComment] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormReviewComment_AgencyId] ON [forms].[FormReviewComment] ([AgencyId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormReviewComment_FormReviewItemId] ON [forms].[FormReviewComment] ([FormReviewItemId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormReviewComment] ADD CONSTRAINT [FK_FormReviewComment_FormReviewItem] FOREIGN KEY ([FormReviewItemId]) REFERENCES [forms].[FormReviewItem] ([Id]) ON DELETE CASCADE
GO
