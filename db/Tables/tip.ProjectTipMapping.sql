CREATE TABLE [tip].[ProjectTipMapping]
(
[Id] [uniqueidentifier] NOT NULL,
[ProjectId] [uniqueidentifier] NOT NULL,
[TipId] [uniqueidentifier] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__ProjectTi__Creat__35E7E693] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__ProjectTi__Creat__36DC0ACC] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectTipMapping] ADD CONSTRAINT [PK_ProjectTipMapping_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectTipMapping] ADD CONSTRAINT [UQ_ProjectTipMapping_ProjectId_TipId] UNIQUE NONCLUSTERED ([ProjectId], [TipId]) ON [PRIMARY]
GO
ALTER TABLE [tip].[ProjectTipMapping] ADD CONSTRAINT [FK_ProjectTipMapping_Project] FOREIGN KEY ([ProjectId]) REFERENCES [tip].[Project] ([Id])
GO
ALTER TABLE [tip].[ProjectTipMapping] ADD CONSTRAINT [FK_ProjectTipMapping_Tip] FOREIGN KEY ([TipId]) REFERENCES [tip].[Tip] ([Id])
GO
