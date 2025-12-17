CREATE TABLE [tip].[ProjectAmendmentReviewStatusType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ProjectAmend__Id__7F8BD5E2] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ProjectAm__Creat__007FFA1B] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__ProjectAm__Creat__01741E54] DEFAULT (getutcdate()),
[UpdateById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectAmendmentReviewStatusType] ADD CONSTRAINT [PK_ProjectAmendmentReviewStatusType] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
