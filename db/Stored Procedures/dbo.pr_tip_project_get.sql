SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2025-07-23
-- Description: Retrieves comprehensive project information including
--              project details, contacts, mappings, budgets, amendments,
--              and funding data for a specified project.
-- Modified:
--   2026-02-19  Added MostRecentTipId to core project query.
--               Expanded Section 6 to include TIP details (label,
--               description, years, IsCurrent) for project TIP list dialog.
--   2026-04-28  Added ReportDescription to project select and Reporting tab fields
--               (ReportDescription + 4 flags) to amendment select.
--   2026-09-07  PSRC-r2j5 - added IsPending to the Section 6 TIP details so the
--               project TIP list dialog can distinguish the TIP being programmed
--               next from the one currently in effect.
--   2026-09-10  PSRC-lqwf - Section 5 returns ProjectPendingId (the project's id inside
--               each amendment) so the warning banner can link straight to it.
--   2026-09-10  PSRC-a8e5 - Returns each funding row's LineageId, and Section 7 maps every
--               audit-log fundingRowId to a lineage for the per-row history viewer.
-- Modified:    2026-09-12 - PSRC-mte.1 tenancy scoping (@TenantAgencyId/@BypassTenancy)
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_get]
    @UserId          UNIQUEIDENTIFIER
        , @ProjectId UNIQUEIDENTIFIER
        , @TenantAgencyId UNIQUEIDENTIFIER = NULL -- PSRC-mte.1: caller's agency (NULL = none)
        , @BypassTenancy  BIT              = 0    -- PSRC-mte.1: 1 = internal caller, no scoping
