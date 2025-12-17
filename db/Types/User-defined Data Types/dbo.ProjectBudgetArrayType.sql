CREATE TYPE [dbo].[ProjectBudgetArrayType] AS TABLE
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectId] [uniqueidentifier] NOT NULL,
[FundingSourceTypeId] [uniqueidentifier] NOT NULL,
[PLSecuredAmount] [bigint] NULL,
[PLUnsecuredAmount] [bigint] NULL,
[PESecuredAmount] [bigint] NULL,
[PEUnsecuredAmount] [bigint] NULL,
[ROWSecuredAmount] [bigint] NULL,
[ROWUnsecuredAmount] [bigint] NULL,
[CNSecuredAmount] [bigint] NULL,
[CNUnsecuredAmount] [bigint] NULL,
[OtherSecuredAmount] [bigint] NULL,
[OtherUnsecuredAmount] [bigint] NULL
)
GO
