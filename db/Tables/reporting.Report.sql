CREATE TABLE [reporting].[Report]
(
[Id] [uniqueidentifier] NOT NULL,
[ReportGroupId] [uniqueidentifier] NOT NULL,
[Name] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ReportTypeId] [uniqueidentifier] NOT NULL,
[ReportSource] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SourceOptions] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ReportDefinitionXml] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NOT NULL,
[IsActive] [bit] NOT NULL CONSTRAINT [DF_Report_IsActive] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Report_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_Report_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [reporting].[Report] ADD CONSTRAINT [PK_Report] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [reporting].[Report] ADD CONSTRAINT [FK_Report_ReportGroup] FOREIGN KEY ([ReportGroupId]) REFERENCES [reporting].[ReportGroup] ([Id])
GO
ALTER TABLE [reporting].[Report] ADD CONSTRAINT [FK_Report_ReportType] FOREIGN KEY ([ReportTypeId]) REFERENCES [reporting].[ReportType] ([Id])
GO
