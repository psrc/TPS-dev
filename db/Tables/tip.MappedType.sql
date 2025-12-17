CREATE TABLE [tip].[MappedType]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF__MappedType__Id__4DF47A4E] DEFAULT (newid()),
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortId] [int] NULL,
[EffectiveDate] [date] NULL,
[EndDate] [date] NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF__MappedTyp__Creat__4EE89E87] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF__MappedTyp__Creat__4FDCC2C0] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [tip].[MappedType] ADD CONSTRAINT [PK_MappedType_Id] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
