CREATE TABLE [tip].[ProjectAmendmentReviewAreaStatusType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ProjectAmend__Id__76026BA8] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ProjectAm__Creat__76F68FE1] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__ProjectAm__Creat__77EAB41A] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectAmendmentReviewAreaStatusType] ADD CONSTRAINT [PK_ProjectAmendmentReviewAreaStatusType] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
