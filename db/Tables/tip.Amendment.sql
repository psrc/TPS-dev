CREATE TABLE [tip].[Amendment]
(
[Id] [uniqueidentifier] NOT NULL,
[AmendmentStatusTypeId] [uniqueidentifier] NULL,
[Name] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[PsrcDueDate] [date] NULL,
[TpbReviewDate] [date] NULL,
[WsdotDueDate] [date] NULL,
[WsdotSubmittedDate] [date] NULL,
[WsdotPostedDate] [date] NULL,
[AmendmentMappedTypeId] [uniqueidentifier] NULL,
[IsAdministrativeAmendmentFlag] [bit] NOT NULL CONSTRAINT [DF_Amendment_IsAdministrativeAmendmentFlag] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_Amendment_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_Amendment_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[EffectiveDate] [date] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[Amendment] ADD CONSTRAINT [PK_Amendment_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[Amendment] ADD CONSTRAINT [FK_Amendment_AmendmentMappedType] FOREIGN KEY ([AmendmentMappedTypeId]) REFERENCES [tip].[AmendmentMappedType] ([Id])
GO
ALTER TABLE [tip].[Amendment] ADD CONSTRAINT [FK_Amendment_AmendmentStatusType] FOREIGN KEY ([AmendmentStatusTypeId]) REFERENCES [tip].[AmendmentStatusType] ([Id])
GO
