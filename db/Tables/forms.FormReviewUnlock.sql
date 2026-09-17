CREATE TABLE [forms].[FormReviewUnlock]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormReviewUnlock_Id] DEFAULT (newid()),
[FormReviewRoundId] [uniqueidentifier] NOT NULL,
[FormFieldId] [uniqueidentifier] NOT NULL,
[AgencyId] [uniqueidentifier] NOT NULL,
[UnlockedById] [uniqueidentifier] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormReviewUnlock_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormReviewUnlock] ADD CONSTRAINT [PK_FormReviewUnlock] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormReviewUnlock_AgencyId] ON [forms].[FormReviewUnlock] ([AgencyId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormReviewUnlock] ADD CONSTRAINT [UQ_FormReviewUnlock_Round_Field] UNIQUE NONCLUSTERED ([FormReviewRoundId], [FormFieldId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormReviewUnlock] ADD CONSTRAINT [FK_FormReviewUnlock_FormField] FOREIGN KEY ([FormFieldId]) REFERENCES [forms].[FormField] ([Id])
GO
ALTER TABLE [forms].[FormReviewUnlock] ADD CONSTRAINT [FK_FormReviewUnlock_FormReviewRound] FOREIGN KEY ([FormReviewRoundId]) REFERENCES [forms].[FormReviewRound] ([Id]) ON DELETE CASCADE
GO
