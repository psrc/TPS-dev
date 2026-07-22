CREATE TABLE [tip].[ProjectBudget_Pending]
(
[Id] [uniqueidentifier] NOT NULL,
[Project_PendingId] [uniqueidentifier] NOT NULL,
[FundingSourceTypeId] [uniqueidentifier] NOT NULL,
[PLSecuredAmount] [bigint] NULL CONSTRAINT [DF_ProjectBudget_Pending_PLSecuredAmount] DEFAULT ((0)),
[PLUnsecuredAmount] [bigint] NULL CONSTRAINT [DF_ProjectBudget_Pending_PLUnsecuredAmount] DEFAULT ((0)),
[PLTotalAmount] AS ([PLSecuredAmount]+[PLUnsecuredAmount]) PERSISTED,
[PESecuredAmount] [bigint] NULL CONSTRAINT [DF_ProjectBudget_Pending_PESecuredAmount] DEFAULT ((0)),
[PEUnsecuredAmount] [bigint] NULL CONSTRAINT [DF_ProjectBudget_Pending_PEUnsecuredAmount] DEFAULT ((0)),
[PETotalAmount] AS ([PESecuredAmount]+[PEUnsecuredAmount]) PERSISTED,
[ROWSecuredAmount] [bigint] NULL CONSTRAINT [DF_ProjectBudget_Pending_ROWSecuredAmount] DEFAULT ((0)),
[ROWUnsecuredAmount] [bigint] NULL CONSTRAINT [DF_ProjectBudget_Pending_ROWUnsecuredAmount] DEFAULT ((0)),
[ROWTotalAmount] AS ([ROWSecuredAmount]+[ROWUnsecuredAmount]) PERSISTED,
[CNSecuredAmount] [bigint] NULL CONSTRAINT [DF_ProjectBudget_Pending_CNSecuredAmount] DEFAULT ((0)),
[CNUnsecuredAmount] [bigint] NULL CONSTRAINT [DF_ProjectBudget_Pending_CNUnsecuredAmount] DEFAULT ((0)),
[CNTotalAmount] AS ([CNSecuredAmount]+[CNUnsecuredAmount]) PERSISTED,
[OtherSecuredAmount] [bigint] NULL CONSTRAINT [DF_ProjectBudget_Pending_OtherSecuredAmount] DEFAULT ((0)),
[OtherUnsecuredAmount] [bigint] NULL CONSTRAINT [DF_ProjectBudget_Pending_OtherUnsecuredAmount] DEFAULT ((0)),
[OtherTotalAmount] AS ([OtherSecuredAmount]+[OtherUnsecuredAmount]) PERSISTED,
[TotalSecuredAmount] AS (((([PLSecuredAmount]+[PESecuredAmount])+[ROWSecuredAmount])+[CNSecuredAmount])+[OtherSecuredAmount]) PERSISTED,
[TotalUnsecuredAmount] AS (((([PLUnsecuredAmount]+[PEUnsecuredAmount])+[ROWUnsecuredAmount])+[CNUnsecuredAmount])+[OtherUnsecuredAmount]) PERSISTED,
[TotalAmount] AS ((((((((([PLSecuredAmount]+[PLUnsecuredAmount])+[PESecuredAmount])+[PEUnsecuredAmount])+[ROWSecuredAmount])+[ROWUnsecuredAmount])+[CNSecuredAmount])+[CNUnsecuredAmount])+[OtherSecuredAmount])+[OtherUnsecuredAmount]) PERSISTED,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ProjectBudget_Pending_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectBudget_Pending] ADD CONSTRAINT [PK_ProjectBudget_Pending] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectBudget_Pending] ADD CONSTRAINT [FK_ProjectBudget_Pending_FundingSourceType] FOREIGN KEY ([FundingSourceTypeId]) REFERENCES [tip].[FundingSourceType] ([Id])
GO
ALTER TABLE [tip].[ProjectBudget_Pending] ADD CONSTRAINT [FK_ProjectBudgetPending_ProjectPending] FOREIGN KEY ([Project_PendingId]) REFERENCES [tip].[Project_Pending] ([Id])
GO
