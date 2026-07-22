SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:      john.hunter@triskelle.solutions
-- Create date: 2025-12-17
-- Modified:    2025-12-22 - Changed to lookup by Project_Pending.Id directly
-- Modified:    2026-02-20 - Return all ProgrammedFunding records (including inactive) to match project view
-- Modified:    2026-04-28 - Added Reporting tab fields (Project_Pending.ReportDescription, ProjectAmendment.ReportDescription, 4 report flags)
-- Modified:    2026-05-05 - Section 9 returns logs across all ProjectAmendment rows for the same ProjectId so prior amendments' logs are visible in the Project Logs tab (PSRC-a83)
-- Description: Retrieves comprehensive pending project information for an amendment
--              including project details, contacts, mappings, budgets, and funding data.
--              Also returns information about other amendments containing the same project
--              and the amendment status to determine read-only mode.
-- =============================================
CREATE PROCEDURE [dbo].[pr_tip_project_amendment_pending_get]
    @UserId           UNIQUEIDENTIFIER
  , @AmendmentId      UNIQUEIDENTIFIER
  , @ProjectPendingId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Variable to hold original ProjectId for "Other Amendments" query
    DECLARE @ProjectId UNIQUEIDENTIFIER;

    -- Get the original ProjectId for this pending record (needed for Other Amendments query)
    SELECT @ProjectId = pa.ProjectId
    FROM tip.Project_Pending AS pp
    INNER JOIN tip.ProjectAmendment AS pa ON pa.Id = pp.ProjectAmendmentId
    WHERE pp.Id = @ProjectPendingId
      AND pa.AmendmentId = @AmendmentId;

    -- =============================================
    -- SECTION 1: Pending Project Information
    -- =============================================
    -- Retrieve the pending project record with ProjectAmendment details
    SELECT
        Id                                 = pp.Id
      , ProjectAmendmentId                 = pp.ProjectAmendmentId
      , AgencyId                           = pp.AgencyId
      , ProjectCode                        = pp.ProjectCode
      , Title                              = pp.Title
      , ContactId                          = pp.ContactId
      , WsDotPin                           = pp.WsDotPin
      , DemoId                             = pp.DemoId
      , Location                           = pp.Location
      , LocationFrom                       = pp.LocationFrom
      , LocationTo                         = pp.LocationTo
      , Length                             = pp.Length
      , FunctionalClassTypeId              = pp.FunctionalClassTypeId
      , PrimaryImprovementTypeId           = pp.PrimaryImprovementTypeId
      , Description                        = pp.Description
      , DateFullyImplemented               = pp.DateFullyImplemented
      , RcpStatusTypeId                    = pp.RcpStatusTypeId
      , ConstantDollarProjectYear          = pp.ConstantDollarProjectYear
      , MappedTypeId                       = pp.MappedTypeId
      , EnvironmentalStatusTypeId          = pp.EnvironmentalStatusTypeId
      , RegionalSignificanceTypeId         = pp.RegionalSignificanceTypeId
      , YearCompPL                         = pp.YearCompPL
      , YearCompPE                         = pp.YearCompPE
      , YearCompROW                        = pp.YearCompROW
      , YearCompCN                         = pp.YearCompCN
      , YearCompOther                      = pp.YearCompOther
      , DateCompProject                    = pp.DateCompProject
      , CaSponsorAgencyId                  = pp.CaSponsorAgencyId
      , CompletionStatusTypeId             = pp.CompletionStatusTypeId
      , UpwpObjective                      = pp.UpwpObjective
      , UpwpTasks                          = pp.UpwpTasks
      , UpwpProducts                       = pp.UpwpProducts
      , UpwpPolicy                         = pp.UpwpPolicy
      , UpwpIsEquipmentPurchaseFlag        = pp.UpwpIsEquipmentPurchaseFlag
      , PsrcComments                       = pp.PsrcComments
      , ReportDescription                  = pp.ReportDescription
      , CreatedById                        = pp.CreatedById
      , CreatedOn                          = pp.CreatedOn
      , UpdatedById                        = pp.UpdatedById
      , UpdatedOn                          = pp.UpdatedOn
      -- ProjectAmendment fields
      , AmendmentId                        = pa.AmendmentId
      , ProjectId                          = pa.ProjectId
      , AmendmentSectionTypeId             = pa.AmendmentSectionTypeId
      , ProjectAmendmentReviewStatusTypeId = pa.ProjectAmendmentReviewStatusTypeId
      , SponsorComments                    = pa.SponsorComments
      , PsrcAmendmentComments              = pa.PsrcComments
      , AmendmentReportDescription         = pa.ReportDescription
      , ReportProjectTrackingFlag          = pa.ReportProjectTrackingFlag
      , ReportNewProjectPhaseFlag          = pa.ReportNewProjectPhaseFlag
      , ReportUpwpFlag                     = pa.ReportUpwpFlag
      , ReportOtherAmendFlag               = pa.ReportOtherAmendFlag
      , ReviewUpdatedById                  = pa.ReviewUpdatedById
      , ReviewUpdateDate                   = pa.ReviewUpdateDate
      -- Amendment name for logs display
      , AmendmentName                      = a.Name
    FROM
        tip.Project_Pending AS pp
        INNER JOIN tip.ProjectAmendment AS pa
                ON pa.Id = pp.ProjectAmendmentId
        INNER JOIN tip.Amendment AS a
                ON a.Id = pa.AmendmentId
    WHERE
        pp.Id = @ProjectPendingId;

    -- =============================================
    -- SECTION 2: Contact Information
    -- =============================================
    -- Retrieve contact details for the pending project's contact
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
        INNER JOIN tip.Project_Pending AS pp
                ON pp.ContactId = c.Id
    WHERE
        pp.Id = @ProjectPendingId;

    -- =============================================
    -- SECTION 3: Secondary Improvement Type Mappings
    -- =============================================
    -- Get all secondary improvement types associated with this pending project
    SELECT
        Id                = pitm.Id
      , ProjectId         = pitm.ProjectId
      , ImprovementTypeId = pitm.ImprovementTypeId
      , CreatedById       = pitm.CreatedById
      , CreatedOn         = pitm.CreatedOn
      , UpdatedById       = pitm.UpdatedById
      , UpdatedOn         = pitm.UpdatedOn
    FROM
        tip.ProjectImprovementTypeMapping_Pending AS pitm
    WHERE
        pitm.ProjectId = @ProjectPendingId;

    -- =============================================
    -- SECTION 4: County Mappings
    -- =============================================
    -- Get all counties associated with this pending project
    SELECT
        Id          = pcm.Id
      , ProjectId   = pcm.ProjectId
      , CountyId    = pcm.CountyId
      , CreatedById = pcm.CreatedById
      , CreatedOn   = pcm.CreatedOn
      , UpdatedById = pcm.UpdatedById
      , UpdatedOn   = pcm.UpdatedOn
    FROM
        tip.ProjectCountyMapping_Pending AS pcm
    WHERE
        pcm.ProjectId = @ProjectPendingId;

    -- =============================================
    -- SECTION 5: Budget Information
    -- =============================================
    -- Retrieve pending project budget information
    SELECT
        Id                   = pb.Id
      , Project_PendingId    = pb.Project_PendingId
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
        tip.ProjectBudget_Pending AS pb
    WHERE
        pb.Project_PendingId = @ProjectPendingId;

    -- =============================================
    -- SECTION 6: Programmed Funding Information
    -- =============================================
    -- Get pending programmed funding details, ordered by most recent first
    SELECT
        Id                      = pf.Id
      , Project_PendingId       = pf.Project_PendingId
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
        tip.ProgrammedFunding_Pending AS pf
    WHERE
        pf.Project_PendingId = @ProjectPendingId
    ORDER BY pf.CreatedOn DESC;

    -- =============================================
    -- SECTION 7: Other Amendments Containing This Project
    -- =============================================
    -- Get list of other amendments that also contain this project (excluding current amendment)
    -- Only include amendments that are NOT in Posted status (posted amendments are finalized)
    SELECT
        AmendmentId   = a.Id
      , AmendmentName = a.Name
      , StatusCode    = ast.Code
      , StatusName    = ast.Description
    FROM
        tip.ProjectAmendment AS pa
        INNER JOIN tip.Amendment AS a
                ON a.Id = pa.AmendmentId
        INNER JOIN tip.AmendmentStatusType AS ast
                ON ast.Id = a.AmendmentStatusTypeId
    WHERE
            pa.ProjectId    = @ProjectId
        AND NOT pa.AmendmentId = @AmendmentId
        AND NOT ast.Code       = 'posted';

    -- =============================================
    -- SECTION 8: Amendment Status (for read-only determination)
    -- =============================================
    -- Get amendment status to determine if pending data should be read-only
    SELECT
        AmendmentId         = a.Id
      , AmendmentStatusCode = ast.Code
      , AmendmentStatusName = ast.Description
      , IsReadOnly          = CASE WHEN ast.Code = 'posted' THEN 1 ELSE 0 END
    FROM
        tip.Amendment AS a
        LEFT JOIN tip.AmendmentStatusType AS ast
               ON ast.Id = a.AmendmentStatusTypeId
    WHERE
        a.Id = @AmendmentId;

    -- =============================================
    -- SECTION 9: Project Amendment Logs (current + prior amendments)
    -- =============================================
    -- Return logs for every ProjectAmendment row tied to the same underlying ProjectId,
    -- plus the current pending ProjectAmendment row. This lets the Project Logs tab show
    -- the change history from prior amendments while editing inside a pending amendment.
    DECLARE @ProjectAmendmentId UNIQUEIDENTIFIER;
    SELECT @ProjectAmendmentId = ProjectAmendmentId
    FROM tip.Project_Pending
    WHERE Id = @ProjectPendingId;

    SELECT
        Id                        = pal.Id
      , ProjectAmendmentLogTypeId = pal.ProjectAmendmentLogTypeId
      , Description               = pal.Description
      , RawChanges                = pal.RawChanges
      , CreatedOn                 = pal.CreatedOn
      , CreatedByEmail            = u.Email
      , ProjectAmendmentId        = pa.Id
      , AmendmentId               = a.Id
      , AmendmentName             = a.Name
      , AmendmentStatusCode       = ast.Code
    FROM
        tip.ProjectAmendmentLog AS pal
        INNER JOIN tip.ProjectAmendment AS pa
                ON pa.Id = pal.ProjectAmendmentId
        INNER JOIN tip.Amendment AS a
                ON a.Id = pa.AmendmentId
        LEFT JOIN tip.AmendmentStatusType AS ast
                ON ast.Id = a.AmendmentStatusTypeId
        LEFT JOIN common.Users AS u
                ON u.Id = pal.CreatedById
    WHERE
            pa.Id = @ProjectAmendmentId
        OR (@ProjectId IS NOT NULL AND pa.ProjectId = @ProjectId)
    ORDER BY
        pal.CreatedOn DESC;
END;
GO
