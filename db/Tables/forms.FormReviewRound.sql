CREATE TABLE [forms].[FormReviewRound]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormReviewRound_Id] DEFAULT (newid()),
[FormAssignmentId] [uniqueidentifier] NOT NULL,
[AgencyId] [uniqueidentifier] NOT NULL,
[RoundNumber] [int] NOT NULL,
[OpenedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormReviewRound_OpenedOn] DEFAULT (getutcdate()),
[OpenedById] [uniqueidentifier] NOT NULL,
[ReleasedOn] [datetime2] NULL,
[ReleasedById] [uniqueidentifier] NULL,
[FormComment] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormReviewRound_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[InternalComment] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormReviewRound] ADD CONSTRAINT [PK_FormReviewRound] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormReviewRound_AgencyId] ON [forms].[FormReviewRound] ([AgencyId]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_FormReviewRound_OneOpenPerAssignment] ON [forms].[FormReviewRound] ([FormAssignmentId]) WHERE ([ReleasedOn] IS NULL) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormReviewRound] ADD CONSTRAINT [UQ_FormReviewRound_Assignment_Round] UNIQUE NONCLUSTERED ([FormAssignmentId], [RoundNumber]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormReviewRound] ADD CONSTRAINT [FK_FormReviewRound_FormAssignment] FOREIGN KEY ([FormAssignmentId]) REFERENCES [forms].[FormAssignment] ([Id]) ON DELETE CASCADE
GO
