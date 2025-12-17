CREATE TABLE [common].[AgencyContactMapping]
(
[Id] [uniqueidentifier] NOT NULL,
[AgencyId] [uniqueidentifier] NOT NULL,
[ContactId] [uniqueidentifier] NOT NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__AgencyCon__Creat__744F2D60] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__AgencyCon__Creat__75435199] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[AgencyContactMapping] ADD CONSTRAINT [PK_AgencyContactMapping_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [common].[AgencyContactMapping] ADD CONSTRAINT [UQ_AgencyContactMapping_ContactId_AgencyId] UNIQUE NONCLUSTERED ([AgencyId], [ContactId]) ON [PRIMARY]
GO
ALTER TABLE [common].[AgencyContactMapping] ADD CONSTRAINT [FK_AgencyContactMapping_Agency] FOREIGN KEY ([AgencyId]) REFERENCES [common].[Agency] ([Id])
GO
ALTER TABLE [common].[AgencyContactMapping] ADD CONSTRAINT [FK_AgencyContactMapping_Contact] FOREIGN KEY ([ContactId]) REFERENCES [common].[Contact] ([Id])
GO
