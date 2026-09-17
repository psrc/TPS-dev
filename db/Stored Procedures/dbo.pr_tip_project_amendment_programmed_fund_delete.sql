SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Modified:    2026-09-12 - PSRC-mte.1 tenancy scoping (@TenantAgencyId/@BypassTenancy)
-- Create date: 2026-09-07
-- Description: Permanently removes a programmed funding row that was added inside the current
--              amendment, along with every version of it (Asana TIP-021, PSRC-gj2o).
--
-- Purpose:     The Remove button on the Programmed Funds tab is a hard delete, on the reading
--              that the row "never should have existed" in this amendment. That is only ever
--              true of rows added in the amendment itself: a row carried over from the posted
--              project is superseded by setting IsActive = 0, never deleted, because the posted
--              data still refers to it.
--
--              Deletion is by origin group rather than by single row. Editing a row archives it
--              and inserts a replacement, so an amendment addition that has been edited is
--              several rows sharing one OriginRecordId; removing only the live one would strand
--              its history as unreachable rows.
--
--              This is a separate procedure rather than a delete-by-omission step inside
--              pr_tip_project_amendment_pending_update deliberately. That procedure archives and
--              re-inserts edited rows under fresh ids partway through, so any "delete what the
--              payload no longer mentions" rule there would be ordering-dependent and could
--              destroy rows the client still holds.
--
-- Guards:      Refuses when the amendment is already posted, when the row does not belong to the
--              given pending project, and when the row was not added in this amendment.
-- =============================================
CREATE   PROCEDURE [dbo].[pr_tip_project_amendment_programmed_fund_delete]
    @UserId                 UNIQUEIDENTIFIER -- ID of the user performing the delete
  , @AmendmentId            UNIQUEIDENTIFIER -- Amendment containing the project
  , @ProjectPendingId       UNIQUEIDENTIFIER -- Pending project the row belongs to
  , @ProgrammedFundingId    UNIQUEIDENTIFIER -- Row the user pressed Remove on
  , @TenantAgencyId         UNIQUEIDENTIFIER = NULL -- PSRC-mte.1: caller's agency (NULL = none)
  , @BypassTenancy          BIT              = 0    -- PSRC-mte.1: 1 = internal caller, no scoping
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- PSRC-mte.1: a scoped caller may only touch a pending project in their own agency.
    IF @BypassTenancy = 0 AND NOT EXISTS (SELECT 1 FROM tip.Project_Pending WHERE Id = @ProjectPendingId AND AgencyId = @TenantAgencyId)
        THROW 50403, 'Tenancy: pending project is not in the caller''s agency.', 1;

    -- =============================================
    -- VALIDATE AMENDMENT STATUS
    -- =============================================
    -- Check that the amendment is not posted (posted amendments are read-only)
    DECLARE @AmendmentStatusCode NVARCHAR(100);

    SELECT @AmendmentStatusCode = ast.Code
    FROM tip.Amendment AS a
    INNER JOIN tip.AmendmentStatusType AS ast ON ast.Id = a.AmendmentStatusTypeId
    WHERE a.Id = @AmendmentId;

    IF @AmendmentStatusCode = 'posted'
    BEGIN
        RAISERROR('Cannot remove programmed funding from a posted amendment.', 16, 1);
        RETURN;
    END

    DECLARE @OriginRecordId UNIQUEIDENTIFIER;
    DECLARE @IsAmendmentAddition BIT;

    SELECT
        @OriginRecordId      = pf.OriginRecordId
      , @IsAmendmentAddition = pf.IsAmendmentAddition
    FROM tip.ProgrammedFunding_Pending AS pf
    WHERE pf.Id = @ProgrammedFundingId
      AND pf.Project_PendingId = @ProjectPendingId;

    IF @OriginRecordId IS NULL
    BEGIN
        RAISERROR('Programmed funding row not found on this pending project.', 16, 1);
        RETURN;
    END

    IF @IsAmendmentAddition = 0
    BEGIN
        RAISERROR('Only rows added in the current amendment can be removed.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

        DELETE pf
        FROM tip.ProgrammedFunding_Pending AS pf
        WHERE pf.Project_PendingId = @ProjectPendingId
          AND pf.IsAmendmentAddition = 1
          AND (pf.OriginRecordId = @OriginRecordId OR pf.Id = @OriginRecordId);

    COMMIT TRANSACTION;
END


GO
