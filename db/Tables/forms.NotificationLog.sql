CREATE TABLE [forms].[NotificationLog]
(
[Id] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormsNotificationLog_Id] DEFAULT (newid()),
[NotificationType] [nvarchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RecipientUserId] [uniqueidentifier] NULL,
[RecipientEmail] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[AssignmentId] [uniqueidentifier] NULL,
[SentDate] [datetime2] NULL,
[DeliveryStatus] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[RetryCount] [int] NOT NULL CONSTRAINT [DF_FormsNotificationLog_RetryCount] DEFAULT ((0)),
[ErrorMessage] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CreatedById] [uniqueidentifier] NOT NULL CONSTRAINT [DF_FormsNotificationLog_CreatedById] DEFAULT (user_name()),
[CreatedOn] [datetime2] NOT NULL CONSTRAINT [DF_FormsNotificationLog_CreatedOn] DEFAULT (getutcdate()),
[UpdatedById] [uniqueidentifier] NULL,
[UpdatedOn] [datetime2] NULL
) ON [PRIMARY]
GO
ALTER TABLE [forms].[NotificationLog] ADD CONSTRAINT [PK_FormsNotificationLog] PRIMARY KEY CLUSTERED ([Id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormsNotificationLog_AssignmentId] ON [forms].[NotificationLog] ([AssignmentId]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormsNotificationLog_DeliveryStatus_RetryCount] ON [forms].[NotificationLog] ([DeliveryStatus], [RetryCount]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_FormsNotificationLog_RecipientUserId] ON [forms].[NotificationLog] ([RecipientUserId]) ON [PRIMARY]
GO
ALTER TABLE [forms].[NotificationLog] ADD CONSTRAINT [FK_FormsNotificationLog_FormAssignment] FOREIGN KEY ([AssignmentId]) REFERENCES [forms].[FormAssignment] ([Id])
GO
