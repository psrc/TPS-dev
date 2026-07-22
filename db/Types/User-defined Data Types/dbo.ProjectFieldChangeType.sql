CREATE TYPE [dbo].[ProjectFieldChangeType] AS TABLE
(
[FieldName] [nvarchar] (200) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[OldValue] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NewValue] [nvarchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[OldValueDisplay] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NewValueDisplay] [nvarchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FieldCategory] [nvarchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)
GO
