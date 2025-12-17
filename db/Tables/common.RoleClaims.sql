CREATE TABLE [common].[RoleClaims]
(
[Id] [int] NOT NULL IDENTITY(1, 1),
[RoleId] [uniqueidentifier] NOT NULL,
[ClaimType] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ClaimValue] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[RoleClaims] ADD CONSTRAINT [PK_identity_RoleClaims] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_RoleClaims_RoleId] ON [common].[RoleClaims] ([RoleId]) ON [PRIMARY]
GO
ALTER TABLE [common].[RoleClaims] ADD CONSTRAINT [FK_common_RoleClaims_common_Roles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [common].[Roles] ([Id])
GO
ALTER TABLE [common].[RoleClaims] ADD CONSTRAINT [FK_RoleClaims_Roles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [common].[Roles] ([Id]) ON DELETE CASCADE
GO
