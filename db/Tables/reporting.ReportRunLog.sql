CREATE TABLE [reporting].[ReportRunLog]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ReportRunLog_Id] DEFAULT (newid()),
[ReportId] [uniqueidentifier] NOT NULL,
[UserId] [uniqueidentifier] NOT NULL,
[StartedAt] [datetime2] NOT NULL,
[CompletedAt] [datetime2] NULL,
[DurationMs] [int] NULL,
[Status] [int] NOT NULL,
[RowCount] [int] NULL,
[ExportType] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ErrorCode] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ReportRunLog_CreatedOn] DEFAULT (getutcdate()),
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [reporting].[ReportRunLog] ADD CONSTRAINT [PK_ReportRunLog] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ReportRunLog_ReportId] ON [reporting].[ReportRunLog] ([ReportId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ReportRunLog_StartedAt] ON [reporting].[ReportRunLog] ([StartedAt] DESC) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ReportRunLog_Status] ON [reporting].[ReportRunLog] ([Status]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ReportRunLog_UserId] ON [reporting].[ReportRunLog] ([UserId]) ON [PRIMARY]
GO
ALTER TABLE [reporting].[ReportRunLog] ADD CONSTRAINT [FK_ReportRunLog_Report] FOREIGN KEY ([ReportId]) REFERENCES [reporting].[Report] ([Id])
GO
