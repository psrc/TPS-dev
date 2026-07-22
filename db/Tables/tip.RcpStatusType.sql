CREATE TABLE [tip].[RcpStatusType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_RcpStatusType_Id] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsConstrained] [bit] NOT NULL CONSTRAINT [DF_RcpStatusType_IsConstrained] DEFAULT ((0)),
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[SortId] [int] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_RcpStatusType_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_RcpStatusType_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[RcpStatusType] ADD CONSTRAINT [PK_RcpStatusType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
