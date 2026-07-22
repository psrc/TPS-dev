CREATE TABLE [tip].[Project]
(
[Id] [uniqueidentifier] NOT NULL,
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
[UpwpIsEquipmentPurchaseFlag] [bit] NULL CONSTRAINT [DF_Project_UpwpIsEquipmentPurchaseFlag] DEFAULT ((0)),
[PsrcComments] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Project_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_Project_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[ReportDescription] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[Project] ADD CONSTRAINT [PK_tipProject_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_tipProject_Id] ON [tip].[Project] ([Id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_tipProject_TipIdCode] ON [tip].[Project] ([ProjectCode]) ON [PRIMARY]
GO
ALTER TABLE [tip].[Project] ADD CONSTRAINT [UQ_tipProject_TipIdCode] UNIQUE NONCLUSTERED ([ProjectCode]) ON [PRIMARY]
GO
ALTER TABLE [tip].[Project] ADD CONSTRAINT [FK_Project_Agency_AgencyId] FOREIGN KEY ([AgencyId]) REFERENCES [common].[Agency] ([Id])
GO
ALTER TABLE [tip].[Project] ADD CONSTRAINT [FK_Project_Agency_CaSponsorAgencyId] FOREIGN KEY ([CaSponsorAgencyId]) REFERENCES [common].[Agency] ([Id])
GO
ALTER TABLE [tip].[Project] ADD CONSTRAINT [FK_Project_CompletionStatusType] FOREIGN KEY ([CompletionStatusTypeId]) REFERENCES [tip].[CompletionStatusType] ([Id])
GO
ALTER TABLE [tip].[Project] ADD CONSTRAINT [FK_Project_Contact] FOREIGN KEY ([ContactId]) REFERENCES [common].[Contact] ([Id])
GO
ALTER TABLE [tip].[Project] ADD CONSTRAINT [FK_Project_EnvironmentalStatusType] FOREIGN KEY ([EnvironmentalStatusTypeId]) REFERENCES [tip].[EnvironmentalStatusType] ([Id])
GO
ALTER TABLE [tip].[Project] ADD CONSTRAINT [FK_Project_FunctionalClassType] FOREIGN KEY ([FunctionalClassTypeId]) REFERENCES [tip].[FunctionalClassType] ([Id])
GO
ALTER TABLE [tip].[Project] ADD CONSTRAINT [FK_Project_ImprovementType] FOREIGN KEY ([PrimaryImprovementTypeId]) REFERENCES [tip].[ImprovementType] ([Id])
GO
ALTER TABLE [tip].[Project] ADD CONSTRAINT [FK_Project_MappedType] FOREIGN KEY ([MappedTypeId]) REFERENCES [tip].[MappedType] ([Id])
GO
ALTER TABLE [tip].[Project] ADD CONSTRAINT [FK_Project_RcpStatusType] FOREIGN KEY ([RcpStatusTypeId]) REFERENCES [tip].[RcpStatusType] ([Id])
GO
ALTER TABLE [tip].[Project] ADD CONSTRAINT [FK_Project_RegionalSignificanceType] FOREIGN KEY ([RegionalSignificanceTypeId]) REFERENCES [tip].[RegionalSignificanceType] ([Id])
GO
