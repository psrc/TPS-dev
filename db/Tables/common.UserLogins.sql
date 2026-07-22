CREATE TABLE [common].[UserLogins]
(
[LoginProvider] [nvarchar] (450) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ProviderKey] [nvarchar] (450) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ProviderDisplayName] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserId] [uniqueidentifier] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[UserLogins] ADD CONSTRAINT [PK_identity_UserLogins] PRIMARY KEY CLUSTERED ([LoginProvider], [ProviderKey]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_UserLogins_UserId] ON [common].[UserLogins] ([UserId]) ON [PRIMARY]
GO
ALTER TABLE [common].[UserLogins] ADD CONSTRAINT [FK_UserLogins_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [common].[Users] ([Id]) ON DELETE CASCADE
GO
