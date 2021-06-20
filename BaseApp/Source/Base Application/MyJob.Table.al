table 9154 "My Job"
{
    Caption = 'My Job';

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            NotBlank = true;
            TableRelation = Job;
        }
        field(3; "Exclude from Business Chart"; Boolean)
        {
            Caption = 'Exclude from Business Chart';
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            InitValue = Open;
            OptionCaption = 'Planning,Quote,Open,Completed';
            OptionMembers = Planning,Quote,Open,Completed;
        }
        field(6; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
        }
        field(7; "Percent Completed"; Decimal)
        {
            Caption = 'Percent Completed';
        }
        field(8; "Percent Invoiced"; Decimal)
        {
            Caption = 'Percent Invoiced';
        }
    }

    keys
    {
        key(Key1; "User ID", "Job No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

