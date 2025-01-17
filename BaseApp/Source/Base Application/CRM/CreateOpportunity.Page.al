page 5126 "Create Opportunity"
{
    Caption = 'Create Opportunity';
    DataCaptionExpression = Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Opportunity;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the description of the opportunity.';
                }
                field("Creation Date"; Rec."Creation Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date that the opportunity was created.';
                }
                field(Priority; Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the priority of the opportunity. There are three options:';
                }
                field("Wizard Contact Name"; Rec."Wizard Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact';
                    Editable = WizardContactNameEditable;
                    Lookup = false;
                    TableRelation = Contact;
                    ToolTip = 'Specifies the contact who is involved in this opportunity.';

                    trigger OnAssistEdit()
                    var
                        Cont: Record Contact;
                    begin
                        if (GetFilter("Contact No.") = '') and (GetFilter("Contact Company No.") = '') then
                            if (Cont."No." = '') and ("Segment Description" = '') then begin
                                if Cont.Get("Contact No.") then;
                                if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                                    Validate("Contact No.", Cont."No.");
                                    "Wizard Contact Name" := Cont.Name;
                                end;
                            end;
                    end;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Salesperson';
                    Editable = SalespersonCodeEditable;
                    ToolTip = 'Specifies the salesperson who is responsible for the opportunity.';
                }
                field("Sales Cycle Code"; Rec."Sales Cycle Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales Cycle';
                    ToolTip = 'Specifies which sales cycle will be used to process this opportunity';
                }
                field("Wizard Campaign Description"; Rec."Wizard Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign';
                    Editable = WizardCampaignDescriptionEdita;
                    Importance = Additional;
                    Lookup = false;
                    TableRelation = Campaign;
                    ToolTip = 'Specifies the campaign that the opportunity is related to. The description is copied from the campaign card.';

                    trigger OnAssistEdit()
                    var
                        Campaign: Record Campaign;
                    begin
                        if GetFilter("Campaign No.") = '' then
                            if PAGE.RunModal(0, Campaign) = ACTION::LookupOK then begin
                                Validate("Campaign No.", Campaign."No.");
                                "Wizard Campaign Description" := Campaign.Description;
                            end;
                    end;
                }
                field("Segment Description"; Rec."Segment Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Segment';
                    Editable = false;
                    Importance = Additional;
                    Lookup = false;
                    TableRelation = "Segment Header";
                    ToolTip = 'Specifies a description of the segment that is related to the opportunity. The description is copied from the segment card.';

                    trigger OnAssistEdit()
                    var
                        SegmentHeader: Record "Segment Header";
                    begin
                        if SegHeader."No." = '' then
                            if PAGE.RunModal(0, SegmentHeader) = ACTION::LookupOK then begin
                                Validate("Segment No.", SegmentHeader."No.");
                                "Segment Description" := SegmentHeader.Description;
                            end;
                    end;
                }
            }
            group(Estimates)
            {
                Caption = 'Estimates';
                field("Activate First Stage"; Rec."Activate First Stage")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Activate the First Stage.';
                    ToolTip = 'Specifies if the opportunity is to be activated. If you select the check box, then you can fill out the remainder of the fields on this page. In the Opportunity Card window, the status is set to In Progress.';

                    trigger OnValidate()
                    begin
                        if not "Activate First Stage" then begin
                            "Wizard Estimated Value (LCY)" := 0;
                            "Wizard Chances of Success %" := 0;
                            "Wizard Estimated Closing Date" := 0D;
                        end;
                    end;
                }
                field("Wizard Estimated Value (LCY)"; Rec."Wizard Estimated Value (LCY)")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Estimated Sales Value (LCY)';
                    Enabled = "Activate First Stage";
                    ToolTip = 'Specifies the value in the wizard for the opportunity. You can specify an estimated value of the opportunity in local currency in this field.';
                }
                field("Wizard Chances of Success %"; Rec."Wizard Chances of Success %")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Chances of Success (%)';
                    DecimalPlaces = 0 : 0;
                    Enabled = "Activate First Stage";
                    MaxValue = 100;
                    ToolTip = 'Specifies the value in the wizard for the opportunity. You can specify a percentage completion estimate in this field.';
                }
                field("Wizard Estimated Closing Date"; Rec."Wizard Estimated Closing Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Estimated Closing Date';
                    Enabled = "Activate First Stage";
                    ToolTip = 'Specifies a closing date for the opportunity from the wizard.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(FinishWizard)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Finish';
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Finish creating the opportunity.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    FinishPage();
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(FinishWizard_Promoted; FinishWizard)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        WizardContactNameOnFormat(Format("Wizard Contact Name"));
    end;

    trigger OnInit()
    begin
        SalespersonCodeEditable := true;
        WizardCampaignDescriptionEdita := true;
        WizardContactNameEditable := true;
    end;

    trigger OnOpenPage()
    begin
        IsOnMobile := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            FinishPage();
    end;

    var
        Cont: Record Contact;
        SalesPurchPerson: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        SegHeader: Record "Segment Header";
        ClientTypeManagement: Codeunit "Client Type Management";
        [InDataSet]
        WizardContactNameEditable: Boolean;
        [InDataSet]
        SalespersonCodeEditable: Boolean;
        [InDataSet]
        WizardCampaignDescriptionEdita: Boolean;
        IsOnMobile: Boolean;

        Text000: Label '(Multiple)';
        Text001: Label 'untitled';

    procedure Caption(): Text
    var
        CaptionStr: Text;
    begin
        if Cont.Get(GetFilter("Contact Company No.")) then
            CaptionStr := CopyStr(Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if Cont.Get(GetFilter("Contact No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if SalesPurchPerson.Get(GetFilter("Salesperson Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SalesPurchPerson.Code + ' ' + SalesPurchPerson.Name, 1, MaxStrLen(CaptionStr));
        if Campaign.Get(GetFilter("Campaign No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Campaign."No." + ' ' + Campaign.Description, 1, MaxStrLen(CaptionStr));
        if SegHeader.Get(GetFilter("Segment No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SegHeader."No." + ' ' + SegHeader.Description, 1, MaxStrLen(CaptionStr));
        if CaptionStr = '' then
            CaptionStr := Text001;

        exit(CaptionStr);
    end;

    local procedure WizardContactNameOnFormat(Text: Text[1024])
    begin
        if SegHeader.Get(GetFilter("Segment No.")) then
            Text := Text000;
    end;

    local procedure FinishPage()
    begin
        CheckStatus();
        FinishWizard();
    end;
}

