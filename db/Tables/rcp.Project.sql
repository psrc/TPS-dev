CREATE TABLE [rcp].[Project]
(
[Id] [uniqueidentifier] NOT NULL,
[AgencyId] [uniqueidentifier] NOT NULL,
[Title] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL,
[UpdatedById] [uniqueidentifier] NOT NULL,
[UpdatedOn] [datetime2] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [rcp].[Project] ADD CONSTRAINT [PK_RcpProject] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
