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
[IsAdministrativeAmendmentFlag] [bit] NOT NULL CONSTRAINT [DF__Amendment__IsAdm__01A9287E] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Amendment__Creat__029D4CB7] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Amendment__Creat__039170F0] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[Amendment] ADD CONSTRAINT [PK_Amendment_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [tip].[Amendment] ADD CONSTRAINT [FK_Amendment_AmendmentMappedType] FOREIGN KEY ([AmendmentMappedTypeId]) REFERENCES [tip].[AmendmentMappedType] ([Id])
GO
ALTER TABLE [tip].[Amendment] ADD CONSTRAINT [FK_Amendment_AmendmentStatusType] FOREIGN KEY ([AmendmentStatusTypeId]) REFERENCES [tip].[AmendmentStatusType] ([Id])
GO
