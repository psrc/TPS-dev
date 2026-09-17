CREATE TABLE [common].[RefreshSession]
(
[Id] [uniqueidentifier] NOT NULL,
[UserId] [uniqueidentifier] NOT NULL,
[TokenHash] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ExpiresOn] [datetime2] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_RefreshSession_CreatedOn] DEFAULT (getutcdate()),
[RevokedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[RefreshSession] ADD CONSTRAINT [PK_RefreshSession_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_RefreshSession_UserId] ON [common].[RefreshSession] ([UserId]) ON [PRIMARY]
GO
ALTER TABLE [common].[RefreshSession] ADD CONSTRAINT [FK_RefreshSession_Users] FOREIGN KEY ([UserId]) REFERENCES [common].[Users] ([Id]) ON DELETE CASCADE
GO
