CREATE TABLE [reporting].[ReportShareGroupMapping]
(
[Id] [uniqueidentifier] NOT NULL,
[ReportId] [uniqueidentifier] NOT NULL,
[ReportShareGroupId] [uniqueidentifier] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ReportShareGroupMapping_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ReportShareGroupMapping_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [reporting].[ReportShareGroupMapping] ADD CONSTRAINT [PK_ReportShareGroupMapping] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [reporting].[ReportShareGroupMapping] ADD CONSTRAINT [FK_ReportShareGroupMapping_Report] FOREIGN KEY ([ReportId]) REFERENCES [reporting].[Report] ([Id])
GO
ALTER TABLE [reporting].[ReportShareGroupMapping] ADD CONSTRAINT [FK_ReportShareGroupMapping_ReportShareGroup] FOREIGN KEY ([ReportShareGroupId]) REFERENCES [reporting].[ReportShareGroup] ([Id])
GO
