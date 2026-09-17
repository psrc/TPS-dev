CREATE TABLE [forms].[FormReviewItem]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormReviewItem_Id] DEFAULT (newid()),
[FormReviewRoundId] [uniqueidentifier] NOT NULL,
[FormFieldId] [uniqueidentifier] NOT NULL,
[AgencyId] [uniqueidentifier] NOT NULL,
[Decision] [nvarchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_FormReviewItem_Decision] DEFAULT ('Pending'),
[ExternalComment] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AnswerSnapshotJson] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormReviewItem_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[DecidedById] [uniqueidentifier] NULL,
[DecidedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormReviewItem] ADD CONSTRAINT [CK_FormReviewItem_Decision] CHECK (([Decision]='Rejected' OR [Decision]='Accepted' OR [Decision]='Pending'))
GO
ALTER TABLE [forms].[FormReviewItem] ADD CONSTRAINT [PK_FormReviewItem] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormReviewItem_AgencyId] ON [forms].[FormReviewItem] ([AgencyId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormReviewItem] ADD CONSTRAINT [UQ_FormReviewItem_Round_Field] UNIQUE NONCLUSTERED ([FormReviewRoundId], [FormFieldId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormReviewItem] ADD CONSTRAINT [FK_FormReviewItem_FormField] FOREIGN KEY ([FormFieldId]) REFERENCES [forms].[FormField] ([Id])
GO
ALTER TABLE [forms].[FormReviewItem] ADD CONSTRAINT [FK_FormReviewItem_FormReviewRound] FOREIGN KEY ([FormReviewRoundId]) REFERENCES [forms].[FormReviewRound] ([Id]) ON DELETE CASCADE
GO
