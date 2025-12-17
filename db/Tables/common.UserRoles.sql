CREATE TABLE [common].[UserRoles]
(
[UserId] [uniqueidentifier] NOT NULL,
[RoleId] [uniqueidentifier] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[UserRoles] ADD CONSTRAINT [PK_identity_UserRoles] PRIMARY KEY CLUSTERED ([UserId], [RoleId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_UserRoles_RoleId] ON [common].[UserRoles] ([RoleId]) ON [PRIMARY]
GO
ALTER TABLE [common].[UserRoles] ADD CONSTRAINT [FK_common_UserRoles_common_Roles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [common].[Roles] ([Id])
GO
ALTER TABLE [common].[UserRoles] ADD CONSTRAINT [FK_common_UserRoles_common_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [common].[Users] ([Id])
GO
ALTER TABLE [common].[UserRoles] ADD CONSTRAINT [FK_UserRoles_Roles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [common].[Roles] ([Id]) ON DELETE CASCADE
GO
ALTER TABLE [common].[UserRoles] ADD CONSTRAINT [FK_UserRoles_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [common].[Users] ([Id]) ON DELETE CASCADE
GO
