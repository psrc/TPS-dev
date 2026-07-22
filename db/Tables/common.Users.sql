CREATE TABLE [common].[Users]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Users_Id] DEFAULT (newsequentialid()),
[UserName] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NormalizedUserName] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Email] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NormalizedEmail] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[EmailConfirmed] [bit] NOT NULL CONSTRAINT [DF_Users_EmailConfirmed] DEFAULT ((0)),
[PasswordHash] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SecurityStamp] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConcurrencyStamp] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PhoneNumber] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PhoneNumberConfirmed] [bit] NOT NULL CONSTRAINT [DF_Users_PhoneNumberConfirmed] DEFAULT ((0)),
[TwoFactorEnabled] [bit] NOT NULL CONSTRAINT [DF_Users_TwoFactorEnabled] DEFAULT ((0)),
[LockoutEnd] [datetimeoffset] NULL,
[LockoutEnabled] [bit] NOT NULL CONSTRAINT [DF_Users_LockoutEnabled] DEFAULT ((1)),
[AccessFailedCount] [int] NOT NULL CONSTRAINT [DF_Users_AccessFailedCount] DEFAULT ((0)),
[LastAccessedOn] [datetime2] NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_Users_CreatedOn] DEFAULT (getutcdate()),
[UpdatedOn] [datetime2] NULL,
[CreatedById] [uniqueidentifier] NULL,
[UpdatedById] [uniqueidentifier] NULL,
[FirstName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Nickname] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastLoginAt] [datetime2] NULL,
[LastLoginIp] [nvarchar] (45) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LoginCount] [int] NOT NULL CONSTRAINT [DF_Users_LoginCount] DEFAULT ((0)),
[LastPasswordResetAt] [datetime2] NULL,
[IsBlocked] [bit] NOT NULL CONSTRAINT [DF_Users_IsBlocked] DEFAULT ((0)),
[BlockReason] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserMetadata] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AppMetadata] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RefreshTokenHash] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[RefreshTokenExpiryTime] [datetime2] NULL,
[MustResetPassword] [bit] NOT NULL CONSTRAINT [DF_Users_MustResetPassword] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [common].[Users] ADD CONSTRAINT [PK_identity_Users] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [EmailIndex] ON [common].[Users] ([NormalizedEmail]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UserNameIndex] ON [common].[Users] ([NormalizedUserName]) WHERE ([NormalizedUserName] IS NOT NULL) ON [PRIMARY]
GO
