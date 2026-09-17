CREATE TABLE [common].[FaqItemFile]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FaqItemFile_Id] DEFAULT (newid()),
[FaqItemId] [uniqueidentifier] NOT NULL,
[StorageKey] [nvarchar] (1024) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OriginalFileName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ContentType] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Extension] [nvarchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SizeBytes] [bigint] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FaqItemFile_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[FaqItemFile] ADD CONSTRAINT [PK_FaqItemFile] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FaqItemFile_FaqItemId] ON [common].[FaqItemFile] ([FaqItemId]) ON [PRIMARY]
GO
ALTER TABLE [common].[FaqItemFile] ADD CONSTRAINT [UQ_FaqItemFile_StorageKey] UNIQUE NONCLUSTERED ([StorageKey]) ON [PRIMARY]
GO
ALTER TABLE [common].[FaqItemFile] ADD CONSTRAINT [FK_FaqItemFile_FaqItem] FOREIGN KEY ([FaqItemId]) REFERENCES [common].[FaqItem] ([Id]) ON DELETE CASCADE
GO
