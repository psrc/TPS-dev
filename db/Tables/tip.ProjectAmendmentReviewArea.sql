CREATE TABLE [tip].[ProjectAmendmentReviewArea]
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectAmendmentId] [uniqueidentifier] NOT NULL,
[ProjectAmendmentReviewAreaTypeId] [uniqueidentifier] NOT NULL,
[ProjectAmendmentReviewAreaStatusTypeId] [uniqueidentifier] NOT NULL,
[ReviewerComments] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FollowUpComments] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ProjectAm__Creat__7231DAC4] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__ProjectAm__Creat__7325FEFD] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectAmendmentReviewArea] ADD CONSTRAINT [PK_ProjectAmendmentReviewArea_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectAmendmentReviewArea] ADD CONSTRAINT [FK_ProjectAmendmentReviewArea_ProjectAmendment] FOREIGN KEY ([ProjectAmendmentId]) REFERENCES [tip].[ProjectAmendment] ([Id])
GO
ALTER TABLE [tip].[ProjectAmendmentReviewArea] ADD CONSTRAINT [FK_ProjectAmendmentReviewArea_ProjectAmendmentReviewAreaStatusType] FOREIGN KEY ([ProjectAmendmentReviewAreaStatusTypeId]) REFERENCES [tip].[ProjectAmendmentReviewAreaStatusType] ([Id])
GO
ALTER TABLE [tip].[ProjectAmendmentReviewArea] ADD CONSTRAINT [FK_ProjectAmendmentReviewArea_ProjectAmendmentReviewAreaType] FOREIGN KEY ([ProjectAmendmentReviewAreaTypeId]) REFERENCES [tip].[ProjectAmendmentReviewAreaType] ([Id])
GO
