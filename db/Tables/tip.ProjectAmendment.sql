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
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__ProjectAm__Creat__66C02818] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
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
