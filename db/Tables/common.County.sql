CREATE TABLE [common].[County]
(
[Id] [uniqueidentifier] NOT NULL,
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_County_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_County_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[County] ADD CONSTRAINT [PK_County_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
