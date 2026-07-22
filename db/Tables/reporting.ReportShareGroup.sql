CREATE TABLE [reporting].[ReportShareGroup]
(
[Id] [uniqueidentifier] NOT NULL,
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NOT NULL,
[IsActive] [bit] NOT NULL CONSTRAINT [DF_ReportShareGroup_IsActive] DEFAULT ((1)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ReportShareGroup_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ReportShareGroup_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [reporting].[ReportShareGroup] ADD CONSTRAINT [PK_ReportShareGroup] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
