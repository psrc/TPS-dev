CREATE TABLE [tip].[Tip]
(
[Id] [uniqueidentifier] NOT NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[BeginYear] [smallint] NOT NULL,
[EndYear] [smallint] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_Tip_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[IsCurrent] [bit] NOT NULL CONSTRAINT [DF_Tip_IsCurrent] DEFAULT ((0)),
[IsPending] [bit] NOT NULL CONSTRAINT [DF_Tip_IsPending] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [tip].[Tip] ADD CONSTRAINT [CK_Tip_NotBothCurrentAndPending] CHECK (([IsCurrent]=(0) OR [IsPending]=(0)))
GO
ALTER TABLE [tip].[Tip] ADD CONSTRAINT [PK_Tip_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [UQ_Tip_IsPending] ON [tip].[Tip] ([IsPending]) WHERE ([IsPending]=(1)) ON [PRIMARY]
GO
