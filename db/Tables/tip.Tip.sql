CREATE TABLE [tip].[Tip]
(
[Id] [uniqueidentifier] NOT NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BeginYear] [smallint] NOT NULL,
[EndYear] [smallint] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Tip__CreatedOn__583CFE97] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[IsCurrent] [bit] NOT NULL CONSTRAINT [DF__Tip__IsCurrent__593122D0] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [tip].[Tip] ADD CONSTRAINT [PK_Tip_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
