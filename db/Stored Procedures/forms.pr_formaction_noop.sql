SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS OFF
GO
-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2026-07-05
-- Description: No-op form action used to exercise the workflow transition
--              stored-procedure runner end-to-end. Contract for all
--              forms.pr_formaction_* procedures: exactly these two parameters.
-- Parameters:  @UserId           - the user who executed the transition
--              @FormAssignmentId - the assignment that transitioned
-- Returns:     0
-- =============================================
CREATE PROCEDURE [forms].[pr_formaction_noop]
(
    @UserId           UNIQUEIDENTIFIER
,   @FormAssignmentId UNIQUEIDENTIFIER
) AS
BEGIN
    SET NOCOUNT ON;
    RETURN 0;
END;
GO
