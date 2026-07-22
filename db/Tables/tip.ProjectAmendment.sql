CREATE TABLE [tip].[ProjectAmendment]
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectId] [uniqueidentifier] NOT NULL,
[AmendmentId] [uniqueidentifier] NOT NULL,
[AmendmentSectionTypeId] [uniqueidentifier] NOT NULL,
[ProjectAmendmentReviewStatusTypeId] [uniqueidentifier] NOT NULL,
[SponsorComments] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PsrcComments] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReviewUpdatedById] [uniqueidentifier] NULL,
[ReviewUpdateDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ProjectAmendment_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[ReportDescription] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReportProjectTrackingFlag] [bit] NOT NULL CONSTRAINT [DF_ProjectAmendment_ReportProjectTrackingFlag] DEFAULT ((0)),
[ReportNewProjectPhaseFlag] [bit] NOT NULL CONSTRAINT [DF_ProjectAmendment_ReportNewProjectPhaseFlag] DEFAULT ((0)),
[ReportUpwpFlag] [bit] NOT NULL CONSTRAINT [DF_ProjectAmendment_ReportUpwpFlag] DEFAULT ((0)),
[ReportOtherAmendFlag] [bit] NOT NULL CONSTRAINT [DF_ProjectAmendment_ReportOtherAmendFlag] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectAmendment] ADD CONSTRAINT [PK_ProjectAmendment_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectAmendment] ADD CONSTRAINT [FK_ProjectAmendment_Amendment] FOREIGN KEY ([AmendmentId]) REFERENCES [tip].[Amendment] ([Id])
GO
ALTER TABLE [tip].[ProjectAmendment] ADD CONSTRAINT [FK_ProjectAmendment_AmendmentSectionType] FOREIGN KEY ([AmendmentSectionTypeId]) REFERENCES [tip].[AmendmentSectionType] ([Id])
GO
ALTER TABLE [tip].[ProjectAmendment] ADD CONSTRAINT [FK_ProjectAmendment_Project] FOREIGN KEY ([ProjectId]) REFERENCES [tip].[Project] ([Id])
GO
ALTER TABLE [tip].[ProjectAmendment] ADD CONSTRAINT [FK_ProjectAmendment_ProjectAmendmentReviewStatusType] FOREIGN KEY ([ProjectAmendmentReviewStatusTypeId]) REFERENCES [tip].[ProjectAmendmentReviewStatusType] ([Id])
GO
