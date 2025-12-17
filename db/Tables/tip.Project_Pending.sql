CREATE TABLE [tip].[Project_Pending]
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectAmendmentId] [uniqueidentifier] NOT NULL,
[AgencyId] [uniqueidentifier] NOT NULL,
[ProjectCode] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Title] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ContactId] [uniqueidentifier] NULL,
[WsDotPin] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DemoId] [nvarchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Location] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LocationFrom] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[LocationTo] [nvarchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Length] [int] NULL,
[FunctionalClassTypeId] [uniqueidentifier] NULL,
[PrimaryImprovementTypeId] [uniqueidentifier] NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[DateFullyImplemented] [date] NULL,
[RcpStatusTypeId] [uniqueidentifier] NULL,
[ConstantDollarProjectYear] [smallint] NULL,
[MappedTypeId] [uniqueidentifier] NULL,
[EnvironmentalStatusTypeId] [uniqueidentifier] NULL,
[RegionalSignificanceTypeId] [uniqueidentifier] NULL,
[YearCompPL] [smallint] NULL,
[YearCompPE] [smallint] NULL,
[YearCompROW] [smallint] NULL,
[YearCompCN] [smallint] NULL,
[YearCompOther] [smallint] NULL,
[DateCompProject] [date] NULL,
[CaSponsorAgencyId] [uniqueidentifier] NULL,
[CompletionStatusTypeId] [uniqueidentifier] NULL,
[UpwpObjective] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UpwpTasks] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UpwpProducts] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UpwpPolicy] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UpwpIsEquipmentPurchaseFlag] [bit] NULL CONSTRAINT [DF__Project_P__UpwpI__3AAC9BB0] DEFAULT ((0)),
[PsrcComments] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Project_P__Creat__3BA0BFE9] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Project_P__Creat__3C94E422] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [PK_Project_Pending] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Project_Pending_Id] ON [tip].[Project_Pending] ([Id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Project_Pending_TipIdCode] ON [tip].[Project_Pending] ([ProjectCode]) ON [PRIMARY]
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [PK_Project_Pending_TipIdCode] UNIQUE NONCLUSTERED ([ProjectCode]) ON [PRIMARY]
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [FK_Project_Pending_Agency_AgencyId] FOREIGN KEY ([AgencyId]) REFERENCES [common].[Agency] ([Id])
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [FK_Project_Pending_Agency_CaSponsorAgencyId] FOREIGN KEY ([CaSponsorAgencyId]) REFERENCES [common].[Agency] ([Id])
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [FK_Project_Pending_CompletionStatusType] FOREIGN KEY ([CompletionStatusTypeId]) REFERENCES [tip].[CompletionStatusType] ([Id])
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [FK_Project_Pending_Contact] FOREIGN KEY ([ContactId]) REFERENCES [common].[Contact] ([Id])
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [FK_Project_Pending_EnvironmentalStatusType] FOREIGN KEY ([EnvironmentalStatusTypeId]) REFERENCES [tip].[EnvironmentalStatusType] ([Id])
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [FK_Project_Pending_FunctionalClassType] FOREIGN KEY ([FunctionalClassTypeId]) REFERENCES [tip].[FunctionalClassType] ([Id])
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [FK_Project_Pending_MappedType] FOREIGN KEY ([MappedTypeId]) REFERENCES [tip].[MappedType] ([Id])
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [FK_Project_Pending_PrimaryImprovementType] FOREIGN KEY ([PrimaryImprovementTypeId]) REFERENCES [tip].[ImprovementType] ([Id])
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [FK_Project_Pending_ProjectAmendment] FOREIGN KEY ([ProjectAmendmentId]) REFERENCES [tip].[ProjectAmendment] ([Id])
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [FK_Project_Pending_RcpStatusType] FOREIGN KEY ([RcpStatusTypeId]) REFERENCES [tip].[RcpStatusType] ([Id])
GO
ALTER TABLE [tip].[Project_Pending] ADD CONSTRAINT [FK_Project_Pending_RegionalSignificanceType] FOREIGN KEY ([RegionalSignificanceTypeId]) REFERENCES [tip].[RegionalSignificanceType] ([Id])
GO
