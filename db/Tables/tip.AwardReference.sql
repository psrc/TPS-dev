CREATE TABLE [tip].[AwardReference]
(
[Id] [uniqueidentifier] NOT NULL,
[AwardId] [int] NULL,
[AwardRef] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SubAwardReference] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[AwardYear] [smallint] NULL,
[AgeOfFunds] [smallint] NULL,
[ForumTypeId] [uniqueidentifier] NULL,
[DistributionTypeId] [uniqueidentifier] NULL,
[AgencyId] [uniqueidentifier] NULL,
[ProjectId] [uniqueidentifier] NULL,
[PhaseTypeId] [uniqueidentifier] NULL,
[FundSourceTypeId] [uniqueidentifier] NULL,
[FundAmount] [bigint] NULL,
[Notes] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[IsActive] [bit] NULL CONSTRAINT [DF__AwardRefe__IsAct__15B0212B] DEFAULT ((1)),
[ActionYear] [smallint] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__AwardRefe__Creat__16A44564] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__AwardRefe__Creat__1798699D] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[AwardReference] ADD CONSTRAINT [PK_AwardReference] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[AwardReference] ADD CONSTRAINT [FK_AwardReference_Agency] FOREIGN KEY ([AgencyId]) REFERENCES [common].[Agency] ([Id])
GO
ALTER TABLE [tip].[AwardReference] ADD CONSTRAINT [FK_AwardReference_DistributionType] FOREIGN KEY ([DistributionTypeId]) REFERENCES [tip].[DistributionType] ([Id])
GO
ALTER TABLE [tip].[AwardReference] ADD CONSTRAINT [FK_AwardReference_ForumType] FOREIGN KEY ([ForumTypeId]) REFERENCES [tip].[ForumType] ([Id])
GO
ALTER TABLE [tip].[AwardReference] ADD CONSTRAINT [FK_AwardReference_FundingSourceType] FOREIGN KEY ([FundSourceTypeId]) REFERENCES [tip].[FundingSourceType] ([Id])
GO
ALTER TABLE [tip].[AwardReference] ADD CONSTRAINT [FK_AwardReference_PhaseType] FOREIGN KEY ([PhaseTypeId]) REFERENCES [tip].[PhaseType] ([Id])
GO
ALTER TABLE [tip].[AwardReference] ADD CONSTRAINT [FK_AwardReference_Project] FOREIGN KEY ([ProjectId]) REFERENCES [tip].[Project] ([Id])
GO
