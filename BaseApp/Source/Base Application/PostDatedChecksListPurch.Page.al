page 28093 "Post Dated Checks List-Purch."
{
    ApplicationArea = Basic, Suite;
    Caption = 'Post Dated Checks';
    CardPageID = "Post Dated Checks-Purchases";
    PageType = List;
    SourceTable = "Post Dated Check Line";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1500004)
            {
                Editable = false;
                ShowCaption = false;
                field("Check Date"; "Check Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the post-dated check when it is supposed to be banked.';
                }
                field("Check No."; "Check No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the check No. for the post-dated check.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the post-dated check.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Amount of the post-dated check.';
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculated amount in LCY.';
                }
                field("Date Received"; "Date Received")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when we received the post-dated check.';
                }
                field(Comment; Comment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the comment for the transaction for your reference.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1905532107; "Dimensions FactBox")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Check)
            {
                Caption = 'Check';
                Image = Check;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View more information about the selected line.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Post Dated Checks-Purchases", Rec);
                    end;
                }
            }
        }
        area(processing)
        {
            action("Vendor Card")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Vendor Card';
                Image = Vendor;
                Promoted = false;
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = Process;
                RunObject = Page "Vendor Card";
                ToolTip = 'View more information for the vendor.';
            }
        }
    }
}

