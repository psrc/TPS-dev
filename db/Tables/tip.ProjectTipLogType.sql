CREATE TABLE [tip].[ProjectTipLogType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ProjectTipLogType_Id] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ProjectTipLogType_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ProjectTipLogType_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectTipLogType] ADD CONSTRAINT [PK_ProjectTipLogType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
