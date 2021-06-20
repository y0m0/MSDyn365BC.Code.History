table 5487 "Balance Sheet Buffer"
{
    Caption = 'Balance Sheet Buffer';
    ReplicateData = false;
    // TableType = Temporary;
    ObsoleteState = Pending;
    ObsoleteReason = 'Table will be marked as TableType=Temporary. Make sure you are not using this table to store records';
    ObsoleteTag = '17.0';

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(3; Balance; Decimal)
        {
            Caption = 'Balance';
            DataClassification = SystemMetadata;
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        field(6; "Line Type"; Text[30])
        {
            Caption = 'Line Type';
            DataClassification = SystemMetadata;
        }
        field(7; Indentation; Integer)
        {
            Caption = 'Indentation';
            DataClassification = SystemMetadata;
        }
        field(8000; Id; Guid)
        {
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Id)
        {
        }
    }

    fieldgroups
    {
    }
}

