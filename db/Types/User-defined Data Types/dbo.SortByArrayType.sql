CREATE TYPE [dbo].[SortByArrayType] AS TABLE
(
[SortColumn] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[SortDirection] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
)
GO
