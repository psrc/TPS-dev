CREATE TABLE [tip].[RcpStatusType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__RcpStatusTyp__Id__3F7150CD] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsConstrained] [bit] NOT NULL CONSTRAINT [DF__RcpStatus__IsCon__40657506] DEFAULT ((0)),
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[SortId] [int] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__RcpStatus__Creat__4159993F] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__RcpStatus__Creat__424DBD78] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[RcpStatusType] ADD CONSTRAINT [PK_RcpStatusType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
