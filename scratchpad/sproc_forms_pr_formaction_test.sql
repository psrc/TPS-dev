use TPS_dev
go

drop procedure if exists forms.pr_formaction_test;
drop table if exists forms.test_cpeak;

create table forms.test_cpeak (
    field1 int identity,
    field2 varchar(10)
)
go


SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:     Chris Peak 
-- Create date: 2026-09-10
-- Description: test procedure, used in development and testing phases only
--              modeled on forms.pr_formaction_noop
--              forms.pr_formaction_* procedures: exactly these two parameters.
-- Parameters:  @UserId           - the user who executed the transition
--              @FormAssignmentId - the assignment that transitioned
-- Returns:     0
-- =============================================
CREATE PROCEDURE [forms].[pr_formaction_test]
(
    @UserId           UNIQUEIDENTIFIER
,   @FormAssignmentId UNIQUEIDENTIFIER
) AS
BEGIN
    SET NOCOUNT ON;

    insert into forms.test_cpeak (field2) 
    values ('test_val')
    RETURN 0;
END;
GO

select *
from forms.test_cpeak

exec forms.pr_formaction_test