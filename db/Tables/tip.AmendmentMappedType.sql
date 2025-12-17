CREATE TABLE [tip].[AmendmentMappedType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__AmendmentMap__Id__066DDD9B] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__Amendment__Creat__076201D4] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__Amendment__Creat__0856260D] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[AmendmentMappedType] ADD CONSTRAINT [PK_AmendmentMappedType] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
