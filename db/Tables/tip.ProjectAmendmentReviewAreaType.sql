CREATE TABLE [tip].[ProjectAmendmentReviewAreaType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ProjectAmend__Id__7AC720C5] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ProjectAm__Creat__7BBB44FE] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__ProjectAm__Creat__7CAF6937] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectAmendmentReviewAreaType] ADD CONSTRAINT [PK_ProjectAmendmentReviewAreaType] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
