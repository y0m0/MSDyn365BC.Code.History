page 27011 "SAT Payment Terms Subform"
{
    Caption = 'SAT Payment Terms Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Payment Terms";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the SAT payment term.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the SAT payment term.';
                }
                field("SAT Payment Term"; Rec."SAT Payment Term")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'SAT Payment Form';
                    ToolTip = 'Specifies the number of the SAT payment form. ';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CurrPage.Caption := '';
    end;
}

