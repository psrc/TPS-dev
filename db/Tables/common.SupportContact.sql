CREATE TABLE [common].[SupportContact]
(
[Id] [uniqueidentifier] NOT NULL,
[ChannelType] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Label] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Value] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Availability] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NOT NULL CONSTRAINT [DF_SupportContact_SortId] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_SupportContact_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_SupportContact_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[SupportContact] ADD CONSTRAINT [PK_SupportContact] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'An admin-editable support contact channel (e.g. Email, Phone) shown in the Contact Support section of the public Help Center. Ordered by SortId.', 'SCHEMA', N'common', 'TABLE', N'SupportContact', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'Channel discriminator, e.g. Email or Phone.', 'SCHEMA', N'common', 'TABLE', N'SupportContact', 'COLUMN', N'ChannelType'
GO
