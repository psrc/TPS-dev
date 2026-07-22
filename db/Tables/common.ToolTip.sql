CREATE TABLE [common].[ToolTip]
(
[Id] [uniqueidentifier] NOT NULL,
[Code] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Description] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_ToolTip_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_ToolTip_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [common].[ToolTip] ADD CONSTRAINT [PK_ToolTip] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'The ToolTip table stores interactive help text and guidance content that appears when users hover over or focus on elements within HTML web pages. This table contains the tooltip messages, their associated target elements, positioning information, and display properties to provide contextual assistance and enhance user experience across web applications.
 
Primary Purpose: Centralized storage and management of dynamic tooltip content for web page elements, enabling consistent help text delivery and easy content updates without requiring code changes.', 'SCHEMA', N'common', 'TABLE', N'ToolTip', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_Description', N'A uniqueidentifier (GUID) primary key that provides a globally unique identifier for each tooltip record in the table', 'SCHEMA', N'common', 'TABLE', N'ToolTip', 'COLUMN', N'Id'
GO
