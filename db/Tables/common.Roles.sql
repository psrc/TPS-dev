CREATE TABLE [common].[Roles]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Roles__Id__4BA21D88] DEFAULT (newsequentialid()),
[Name] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NormalizedName] [nvarchar] (256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ConcurrencyStamp] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Roles__CreatedOn__4C9641C1] DEFAULT (getutcdate()),
[UpdatedOn] [datetime2] NULL,
[CreatedById] [uniqueidentifier] NULL,
[UpdatedById] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[Roles] ADD CONSTRAINT [PK_identity_Roles] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [RoleNameIndex] ON [common].[Roles] ([NormalizedName]) WHERE ([NormalizedName] IS NOT NULL) ON [PRIMARY]
GO
