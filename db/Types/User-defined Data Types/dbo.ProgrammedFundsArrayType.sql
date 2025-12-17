CREATE TYPE [dbo].[ProgrammedFundsArrayType] AS TABLE
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectId] [uniqueidentifier] NOT NULL,
[OriginRecordId] [uniqueidentifier] NULL,
[AwardReferenceId] [uniqueidentifier] NULL,
[PhaseTypeId] [uniqueidentifier] NULL,
[ProgrammedFundingYear] [int] NULL,
[EstimatedObligationDate] [date] NULL,
[FundingSourceTypeId] [uniqueidentifier] NOT NULL,
[FundingAmount] [int] NOT NULL,
[IsObligatedFlag] [bit] NULL,
[FtaObligatedDate] [date] NULL,
[FtaObligatedNumber] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FhwaObligatedDate] [date] NULL,
[FhwaObligatedNumber] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NOT NULL
)
GO
