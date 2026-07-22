CREATE TABLE [reporting].[ApprovedReportSource]
(
[Id] [uniqueidentifier] NOT NULL,
[SourceName] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SourceType] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ApprovedReportSource_SourceType] DEFAULT ('VIEW'),
[SchemaName] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_ApprovedReportSource_SchemaName] DEFAULT ('reporting'),
[Description] [nvarchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NOT NULL CONSTRAINT [DF_ApprovedReportSource_IsActive] DEFAULT ((1)),
[SortId] [int] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ApprovedReportSource_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ApprovedReportSource_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [reporting].[ApprovedReportSource] ADD CONSTRAINT [PK_ApprovedReportSource] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
