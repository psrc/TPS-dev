CREATE TABLE [reporting].[ReportGroup]
(
[Id] [uniqueidentifier] NOT NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SortId] [int] NOT NULL,
[IsActive] [bit] NOT NULL CONSTRAINT [DF__ReportGro__IsAct__4EB3945D] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ReportGro__Creat__4FA7B896] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__ReportGro__Creat__509BDCCF] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [reporting].[ReportGroup] ADD CONSTRAINT [PK_ReportGroup] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
