CREATE TABLE [tip].[ForumType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ForumType__Id__361CF0BD] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FundFamilyTypeId] [uniqueidentifier] NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ForumType__Creat__371114F6] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__ForumType__Creat__3805392F] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ForumType] ADD CONSTRAINT [PK_Forum] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ForumType] ADD CONSTRAINT [FK_FundFamilyType_ForumType] FOREIGN KEY ([FundFamilyTypeId]) REFERENCES [tip].[FundFamilyType] ([Id])
GO
