CREATE TABLE [tip].[ProgrammedFunding]
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectId] [uniqueidentifier] NOT NULL,
[AwardReferenceId] [uniqueidentifier] NULL,
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
[IsActive] [bit] NOT NULL CONSTRAINT [DF_ProgrammedFunding_IsActive] DEFAULT ((1)),
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ProgrammedFunding_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProgrammedFunding] ADD CONSTRAINT [PK_ProgrammedFunding] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProgrammedFunding] ADD CONSTRAINT [FK_ProgrammedFunding_AwardReference] FOREIGN KEY ([AwardReferenceId]) REFERENCES [tip].[AwardReference] ([Id])
GO
ALTER TABLE [tip].[ProgrammedFunding] ADD CONSTRAINT [FK_ProgrammedFunding_PhaseType] FOREIGN KEY ([PhaseTypeId]) REFERENCES [tip].[PhaseType] ([Id])
GO
ALTER TABLE [tip].[ProgrammedFunding] ADD CONSTRAINT [FK_ProgrammedFunding_Project] FOREIGN KEY ([ProjectId]) REFERENCES [tip].[Project] ([Id])
GO
