CREATE TABLE [common].[UserClaims]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[UserId] [uniqueidentifier] NOT NULL,
[ClaimType] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ClaimValue] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[UserClaims] ADD CONSTRAINT [PK_identity_UserClaims] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_UserClaims_UserId] ON [common].[UserClaims] ([UserId]) ON [PRIMARY]
GO
ALTER TABLE [common].[UserClaims] ADD CONSTRAINT [FK_common_UserClaims_common_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [common].[Users] ([Id])
GO
ALTER TABLE [common].[UserClaims] ADD CONSTRAINT [FK_UserClaims_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [common].[Users] ([Id]) ON DELETE CASCADE
GO