AS
BEGIN
    SET NOCOUNT ON;
    -- PSRC-mte.1: a scoped caller may only touch a project in their own agency.
    IF @BypassTenancy = 0 AND NOT EXISTS (SELECT 1 FROM tip.Project WHERE Id = @ProjectId AND AgencyId = @TenantAgencyId)
        THROW 50403, 'Tenancy: project is not in the caller''s agency.', 1;

    -- =============================================
    -- SECTION 1: Core Project Information
    -- =============================================
    -- Retrieve the main project record with all core attributes
    SELECT
        Id                          = p.Id
      , AgencyId                    = p.AgencyId
      , ProjectCode                 = p.ProjectCode
      , Title                       = p.Title
      , ContactId                   = p.ContactId
      , WsDotPin                    = p.WsDotPin
      , DemoId                      = p.DemoId
      , Location                    = p.Location
      , LocationFrom                = p.LocationFrom
      , LocationTo                  = p.LocationTo
      , Length                      = p.Length
      , FunctionalClassTypeId       = p.FunctionalClassTypeId
      , PrimaryImprovementTypeId    = p.PrimaryImprovementTypeId
      , Description                 = p.Description
      , DateFullyImplemented        = p.DateFullyImplemented
      , RcpStatusTypeId             = p.RcpStatusTypeId
      , ConstantDollarProjectYear   = p.ConstantDollarProjectYear
      , MappedTypeId                = p.MappedTypeId
      , EnvironmentalStatusTypeId   = p.EnvironmentalStatusTypeId
      , RegionalSignificanceTypeId  = p.RegionalSignificanceTypeId
      , YearCompPL                  = p.YearCompPL
      , YearCompPE                  = p.YearCompPE
      , YearCompROW                 = p.YearCompROW
      , YearCompCN                  = p.YearCompCN
      , YearCompOther               = p.YearCompOther
      , CaSponsorAgencyId           = p.CaSponsorAgencyId
      , CompletionStatusTypeId      = p.CompletionStatusTypeId
      , UpwpObjective               = p.UpwpObjective
      , UpwpTasks                   = p.UpwpTasks
      , UpwpProducts                = p.UpwpProducts
      , UpwpPolicy                  = p.UpwpPolicy
      , UpwpIsEquipmentPurchaseFlag = p.UpwpIsEquipmentPurchaseFlag
      , PsrcComments                = p.PsrcComments
      , ReportDescription           = p.ReportDescription
      , CreatedById                 = p.CreatedById
      , CreatedOn                   = p.CreatedOn
      , UpdatedById                 = p.UpdatedById
      , UpdatedOn                   = p.UpdatedOn
      , MostRecentTip               = mrt.TipLabel
      , MostRecentTipId             = mrt.TipId
    FROM
        tip.Project AS p
    OUTER APPLY (
        SELECT TOP (1)
            TipLabel = CONCAT(
                RIGHT(CAST(t.BeginYear AS VARCHAR(4)), 2),
                '-',
                RIGHT(CAST(t.EndYear AS VARCHAR(4)), 2)
            )
          , TipId = t.Id
        FROM tip.ProjectTipMapping AS ptm
        INNER JOIN tip.Tip AS t ON ptm.TipId = t.Id
        WHERE ptm.ProjectId = p.Id
        ORDER BY t.BeginYear DESC
    ) AS mrt
    WHERE
        p.Id = @ProjectId;

    -- =============================================
    -- SECTION 2: Project Contact Information
    -- =============================================
    -- Retrieve contact details for the project's primary contact
    SELECT
        Id          = c.Id
      , FirstName   = c.FirstName
      , LastName    = c.LastName
      , Email       = c.Email
      , Phone       = c.Phone
      , PhoneExt    = c.PhoneExt
      , AgencyId    = c.AgencyId
      , IsActive    = c.IsActive
      , Notes       = c.Notes
      , CreatedById = c.CreatedById
      , CreatedOn   = c.CreatedOn
      , UpdatedById = c.UpdatedById
      , UpdatedOn   = c.UpdatedOn
    FROM
        common.Contact AS c
        INNER JOIN tip.Project AS p
                ON p.ContactId = c.Id
    WHERE
        p.Id = @ProjectId;

    -- =============================================
    -- SECTION 3: Project Type and Location Mappings
    -- =============================================
    -- Get all secondary improvement types associated with this project
    SELECT
        Id                = pitm.Id
      , ProjectId         = pitm.ProjectId
      , ImprovementTypeId = pitm.ImprovementTypeId
      , CreatedById       = pitm.CreatedById
      , CreatedOn         = pitm.CreatedOn
      , UpdatedById       = pitm.UpdatedById
      , UpdatedOn         = pitm.UpdatedOn
    FROM
        tip.ProjectImprovementTypeMapping AS pitm
    WHERE
        pitm.ProjectId = @ProjectId;

    -- Get all counties associated with this project
    SELECT
        Id          = pcm.Id
      , ProjectId   = pcm.ProjectId
      , CountyId    = pcm.CountyId
      , CreatedById = pcm.CreatedById
      , CreatedOn   = pcm.CreatedOn
      , UpdatedById = pcm.UpdatedById
      , UpdatedOn   = pcm.UpdatedOn
    FROM
        tip.ProjectCountyMapping AS pcm
    WHERE
        pcm.ProjectId = @ProjectId;

    -- =============================================
    -- SECTION 4: Financial Information
    -- =============================================
    -- Retrieve project budget information
    SELECT
        Id                   = pb.Id
      , ProjectId            = pb.ProjectId
      , FundingSourceTypeId  = pb.FundingSourceTypeId
      , PLSecuredAmount      = pb.PLSecuredAmount
      , PLUnsecuredAmount    = pb.PLUnsecuredAmount
      , PLTotalAmount        = pb.PLTotalAmount
      , PESecuredAmount      = pb.PESecuredAmount
      , PEUnsecuredAmount    = pb.PEUnsecuredAmount
      , PETotalAmount        = pb.PETotalAmount
      , ROWSecuredAmount     = pb.ROWSecuredAmount
      , ROWUnsecuredAmount   = pb.ROWUnsecuredAmount
      , ROWTotalAmount       = pb.ROWTotalAmount
      , CNSecuredAmount      = pb.CNSecuredAmount
      , CNUnsecuredAmount    = pb.CNUnsecuredAmount
      , CNTotalAmount        = pb.CNTotalAmount
      , OtherSecuredAmount   = pb.OtherSecuredAmount
      , OtherUnsecuredAmount = pb.OtherUnsecuredAmount
      , OtherTotalAmount     = pb.OtherTotalAmount
      , TotalSecuredAmount   = pb.TotalSecuredAmount
      , TotalUnsecuredAmount = pb.TotalUnsecuredAmount
      , TotalAmount          = pb.TotalAmount
      , CreatedById          = pb.CreatedById
      , CreatedOn            = pb.CreatedOn
      , UpdatedById          = pb.UpdatedById
      , UpdatedOn            = pb.UpdatedOn
    FROM
        tip.ProjectBudget AS pb
    WHERE
        pb.ProjectId = @ProjectId;

    -- Get programmed funding details, ordered by most recent first
    SELECT
        Id                      = pf.Id
      , ProjectId               = pf.ProjectId
      , AwardReferenceId        = pf.AwardReferenceId
      , PhaseTypeId             = pf.PhaseTypeId
      , ProgrammedFundingYear   = pf.ProgrammedFundingYear
      , EstimatedObligationDate = pf.EstimatedObligationDate
      , FundingSourceTypeId     = pf.FundingSourceTypeId
      , FundingAmount           = pf.FundingAmount
      , IsObligatedFlag         = pf.IsObligatedFlag
      , FtaObligatedDate        = pf.FtaObligatedDate
      , FtaObligatedNumber      = pf.FtaObligatedNumber
      , FhwaObligatedDate       = pf.FhwaObligatedDate
      , FhwaObligatedNumber     = pf.FhwaObligatedNumber
      , OriginRecordId          = pf.OriginRecordId
      , LineageId               = pf.LineageId
      , IsActive                = pf.IsActive
      , CreatedById             = pf.CreatedById
      , CreatedOn               = pf.CreatedOn
      , UpdatedById             = pf.UpdatedById
      , UpdatedOn               = pf.UpdatedOn
    FROM
        tip.ProgrammedFunding AS pf
    WHERE
        pf.ProjectId = @ProjectId
    ORDER BY pf.CreatedOn DESC;

    -- =============================================
    -- SECTION 5: Amendment Information
    -- =============================================
    -- Get project amendment records
    SELECT
        Id                                 = pa.Id
      , ProjectId                          = pa.ProjectId
      , AmendmentId                        = pa.AmendmentId
      , AmendmentSectionTypeId             = pa.AmendmentSectionTypeId
      , ProjectAmendmentReviewStatusTypeId = pa.ProjectAmendmentReviewStatusTypeId
      , SponsorComments                    = pa.SponsorComments
      , PsrcComments                       = pa.PsrcComments
      , ReportDescription                  = pa.ReportDescription
      , ReportProjectTrackingFlag          = pa.ReportProjectTrackingFlag
      , ReportNewProjectPhaseFlag          = pa.ReportNewProjectPhaseFlag
      , ReportUpwpFlag                     = pa.ReportUpwpFlag
      , ReportOtherAmendFlag               = pa.ReportOtherAmendFlag
      , ReviewUpdatedById                  = pa.ReviewUpdatedById
      , ReviewUpdateDate                   = pa.ReviewUpdateDate
      , CreatedById                        = pa.CreatedById
      , CreatedOn                          = pa.CreatedOn
      , UpdatedById                        = pa.UpdatedById
      , UpdatedOn                          = pa.UpdatedOn
        -- PSRC-lqwf: each amendment holds its own Project_Pending row (1:1 with ProjectAmendment),
        -- and that id is what the amendment's route needs to open this project directly.
      , ProjectPendingId                   = pp.Id
    FROM
        tip.ProjectAmendment AS pa
        LEFT JOIN tip.Project_Pending AS pp
               ON pp.ProjectAmendmentId = pa.Id
    WHERE
        pa.ProjectId = @ProjectId;

    -- Get amendment log entries for this project
    SELECT
        Id                        = pal.Id
      , ProjectAmendmentId        = pal.ProjectAmendmentId
      , ProjectAmendmentLogTypeId = pal.ProjectAmendmentLogTypeId
      , SourceRecordId            = pal.SourceRecordId
      , Description               = pal.Description
      , RawChanges                = pal.RawChanges
      , CreatedById               = pal.CreatedById
      , CreatedOn                 = pal.CreatedOn
      , UpdatedById               = pal.UpdatedById
      , UpdatedOn                 = pal.UpdatedOn
      , CreatedByEmail            = ISNULL(u.Email, 'Unknown User')
    FROM
        tip.ProjectAmendmentLog AS pal
        INNER JOIN tip.ProjectAmendment AS pa
                ON pa.Id = pal.ProjectAmendmentId
        LEFT JOIN common.Users AS u
                ON u.Id = pal.CreatedById
    WHERE
        pa.ProjectId = @ProjectId;

    -- Get amendment details for this project
    SELECT
        Id                            = a.Id
      , AmendmentStatusTypeId         = a.AmendmentStatusTypeId
      , Name                          = a.Name
      , PsrcDueDate                   = a.PsrcDueDate
      , TpbReviewDate                 = a.TpbReviewDate
      , WsdotDueDate                  = a.WsdotDueDate
      , WsdotSubmittedDate            = a.WsdotSubmittedDate
      , WsdotPostedDate               = a.WsdotPostedDate
      , AmendmentMappedTypeId         = a.AmendmentMappedTypeId
      , IsAdministrativeAmendmentFlag = a.IsAdministrativeAmendmentFlag
      , CreatedById                   = a.CreatedById
      , CreatedOn                     = a.CreatedOn
      , UpdatedById                   = a.UpdatedById
      , UpdatedOn                     = a.UpdatedOn
    FROM
        tip.Amendment AS a
        INNER JOIN tip.ProjectAmendment AS pa
                ON pa.AmendmentId = a.Id
    WHERE
        pa.ProjectId = @ProjectId;

    -- =============================================
    -- SECTION 6: TIP Information
    -- =============================================
    -- Get project tip records with TIP details
    SELECT
        Id          = ptm.Id
      , ProjectId   = ptm.ProjectId
      , TipId       = ptm.TipId
      , TipLabel    = CONCAT(
            RIGHT(CAST(t.BeginYear AS VARCHAR(4)), 2),
            '-',
            RIGHT(CAST(t.EndYear AS VARCHAR(4)), 2)
        )
      , Description = t.Description
      , BeginYear   = t.BeginYear
      , EndYear     = t.EndYear
      , IsCurrent   = t.IsCurrent
      , IsPending   = t.IsPending
    FROM
        tip.ProjectTipMapping AS ptm
        INNER JOIN tip.Tip AS t ON ptm.TipId = t.Id
    WHERE
        ptm.ProjectId = @ProjectId
    ORDER BY
        t.BeginYear DESC;

    -- =============================================
    -- SECTION 7: Funding-row lineage map (PSRC-a8e5)
    -- =============================================
    -- Audit logs key a funding change by fundingRowId, which is the row's OriginRecordId (or its
    -- own Id for a split half) AS IT WAS in that amendment - and every amendment re-keys origins.
    -- This maps each key back to the row's LineageId (PSRC-yh7o), so the client can follow one
    -- funding row through every amendment's log. Keys are lower-case to match
    -- AuditLogService.FundingRowKey. AmendmentId NULL = a posted row, the fallback for edits made
    -- to the posted project directly (logged under an Admin- amendment with no pending rows).
    SELECT DISTINCT
        AmendmentId  = pa.AmendmentId
      , FundingRowId = LOWER(CAST(k.RowKey AS NVARCHAR(36)))
      , LineageId    = pf.LineageId
    FROM
        tip.ProjectAmendment AS pa
        INNER JOIN tip.Project_Pending AS pp
                ON pp.ProjectAmendmentId = pa.Id
        INNER JOIN tip.ProgrammedFunding_Pending AS pf
                ON pf.Project_PendingId = pp.Id
        CROSS APPLY (VALUES (pf.Id), (pf.OriginRecordId)) AS k (RowKey)
    WHERE
            pa.ProjectId  = @ProjectId
        AND pf.LineageId IS NOT NULL
    UNION
    SELECT
        AmendmentId  = NULL
      , FundingRowId = LOWER(CAST(k.RowKey AS NVARCHAR(36)))
      , LineageId    = pf.LineageId
    FROM
        tip.ProgrammedFunding AS pf
        CROSS APPLY (VALUES (pf.Id), (pf.OriginRecordId)) AS k (RowKey)
    WHERE
            pf.ProjectId  = @ProjectId
        AND pf.LineageId IS NOT NULL;

END;


GO
