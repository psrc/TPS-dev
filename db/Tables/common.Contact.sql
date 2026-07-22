CREATE TABLE [common].[Contact]
(
[Id] [uniqueidentifier] NOT NULL,
[FirstName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LastName] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Email] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Phone] [nvarchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PhoneExt] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AgencyId] [uniqueidentifier] NULL,
[IsActive] [bit] NOT NULL CONSTRAINT [DF_Contact_IsActive] DEFAULT ((1)),
[Notes] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Contact_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_Contact_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[Contact] ADD CONSTRAINT [PK_Contact_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
