CREATE TABLE [common].[EmailTemplate]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_EmailTemplate_Id] DEFAULT (newid()),
[Category] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_EmailTemplate_Category] DEFAULT ('FormTransition'),
[FormTemplateId] [uniqueidentifier] NULL,
[Name] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Subject] [nvarchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[BodyHtml] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AttachResponsePdf] [bit] NOT NULL CONSTRAINT [DF_EmailTemplate_AttachResponsePdf] DEFAULT ((0)),
[IsSystem] [bit] NOT NULL CONSTRAINT [DF_EmailTemplate_IsSystem] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL,
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_EmailTemplate_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[EmailTemplate] ADD CONSTRAINT [PK_EmailTemplate] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_EmailTemplate_Category_FormTemplate] ON [common].[EmailTemplate] ([Category], [FormTemplateId]) ON [PRIMARY]
GO
ALTER TABLE [common].[EmailTemplate] ADD CONSTRAINT [FK_EmailTemplate_FormTemplate] FOREIGN KEY ([FormTemplateId]) REFERENCES [forms].[FormTemplate] ([Id])
GO
