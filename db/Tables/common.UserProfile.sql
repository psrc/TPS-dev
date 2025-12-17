CREATE TABLE [common].[UserProfile]
(
[Id] [uniqueidentifier] NOT NULL,
[UserId] [uniqueidentifier] NOT NULL,
[FullName] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Email] [nvarchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__UserProfi__Creat__668B1DEE] DEFAULT (getutcdate()),
[UpdatedOn] [datetime2] NULL,
[AppUserId] [uniqueidentifier] NULL,
[AgencyId] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[UserProfile] ADD CONSTRAINT [UserProfile_pkey] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_UserProfile_AgencyId] ON [common].[UserProfile] ([AgencyId]) INCLUDE ([FullName], [Email]) ON [PRIMARY]
GO
ALTER TABLE [common].[UserProfile] ADD CONSTRAINT [FK_UserProfile_Agency] FOREIGN KEY ([AgencyId]) REFERENCES [common].[Agency] ([Id])
GO
ALTER TABLE [common].[UserProfile] ADD CONSTRAINT [FK_UserProfile_AppUsers_AppUserId] FOREIGN KEY ([AppUserId]) REFERENCES [common].[Users] ([Id])
GO
ALTER TABLE [common].[UserProfile] ADD CONSTRAINT [FK_UserProfile_Users] FOREIGN KEY ([UserId]) REFERENCES [common].[Users] ([Id]) ON DELETE CASCADE
GO
