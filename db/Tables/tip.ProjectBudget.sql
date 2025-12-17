CREATE TABLE [tip].[ProjectBudget]
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectId] [uniqueidentifier] NOT NULL,
[FundingSourceTypeId] [uniqueidentifier] NOT NULL,
[PLSecuredAmount] [bigint] NULL CONSTRAINT [DF__ProjectBu__PLSec__04508AFF] DEFAULT ((0)),
[PLUnsecuredAmount] [bigint] NULL CONSTRAINT [DF__ProjectBu__PLUns__0544AF38] DEFAULT ((0)),
[PLTotalAmount] AS ([PLSecuredAmount]+[PLUnsecuredAmount]) PERSISTED,
[PESecuredAmount] [bigint] NULL CONSTRAINT [DF__ProjectBu__PESec__0638D371] DEFAULT ((0)),
[PEUnsecuredAmount] [bigint] NULL CONSTRAINT [DF__ProjectBu__PEUns__072CF7AA] DEFAULT ((0)),
[PETotalAmount] AS ([PESecuredAmount]+[PEUnsecuredAmount]) PERSISTED,
[ROWSecuredAmount] [bigint] NULL CONSTRAINT [DF__ProjectBu__ROWSe__08211BE3] DEFAULT ((0)),
[ROWUnsecuredAmount] [bigint] NULL CONSTRAINT [DF__ProjectBu__ROWUn__0915401C] DEFAULT ((0)),
[ROWTotalAmount] AS ([ROWSecuredAmount]+[ROWUnsecuredAmount]) PERSISTED,
[CNSecuredAmount] [bigint] NULL CONSTRAINT [DF__ProjectBu__CNSec__0A096455] DEFAULT ((0)),
[CNUnsecuredAmount] [bigint] NULL CONSTRAINT [DF__ProjectBu__CNUns__0AFD888E] DEFAULT ((0)),
[CNTotalAmount] AS ([CNSecuredAmount]+[CNUnsecuredAmount]) PERSISTED,
[OtherSecuredAmount] [bigint] NULL CONSTRAINT [DF__ProjectBu__Other__0BF1ACC7] DEFAULT ((0)),
[OtherUnsecuredAmount] [bigint] NULL CONSTRAINT [DF__ProjectBu__Other__0CE5D100] DEFAULT ((0)),
[OtherTotalAmount] AS ([OtherSecuredAmount]+[OtherUnsecuredAmount]) PERSISTED,
[TotalSecuredAmount] AS (((([PLSecuredAmount]+[PESecuredAmount])+[ROWSecuredAmount])+[CNSecuredAmount])+[OtherSecuredAmount]) PERSISTED,
[TotalUnsecuredAmount] AS (((([PLUnsecuredAmount]+[PEUnsecuredAmount])+[ROWUnsecuredAmount])+[CNUnsecuredAmount])+[OtherUnsecuredAmount]) PERSISTED,
[TotalAmount] AS ((((((((([PLSecuredAmount]+[PLUnsecuredAmount])+[PESecuredAmount])+[PEUnsecuredAmount])+[ROWSecuredAmount])+[ROWUnsecuredAmount])+[CNSecuredAmount])+[CNUnsecuredAmount])+[OtherSecuredAmount])+[OtherUnsecuredAmount]) PERSISTED,
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__ProjectBu__Creat__0DD9F539] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectBudget] ADD CONSTRAINT [PK_ProjectBudget] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectBudget] ADD CONSTRAINT [FK_ProjectBudget_FundingSourceType] FOREIGN KEY ([FundingSourceTypeId]) REFERENCES [tip].[FundingSourceType] ([Id])
GO
ALTER TABLE [tip].[ProjectBudget] ADD CONSTRAINT [FK_ProjectBudget_Project] FOREIGN KEY ([ProjectId]) REFERENCES [tip].[Project] ([Id])
GO
