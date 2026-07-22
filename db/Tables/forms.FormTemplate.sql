CREATE TABLE [forms].[FormTemplate]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormTemplate_Id] DEFAULT (newid()),
[Name] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormTemplate_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormTemplate_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL,
[Category] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[PsrcContactId] [uniqueidentifier] NULL,
[IsSelfAssignable] [bit] NOT NULL CONSTRAINT [DF_FormTemplate_IsSelfAssignable] DEFAULT ((0)),
[OpenDate] [date] NULL,
[CloseDate] [date] NULL,
[DueDate] [date] NULL,
[StatusTypeId] [uniqueidentifier] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormTemplate] ADD CONSTRAINT [PK_FormTemplate] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormTemplate] ADD CONSTRAINT [UQ_FormTemplate_Name] UNIQUE NONCLUSTERED ([Name]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormTemplate] ADD CONSTRAINT [FK_FormTemplate_FormTemplateStatusType] FOREIGN KEY ([StatusTypeId]) REFERENCES [forms].[FormTemplateStatusType] ([Id])
GO
