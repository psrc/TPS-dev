CREATE TABLE [common].[UserTokens]
(
[UserId] [uniqueidentifier] NOT NULL,
[LoginProvider] [nvarchar] (450) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Name] [nvarchar] (450) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Value] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[UserTokens] ADD CONSTRAINT [PK_identity_UserTokens] PRIMARY KEY CLUSTERED ([UserId], [LoginProvider], [Name]) ON [PRIMARY]
GO
ALTER TABLE [common].[UserTokens] ADD CONSTRAINT [FK_common_UserTokens_common_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [common].[Users] ([Id])
GO
ALTER TABLE [common].[UserTokens] ADD CONSTRAINT [FK_UserTokens_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [common].[Users] ([Id]) ON DELETE CASCADE
GO
