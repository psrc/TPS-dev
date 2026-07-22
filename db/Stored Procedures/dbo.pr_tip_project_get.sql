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
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_get]
    @UserId          UNIQUEIDENTIFIER
        , @ProjectId UNIQUEIDENTIFIER AS
BEGIN
    SET NOCOUNT ON;

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
    FROM
        tip.ProjectAmendment AS pa
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
    FROM
        tip.ProjectTipMapping AS ptm
        INNER JOIN tip.Tip AS t ON ptm.TipId = t.Id
    WHERE
        ptm.ProjectId = @ProjectId
    ORDER BY
        t.BeginYear DESC;
END;
GO
