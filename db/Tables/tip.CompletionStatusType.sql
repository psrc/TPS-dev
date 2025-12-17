CREATE TABLE [tip].[CompletionStatusType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__CompletionSt__Id__1A74D648] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Completio__Creat__1B68FA81] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Completio__Creat__1C5D1EBA] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[CompletionStatusType] ADD CONSTRAINT [PK_CompletionStatusType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
