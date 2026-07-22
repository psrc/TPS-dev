CREATE TABLE [forms].[FormFieldOption]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormFieldOption_Id] DEFAULT (newid()),
[FormFieldId] [uniqueidentifier] NOT NULL,
[Label] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Value] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortOrder] [int] NOT NULL CONSTRAINT [DF_FormFieldOption_SortOrder] DEFAULT ((0)),
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormFieldOption_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormFieldOption_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormFieldOption] ADD CONSTRAINT [PK_FormFieldOption] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormFieldOption_FormFieldId] ON [forms].[FormFieldOption] ([FormFieldId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[FormFieldOption] ADD CONSTRAINT [FK_FormFieldOption_FormField] FOREIGN KEY ([FormFieldId]) REFERENCES [forms].[FormField] ([Id]) ON DELETE CASCADE
GO
