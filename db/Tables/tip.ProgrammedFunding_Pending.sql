CREATE TABLE [tip].[ProgrammedFunding_Pending]
(
[Id] [uniqueidentifier] NOT NULL,
[Project_PendingId] [uniqueidentifier] NOT NULL,
[AwardReferenceTypeId] [uniqueidentifier] NULL,
[PhaseTypeId] [uniqueidentifier] NULL,
[ProgrammedFundingYear] [smallint] NULL,
[EstimatedObligationDate] [date] NULL,
[FundingSourceTypeId] [uniqueidentifier] NOT NULL,
[FundingAmount] [bigint] NULL,
[IsObligatedFlag] [bit] NULL,
[FtaObligatedDate] [date] NULL,
[FtaObligatedNumber] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FhwaObligatedDate] [date] NULL,
[FhwaObligatedNumber] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OriginRecordId] [uniqueidentifier] NOT NULL,
[IsActive] [bit] NOT NULL CONSTRAINT [DF__Programme__IsAct__5B4E756C] DEFAULT ((1)),
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Programme__Creat__5C4299A5] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProgrammedFunding_Pending] ADD CONSTRAINT [PK_ProgrammedFunding_Pending] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProgrammedFunding_Pending] ADD CONSTRAINT [FK_ProgrammedFunding_Pending_PhaseType] FOREIGN KEY ([PhaseTypeId]) REFERENCES [tip].[PhaseType] ([Id])
GO
ALTER TABLE [tip].[ProgrammedFunding_Pending] ADD CONSTRAINT [FK_ProgrammedFundingPending_ProjectPending] FOREIGN KEY ([Project_PendingId]) REFERENCES [tip].[Project_Pending] ([Id])
GO
