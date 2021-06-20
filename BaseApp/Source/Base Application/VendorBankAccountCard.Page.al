page 425 "Vendor Bank Account Card"
{
    Caption = 'Vendor Bank Account Card';
    PageType = Card;
    SourceTable = "Vendor Bank Account";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify this vendor bank account.';
                }
                field("Payment Form"; "Payment Form")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how payments are made. The different payment forms are used for different types of payment.';

                    trigger OnValidate()
                    begin
                        TestField(Code);
                        CurrPage.SaveRecord;
                        UpdateView;
                    end;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = NameEnable;
                    ToolTip = 'Specifies the name of the bank where the vendor has this bank account.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType;
                    end;
                }
                field(Address; Address)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = AddressEnable;
                    ToolTip = 'Specifies the address of the bank where the vendor has the bank account.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType;
                    end;
                }
                field("Address 2"; "Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = Address2Enable;
                    ToolTip = 'Specifies additional address information.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = PostCodeEnable;
                    ToolTip = 'Specifies the postal code.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType;
                    end;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = CountryRegionCodeEnable;
                    ToolTip = 'Specifies the country/region of the address.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType;
                    end;
                }
                field("Phone No."; "Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = PhoneNoEnable;
                    ToolTip = 'Specifies the telephone number of the bank where the vendor has the bank account.';
                }
                field(Contact; Contact)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ContactEnable;
                    ToolTip = 'Specifies the name of the bank employee regularly contacted in connection with this bank account.';
                }
                field(City; City)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = CityEnable;
                    ToolTip = 'Specifies the city of the bank where the vendor has the bank account.';
                }
            }
            group(Communication)
            {
                Caption = 'Communication';
                field("Bank Branch No."; "Bank Branch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank branch.';
                }
                field("Bank Account No."; "Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = BankAccountNoEnable;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';

                    trigger OnValidate()
                    begin
                        UpdateView;
                    end;
                }
                field("Transit No."; "Transit No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank identification number of your own choice.';
                }
                field("Fax No."; "Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = FaxNoEnable;
                    Importance = Additional;
                    ToolTip = 'Specifies the fax number of the bank where the vendor has the bank account.';
                }
                field("E-Mail"; "E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = EMailEnable;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address associated with the bank account.';
                }
                field("Home Page"; "Home Page")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = HomePageEnable;
                    ToolTip = 'Specifies the bank web site.';
                }
            }
            group(Transfer)
            {
                Caption = 'Transfer';
                field(PaymentForm2; "Payment Form")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how payments are made. The different payment forms are used for different types of payment.';

                    trigger OnValidate()
                    begin
                        TestField(Code);
                        CurrPage.SaveRecord;
                        UpdateView;
                    end;
                }
                field("SWIFT Code"; "SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = SWIFTCodeEnable;
                    ToolTip = 'Specifies the SWIFT code (international bank identifier code) of the bank where the vendor has the account.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType;
                    end;
                }
                field("Clearing No."; "Clearing No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ClearingNoEnable;
                    ToolTip = 'Specifies the clearing number for the supplier''s bank.';

                    trigger OnValidate()
                    begin
                        UpdateView;
                    end;
                }
                field("Giro Account No."; "Giro Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = GiroAccountNoEnable;
                    ToolTip = 'Specifies the vendor''s giro account no.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType;
                    end;
                }
                field("ESR Type"; "ESR Type")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ESRTypeEnable;
                    ToolTip = 'Specifies, for ESR and ESR+, you can define the format of account numbers and reference numbers for this vendor.';
                }
                field("ESR Account No."; "ESR Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = ESRAccountNoEnable;
                    ToolTip = 'Specifies the vendor''s ESR account number.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType;
                    end;
                }
                field("Invoice No. Startposition"; "Invoice No. Startposition")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = InvoiceNoStartpositionEnable;
                    ToolTip = 'Specifies the position of the invoice number within the reference number.';
                }
                field("Invoice No. Length"; "Invoice No. Length")
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = InvoiceNoLengthEnable;
                    ToolTip = 'Specifies the length of the invoice number in the reference number.';
                }
                field("Balance Account No."; "Balance Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that when processing an invoice, for this bank account, the balance account you enter here will be suggested.';
                }
                field("Debit Bank"; "Debit Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a debit bank can be predefined, which should be used for this vendor bank.';
                }
                field("Bank Identifier Code"; "Bank Identifier Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies this is used if a payment is made to a foreign bank.';
                    Visible = false;
                }
                field(IBAN; IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IBANEnable;
                    ToolTip = 'Specifies the bank account''s international bank account number.';

                    trigger OnValidate()
                    begin
                        UpdateView;
                    end;
                }
                field("Payment Fee Code"; "Payment Fee Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment fee code to be used for this vendor bank account.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';

                    trigger OnValidate()
                    begin
                        UpdateSuggestedSwissPaymentType;
                    end;
                }
                field("Bank Clearing Standard"; "Bank Clearing Standard")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format standard to be used in bank transfers if you use the Bank Clearing Code field to identify you as the sender.';
                }
                field("Bank Clearing Code"; "Bank Clearing Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for bank clearing that is required according to the format standard you selected in the Bank Clearing Standard field.';
                }
                field(SuggestedSwissPaymentType; SuggestedSwissPaymentType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Suggested Swiss SEPA CT Export Payment Type';
                    Editable = false;
                    ToolTip = 'Specifies the suggested payment type for swiss SEPA CT exports.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        UpdateView;
    end;

    trigger OnInit()
    begin
        TransitNoEnable := true;
        SWIFTCodeEnable := true;
        HomePageEnable := true;
        EMailEnable := true;
        FaxNoEnable := true;
        ContactEnable := true;
        PhoneNoEnable := true;
        CountryRegionCodeEnable := true;
        IBANEnable := true;
        CityEnable := true;
        PostCodeEnable := true;
        Address2Enable := true;
        AddressEnable := true;
        NameEnable := true;
        InvoiceNoLengthEnable := true;
        InvoiceNoStartpositionEnable := true;
        ESRAccountNoEnable := true;
        GiroAccountNoEnable := true;
        ESRTypeEnable := true;
        BankAccountNoEnable := true;
        ClearingNoEnable := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateView;
    end;

    trigger OnOpenPage()
    begin
        UpdateView;
    end;

    var
        [InDataSet]
        ClearingNoEnable: Boolean;
        [InDataSet]
        BankAccountNoEnable: Boolean;
        [InDataSet]
        ESRTypeEnable: Boolean;
        [InDataSet]
        GiroAccountNoEnable: Boolean;
        [InDataSet]
        ESRAccountNoEnable: Boolean;
        [InDataSet]
        InvoiceNoStartpositionEnable: Boolean;
        [InDataSet]
        InvoiceNoLengthEnable: Boolean;
        [InDataSet]
        NameEnable: Boolean;
        [InDataSet]
        AddressEnable: Boolean;
        [InDataSet]
        Address2Enable: Boolean;
        [InDataSet]
        PostCodeEnable: Boolean;
        [InDataSet]
        CityEnable: Boolean;
        [InDataSet]
        IBANEnable: Boolean;
        [InDataSet]
        CountryRegionCodeEnable: Boolean;
        [InDataSet]
        PhoneNoEnable: Boolean;
        [InDataSet]
        ContactEnable: Boolean;
        [InDataSet]
        FaxNoEnable: Boolean;
        [InDataSet]
        EMailEnable: Boolean;
        [InDataSet]
        HomePageEnable: Boolean;
        [InDataSet]
        SWIFTCodeEnable: Boolean;
        [InDataSet]
        TransitNoEnable: Boolean;
        SuggestedSwissPaymentType: Option " ","1","2.1","2.2","3","4","5","6";

    [Scope('OnPrem')]
    procedure UpdateView()
    begin
        ClearingNoEnable := false;
        BankAccountNoEnable := false;
        ESRTypeEnable := false;
        GiroAccountNoEnable := false;
        ESRAccountNoEnable := false;
        InvoiceNoStartpositionEnable := false;
        InvoiceNoLengthEnable := false;
        NameEnable := false;
        AddressEnable := false;
        Address2Enable := false;
        PostCodeEnable := false;
        CityEnable := false;
        IBANEnable := false;
        CountryRegionCodeEnable := false;
        PhoneNoEnable := false;
        ContactEnable := false;
        FaxNoEnable := false;
        EMailEnable := false;
        HomePageEnable := false;
        SWIFTCodeEnable := false;
        TransitNoEnable := false;

        case "Payment Form" of
            "Payment Form"::ESR,
            "Payment Form"::"ESR+":
                begin
                    ESRTypeEnable := true;
                    ESRAccountNoEnable := true;
                    InvoiceNoStartpositionEnable := true;
                    InvoiceNoLengthEnable := true;
                    IBANEnable := true;
                end;
            "Payment Form"::"Post Payment Domestic":
                begin
                    GiroAccountNoEnable := true;
                    BankAccountNoEnable := true;
                    SWIFTCodeEnable := true;
                    NameEnable := false;
                    AddressEnable := false;
                    Address2Enable := false;
                    PostCodeEnable := false;
                    CityEnable := false;

                    IBANCheck;

                    CountryRegionCodeEnable := false;
                    PhoneNoEnable := true;
                    ContactEnable := true;
                    FaxNoEnable := true;
                    EMailEnable := true;
                    HomePageEnable := true;
                end;
            "Payment Form"::"Bank Payment Domestic":
                begin
                    ClearingNoEnable := true;
                    NameEnable := true;
                    AddressEnable := true;
                    Address2Enable := true;
                    PostCodeEnable := true;
                    CityEnable := true;
                    BankAccountNoEnable := true;
                    SWIFTCodeEnable := true;

                    IBANCheck;

                    CountryRegionCodeEnable := true;
                    PhoneNoEnable := true;
                    ContactEnable := true;
                    FaxNoEnable := true;
                    EMailEnable := true;
                    HomePageEnable := true;
                end;
            "Payment Form"::"Cash Outpayment Order Domestic":
                ;
            "Payment Form"::"Bank Payment Abroad", "Payment Form"::"Post Payment Abroad":
                begin
                    NameEnable := true;
                    AddressEnable := true;
                    Address2Enable := true;
                    PostCodeEnable := true;
                    CityEnable := true;
                    BankAccountNoEnable := true;
                    SWIFTCodeEnable := true;

                    IBANCheck;

                    CountryRegionCodeEnable := true;
                    PhoneNoEnable := true;
                    ContactEnable := true;
                    FaxNoEnable := true;
                    EMailEnable := true;
                    HomePageEnable := true;

                    ClearingNoEnable := true;
                end;
            "Payment Form"::"SWIFT Payment Abroad":
                begin
                    SWIFTCodeEnable := true;
                    NameEnable := true;
                    AddressEnable := true;
                    PostCodeEnable := true;
                    CityEnable := true;
                    CountryRegionCodeEnable := true;
                    BankAccountNoEnable := true;

                    IBANCheck;
                end;
            "Payment Form"::"Cash Outpayment Order Abroad":
                ;
        end;
        UpdateSuggestedSwissPaymentType;
    end;

    local procedure IBANCheck()
    begin
        IBANEnable := true;
        if IBAN <> '' then
            BankAccountNoEnable := false;
        if "Bank Account No." <> '' then
            IBANEnable := false;
    end;

    local procedure UpdateSuggestedSwissPaymentType()
    begin
        if not GetPaymentType(SuggestedSwissPaymentType, "Currency Code") then
            SuggestedSwissPaymentType := SuggestedSwissPaymentType::" ";
    end;
}

