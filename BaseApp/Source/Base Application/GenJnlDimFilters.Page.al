page 482 "Gen. Jnl. Dim. Filters"
{
    Caption = 'Gen. Jnl. Dim. Filters';
    DelayedInsert = true;
    PageType = List;
    ShowFilter = false;
    SourceTable = "Gen. Jnl. Dim. Filter";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Dimension Code"; "Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the dimension.';
                }
                field("Dimension Value Filter"; "Dimension Value Filter")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the filter for the dimension values.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimensionValue: Record "Dimension Value";
                    begin
                        exit(DimensionValue.LookUpDimFilter("Dimension Code", Text));
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        GenJnlDimFilter: Record "Gen. Jnl. Dim. Filter";
    begin
        GenJnlDimFilter.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJnlDimFilter.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJnlDimFilter.SetRange("Journal Line No.", GenJournalLine."Line No.");
        if GenJnlDimFilter.FindSet() then
            repeat
                Init();
                TransferFields(GenJnlDimFilter);
                Insert();
            until GenJnlDimFilter.Next() = 0;
    end;

    trigger OnClosePage()
    var
        GenJnlDimFilter: Record "Gen. Jnl. Dim. Filter";
    begin
        GenJnlDimFilter.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJnlDimFilter.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJnlDimFilter.SetRange("Journal Line No.", GenJournalLine."Line No.");
        GenJnlDimFilter.DeleteAll();
        if FindSet() then
            repeat
                GenJnlDimFilter.Init();
                GenJnlDimFilter.TransferFields(Rec);
                GenJnlDimFilter."Journal Template Name" := GenJournalLine."Journal Template Name";
                GenJnlDimFilter."Journal Batch Name" := GenJournalLine."Journal Batch Name";
                GenJnlDimFilter."Journal Line No." := GenJournalLine."Line No.";
                GenJnlDimFilter.Insert();
            until Next() = 0;
    end;

    var
        GenJournalLine: Record "Gen. Journal Line";

    procedure SetGenJnlLine(var NewGenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.Copy(NewGenJournalLine);
    end;
}