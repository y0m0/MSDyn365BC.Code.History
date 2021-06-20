codeunit 141011 "ERM WHT - AU"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [WHT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        ABNTxt: Label '53001003000';
        DiffrentWHTPostingGroupOnLineErr: Label 'You cannot post a transaction using different WHT minimum invoice amounts on lines.';
        ValueMustBeSameMsg: Label 'Value must be same.';
        ValueMustNotExistMsg: Label '%1 must not exist.';

    [Test]
    [Scope('OnPrem')]
    procedure GenJnlLinePaymentWithUpdatedCurrFactor()
    var
        GenJournalLine: array[2] of Record "Gen. Journal Line";
    begin
        // [SCENARIO 287724] Post FCY payment with updated currency factor and applied to FCY invoice
        Initialize;
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);

        // [GIVEN] FCY invoice general journal
        CreateFCYInvoiceGenJnlLine(GenJournalLine[1]);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);
        // [GIVEN] FCY payment general journal with updated currency factor
        CreateAppliedFCYPaymentGenJnlLine(GenJournalLine[2], GenJournalLine[1]);
        // [WHEN] Post general journal line with updated currency factor
        LibraryERM.PostGeneralJnlLine(GenJournalLine[2]);
        // [THEN] Posted WHT amount is calculated based on updated currency factor
        VerifyGLEntryWHTAmount(GenJournalLine[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithoutABNVendor()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        OldGSTProdPostingGroup: Code[20];
    begin
        // [SCENARIO] VAT Product Posting Group on Purchase Line with Purchase and Payable Setup when vendor not having ABN.

        // Setup.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);

        // Exercise.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", ''),
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDecInRange(1000, 10000, 2), '');  // Direct Unit Cost in Random Decimal Range and blank ABN Code, Currency Code.

        // [THEN] Verify Purchase Line - VAT Product Posting Group with Purchases and Payables Setup - GST Product Posting Group.
        PurchasesPayablesSetup.Get;
        PurchaseLine.TestField("VAT Prod. Posting Group", PurchasesPayablesSetup."GST Prod. Posting Group");

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatistics()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTEntry: Record "WHT Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
        WHTAmount: Decimal;
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with G/L Account for a Vendor.

        // [GIVEN] Create and Post Purchase Order.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
            LibraryRandom.RandDecInRange(1000, 10000, 2), VendorNo);  // Random - Direct unit cost.
        WHTPostingSetup.Get(PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        WHTAmount := CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %");
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics Page, WHT Entry with Remaining WHT Prepaid Amount and GST  Purchase Entry with 0 value.
        VerifyPurchaseInvoiceStatisticsPageAndWHTEntry(
          PurchaseInvoiceStatistics, PostedPurchaseInvoice, WHTEntry."Document Type"::Invoice, VendorNo, WHTAmount, 0, 0, WHTAmount);  // Paid WHT Prepaid Amount and Amount - 0.
        VerifyGSTPurchaseEntry(DocumentNo, GSTPurchaseEntry."Document Line Type"::"G/L Account");

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsWithPayment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        VendorNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with G/L Account for a Vendor and make payment.

        // [GIVEN] Create and Post Purchase Order. Create and Post General Journal Line - Applies To Document Number.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
            LibraryRandom.RandDecInRange(1000, 10000, 2), VendorNo);  // Random - Direct unit cost.
        WHTPostingSetup.Get(PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));  // Blank Currency Code.
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics Page, WHT Entry with Paid WHT Prepaid Amount and GST Purchase Entry with 0 value.
        VerifyPurchaseInvoiceStatisticsWHTAndGSTEntries(
          PurchaseInvoiceStatistics, PostedPurchaseInvoice, DocumentNo, CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %"), VendorNo);
        VerifyGSTPurchaseEntry(DocumentNo, GSTPurchaseEntry."Document Line Type"::"G/L Account");

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsWHTMinimumInvAmt()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with (WHT minimum Invoice Amount) G/L Account for a Vendor.

        // [GIVEN] Post purchase order with less than WHT Minimum Invoice Amount.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
            LibraryRandom.RandDecInRange(1, 5, 2), VendorNo);  // Amount should be less than WHT Minimum Invoice Amount.
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics Page and GST Purchase Entry with 0 value.
        VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics, 0, 0);  // Remaining WHT Prepaid Amount and Paid WHT Prepaid Amount - 0.
        VerifyGSTPurchaseEntry(DocumentNo, GSTPurchaseEntry."Document Line Type"::"G/L Account");
        PostedPurchaseInvoice.Close;

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsWHTMinimumInvAmtWithPayment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with (WHT minimum Invoice Amount) G/L Account for a Vendor and make payment.

        // [GIVEN] Post purchase order with less than WHT Minimum Invoice Amount. Create and Post General Journal Line - Applies To Document Number.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
            LibraryRandom.RandDecInRange(1, 5, 2), VendorNo);  // Amount should be less than WHT Minimum Invoice Amount.
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));  // Blank Currency Code.
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics Page and GST Purchase Entry with 0 value.
        VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics, 0, 0);  // Remaining WHT Prepaid Amount and Paid WHT Prepaid Amount - 0.
        VerifyGSTPurchaseEntry(DocumentNo, GSTPurchaseEntry."Document Line Type"::"G/L Account");
        PostedPurchaseInvoice.Close;

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvWithMultipleLinesStatsWithPayment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order(multiple Lines) with G/L Account for a Vendor and make payment.

        // [GIVEN] Post purchase order with multiple Lines. Create and Post General Journal Line - Applies To Document Number.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", ''),
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDecInRange(100, 1000, 2), '');  // Direct Unit Cost in Random Decimal Range and blank ABN Code, Currency Code.
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(5));  // Random Quantity.
        UpdatePaymentDiscountOnPurchaseHeader(PurchaseHeader);
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));  // Blank Currency Code.
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics and WHT And GST Entries.
        VerifyPurchaseInvoiceStatisticsWHTAndGSTEntries(
          PurchaseInvoiceStatistics, PostedPurchaseInvoice, DocumentNo, CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %"),
          PurchaseHeader."Buy-from Vendor No.");
        VerifyGSTPurchaseEntry(DocumentNo, GSTPurchaseEntry."Document Line Type"::Item);
        VerifyPaymentDiscountOnDetailedVendorLedgEntry(DocumentNo);

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsWithCurrAndPayment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order(multiple Lines) with G/L Account with Currency for a Vendor and make payment.

        // [GIVEN] Post Purchase Order with Item and two G/L Account lines with Currency. Create and Post General Journal Line - Applies To Document Number.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", CreateCurrency, '',
          LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);  // Blank ABN and Random - Direct Unit Cost.
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, PurchaseLine."Currency Code", -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics and WHT And GST Entries.
        VerifyPurchaseInvoiceStatisticsWHTAndGSTEntries(
          PurchaseInvoiceStatistics, PostedPurchaseInvoice, DocumentNo, CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %"),
          VendorNo);
        VerifyGSTPurchaseEntry(DocumentNo, GSTPurchaseEntry."Document Line Type"::Item);

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsWithPartialPayment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTEntry: Record "WHT Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
        WHTAmount: Decimal;
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with G/L Account for a Vendor and make Partial payment.

        // [GIVEN] Post purchase order with Item and two G/L Account lines. Create and Post General Journal Line - Applies To Document Number with Partial payment.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', '',
          LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);  // Blank Currency, ABN and Random - Direct Unit Cost.
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo) / 2);  // Blank Currency Code and Partial payment.
        WHTAmount := CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %") / 2;  // WHT Amount half of Invoiced Amount.
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics Page and WHT Entry - Remaining WHT Prepaid Amount and Paid WHT Prepaid Amount.
        VerifyPurchaseInvoiceStatisticsPageAndWHTEntry(
          PurchaseInvoiceStatistics, PostedPurchaseInvoice, WHTEntry."Document Type"::Payment,
          VendorNo, WHTAmount, WHTAmount, WHTAmount, 0);  // Unrealized Amount - 0.
        VerifyGSTPurchaseEntries(DocumentNo);

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsWithPartialPaymentAndDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTEntry: Record "WHT Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
        PaidWHTAmount: Decimal;
        TotalWHTAmount: Decimal;
        AppliedAmount: Decimal;
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with G/L Account for a Vendor with discount and make Partial payment.

        // [GIVEN] Post purchase order with Item and two G/L Account lines with discount. Create and Post General Journal Line - Applies To Document Number with Partial payment.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', '',
          LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);  // Blank Currency, ABN and Random - Direct Unit Cost.
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        UpdatePaymentDiscountOnPurchaseHeader(PurchaseHeader);
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        AppliedAmount := -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo) / 2;  // Half Amount used as Applied Amount for Partial payment.
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', AppliedAmount);  // Blank Currency Code.
        TotalWHTAmount := CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %");
        PaidWHTAmount := AppliedAmount * WHTPostingSetup."WHT %" / 100;
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics Page and WHT Entry - Remaining WHT Prepaid Amount and Paid WHT Prepaid Amount.
        VerifyPurchaseInvoiceStatisticsPageAndWHTEntry(
          PurchaseInvoiceStatistics, PostedPurchaseInvoice, WHTEntry."Document Type"::Payment, VendorNo,
          TotalWHTAmount - PaidWHTAmount, PaidWHTAmount, PaidWHTAmount, 0);  // Unrealized Amount - 0.
        VerifyGSTPurchaseEntries(DocumentNo);

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsWithPaymentAndDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTEntry: Record "WHT Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with G/L Account for a Vendor with discount and make Partial and full payment.

        // [GIVEN] Post purchase order with Item and two G/L Account lines and discount. Create and Post General Journal Line - Applies To Document Number with Partial payment.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', '',
          LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);  // Blank Currency, ABN and Random - Direct Unit Cost.
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        UpdatePaymentDiscountOnPurchaseHeader(PurchaseHeader);
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo) / 2);  // Blank Currency Code and Partial payment.
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));  // Blank Currency Code.
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics Page and WHT Entry - Paid WHT Prepaid Amount.
        VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics, 0, CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %"));  // Remaining WHT Prepaid Amount - 0.
        FilterOnWHTEntry(WHTEntry, WHTEntry."Document Type"::Payment, PurchaseLine."Buy-from Vendor No.");
        Assert.AreEqual(2, WHTEntry.Count, ValueMustBeSameMsg);  // WHT Entry count should be 2 for twice partial payment.
        PostedPurchaseInvoice.Close;

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoStatsWithPaymentAndAdjustment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        WHTEntry: Record "WHT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PurchCreditMemoStatistics: TestPage "Purch. Credit Memo Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
        WHTAmount: Decimal;
    begin
        // [SCENARIO] WHT Amount on Purch. Credit Memo Statistics Page, Post purchase order(multiple Lines) with G/L Account for a Vendor and make payment. Post Purchase Credit Memo with Adjustment.

        // [GIVEN] Post purchase order with Item and two G/L Account lines. Create and Post General Journal Line - Applies To Document Number. Create and Post Purchase Credit Memo with Adjustment.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', '',
          LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);    // Blank Currency, ABN and Random - Direct Unit Cost.
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, PurchaseLine."Currency Code", -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));
        DocumentNo := CreateAndPostCrMemoWithAdjAppliesTo(PurchaseLine, DocumentNo);
        WHTAmount := CalculatePurchCrMemoHdrWHTAmount(DocumentNo, WHTPostingSetup."WHT %");
        PurchCreditMemoStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseCreditMemoPage(PostedPurchaseCreditMemo, DocumentNo);

        // [THEN] Purchase Credit Memo Statistics and WHT Entry - Remaining WHT Prepaid Amount.
        VerifyPurchCreditMemoStatisticsPageAndWHTEntry(
          PurchCreditMemoStatistics, PostedPurchaseCreditMemo, WHTEntry."Document Type"::"Credit Memo",
          PurchaseLine."Buy-from Vendor No.", -WHTAmount, 0);  // Paid WHT Prepaid Amount - 0.
        VerifyGSTPurchaseEntry(DocumentNo, GSTPurchaseEntry."Document Line Type"::"G/L Account");

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoStatsWithPaymentAndRefund()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        WHTEntry: Record "WHT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PurchCreditMemoStatistics: TestPage "Purch. Credit Memo Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
        WHTAmount: Decimal;
    begin
        // [SCENARIO] WHT Amount on Purch. Credit Memo Statistics Page, Post purchase order(multiple Lines) with G/L Account for a Vendor and make payment. Post Purchase Credit Memo with Adjustment, Create and Post Refund.

        // [GIVEN] Post purchase order with Item and two G/L Account lines. Create and Post General Journal Line - Applies To Document Number. Create and Post Purchase Credit Memo with Adjustment.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', '',
          LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);  // Blank Currency, ABN and Random - Direct Unit Cost.
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, PurchaseLine."Currency Code", -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));
        DocumentNo := CreateAndPostCrMemoWithAdjAppliesTo(PurchaseLine, DocumentNo);
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Refund, GenJournalLine."Applies-to Doc. Type"::"Credit Memo",
          DocumentNo, PurchaseLine."Currency Code", -FindVendorLedgerEntryAmount(
            VendorLedgerEntry."Document Type"::"Credit Memo", DocumentNo));
        WHTAmount := CalculatePurchCrMemoHdrWHTAmount(DocumentNo, WHTPostingSetup."WHT %");
        PurchCreditMemoStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseCreditMemoPage(PostedPurchaseCreditMemo, DocumentNo);

        // [THEN] Purchase Credit Memo Statistics and WHT Entry - Paid WHT Prepaid Amount.
        VerifyPurchCreditMemoStatisticsPageAndWHTEntry(
          PurchCreditMemoStatistics, PostedPurchaseCreditMemo, WHTEntry."Document Type"::Refund,
          PurchaseLine."Buy-from Vendor No.", 0, -WHTAmount);  // Remaining WHT Prepaid Amount - 0.
        VerifyGSTPurchaseEntry(DocumentNo, GSTPurchaseEntry."Document Line Type"::"G/L Account");

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchCrMemoStatsPostedCrMemoWithCopyDoc()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTEntry: Record "WHT Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PurchCreditMemoStatistics: TestPage "Purch. Credit Memo Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
        WHTAmount: Decimal;
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with G/L Account for a Vendor. Create and Post Credit Memo with copy Posted Invoice delete G/L line.

        // [GIVEN] Post purchase order with Item and two G/L Account lines. Create and Post Credit Memo with Copy Posted Invoice G/L line, Create and Post General Journal Line - Applies To Document Number with payment.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', '',
          LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);  // Blank Currency, ABN and Random - Direct Unit Cost.
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        DocumentNo := CreateAndPostPurchCrMemoWithCopyDoc(PurchaseLine."Buy-from Vendor No.", DocumentNo);
        WHTAmount := CalculatePurchCrMemoHdrWHTAmount(DocumentNo, WHTPostingSetup."WHT %");
        PurchCreditMemoStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseCreditMemoPage(PostedPurchaseCreditMemo, DocumentNo);

        // [THEN] Purchase Credit Memo Statistics and WHT - Remaining Amount.
        VerifyPurchCreditMemoStatisticsPageAndWHTEntry(
          PurchCreditMemoStatistics, PostedPurchaseCreditMemo, WHTEntry."Document Type"::"Credit Memo",
          PurchaseLine."Buy-from Vendor No.", -WHTAmount, 0);  // Paid WHT Prepaid Amount - 0.
        VerifyGSTPurchaseEntries(DocumentNo);

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsPostedCrMemoWithCopyDocPayment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTEntry: Record "WHT Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
        WHTAmount: Decimal;
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with G/L Account for a Vendor. Create and Post Credit Memo with copy Posted Invoice delete G/L line make payment.

        // [GIVEN] Post purchase order with Item and G/L Account lines. Create and Post Credit Memo with Copy Posted Invoice G/L line, Create and Post General Journal Line - Applies To Document Number with payment.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', '',
          LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);  // Blank Currency, ABN and Random - Direct Unit Cost.
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        CreateAndPostPurchCrMemoWithCopyDoc(PurchaseLine."Buy-from Vendor No.", DocumentNo);
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));  // Blank Currency Code.
        WHTAmount := CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %");
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics Page and WHT Entry - Amount.
        VerifyPurchaseInvoiceStatisticsPageAndWHTEntry(
          PurchaseInvoiceStatistics, PostedPurchaseInvoice, WHTEntry."Document Type"::Invoice, VendorNo,
          0, WHTAmount, 0, WHTAmount);  // Remaining WHT Prepaid Amount and Amount - 0.
        VerifyGSTPurchaseEntries(DocumentNo);

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsWithABNVendorPayment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTEntry: Record "WHT Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        VendorNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        OldABN: Text[11];
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with G/L Account for a Vendor with ABN and make payment.

        // [GIVEN] Post purchase order with Item and two G/L Account lines having ABN Vendor. Create and Post General Journal Line - Applies To Document Number with Partial payment.
        GeneralLedgerSetup.Get;
        OldABN := UpdateCompanyInformationABN(ABNTxt);
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', ABNTxt,
          LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);  // Blank Currency and Random - Direct Unit Cost.
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));  // Blank Currency.
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics Page and WHT Entry not exists as Vendor have ABN.
        VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics, 0, 0);  // Remaining WHT Prepaid Amount and Paid WHT Prepaid Amount - 0.
        FilterOnWHTEntry(WHTEntry, WHTEntry."Document Type"::Payment, PurchaseLine."Buy-from Vendor No.");
        Assert.IsFalse(WHTEntry.FindFirst, StrSubstNo(ValueMustNotExistMsg, WHTEntry.TableCaption));
        PostedPurchaseInvoice.Close;

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
        UpdateVendorABN(PurchaseLine."Buy-from Vendor No.", '');
        UpdateCompanyInformationABN(OldABN);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsPaymentWithABNVendor()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTEntry: Record "WHT Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        VendorNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        OldABN: Text[11];
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with G/L Account for a Vendor and make payment after Update Vendor - ABN.

        // [GIVEN] Post purchase order with Item and two G/L Account lines. Create and Post General Journal Line - Applies To Document Number payment with modified Vendor ABN.
        GeneralLedgerSetup.Get;
        OldABN := UpdateCompanyInformationABN(ABNTxt);
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', '',
          LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);  // Blank Currency, ABN and Random - Direct Unit Cost.
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        UpdateVendorABN(PurchaseLine."Buy-from Vendor No.", ABNTxt);
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));  // Blank Currency Code.
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics Page and WHT Entry not created ABN Vendor is used.
        VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics, CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %"), 0);  // Paid WHT Prepaid Amount - 0.
        FilterOnWHTEntry(WHTEntry, WHTEntry."Document Type"::Payment, PurchaseLine."Buy-from Vendor No.");
        Assert.IsFalse(WHTEntry.FindFirst, StrSubstNo(ValueMustNotExistMsg, WHTEntry.TableCaption));
        PostedPurchaseInvoice.Close;

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
        UpdateVendorABN(PurchaseLine."Buy-from Vendor No.", '');
        UpdateCompanyInformationABN(OldABN);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsWithWHTMinInvAmtPayment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTEntry: Record "WHT Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with G/L Account for a Vendor and make Partial(WHT Minimum Invoice Amount) and full payment.

        // [GIVEN] Post purchase order with Item and two G/L Account lines and discount. Create and Post General Journal Line - Applies To Document Number with Partial (WHT Minimum Invoice Amount) payment.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::Item, CreateItem(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', '',
          LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);  // Blank Currency, ABN and Random - Direct Unit Cost.
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', WHTPostingSetup."WHT Minimum Invoice Amount");
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));  // Blank Currency Code.
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics Page and two WHT Entry are created.
        VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics, 0, CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %"));  // Remaining WHT Prepaid Amount - 0.
        FilterOnWHTEntry(WHTEntry, WHTEntry."Document Type"::Payment, PurchaseLine."Buy-from Vendor No.");
        Assert.AreEqual(2, WHTEntry.Count, ValueMustBeSameMsg);
        PostedPurchaseInvoice.Close;

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsAmtMoreThanWHTMinInvAmt()
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Posted Purchase Order and WHT Entry and Post Purchase order(multiple Lines) with more than the (WHT minimum Invoice Amount) G/L Account for a Vendor and make payment.

        // Setup.
        PostedPurchInvStatsAmtWHTMinInvAmt(LibraryRandom.RandDecInRange(100, 500, 2));  // Random - Direct Unit Cost and excess of the WHT minimum Invoice Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsAmtLessThanWHTMinInvAmt()
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Posted Purchase Order and WHT Entry and Post Purchase order(multiple Lines) with Less than of the (WHT minimum Invoice Amount) G/L Account for a Vendor and make payment.

        // Setup.
        PostedPurchInvStatsAmtWHTMinInvAmt(LibraryRandom.RandDecInRange(1, 5, 2));  // Random - Direct Unit Cost and Lesser of the WHT minimum Invoice Amount.
    end;

    local procedure PostedPurchInvStatsAmtWHTMinInvAmt(Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        WHTAmount: Decimal;
        DocumentNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
        VendorNo: Code[20];
    begin
        // Post Purchase order with multiple Lines. Create and Post General Journal Line - Applies To Document Number.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::"G/L Account", CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', '', Amount, VendorNo);  // Blank Currency, ABN and Random - Direct Unit Cost.
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.CalcFields(Amount);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        WHTAmount := CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %");
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));  // Blank Currency Code.
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // Verify Purchase Invoice Statistics, and Posted Journal General Line - Amount, Base on WHT Entries.
        VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics, 0, WHTAmount);  // Remaining WHT Prepaid Amount and Paid WHT Prepaid Amount - 0.
        VerifyBaseAndAmountOnWHTEntry(PurchaseLine."Buy-from Vendor No.", PurchaseHeader.Amount, WHTAmount);
        VerifyGSTPurchaseEntry(DocumentNo, GSTPurchaseEntry."Document Line Type"::"G/L Account");
        PostedPurchaseInvoice.Close;

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithMultipleLineWHTEntries()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        DocumentNo: Code[20];
        VendorNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
    begin
        // [SCENARIO] WHT Amount on Posted Purchase Order, Post Purchase order (multiple Lines) with G/L Account for a Vendor and make payment.

        // [GIVEN] Post Purchase order with multiple Lines. Create and Post General Journal Line - Applies To Document Number.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseOrderWithMultipleLines(
          PurchaseLine, PurchaseLine.Type::"G/L Account", CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"),
          VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group", '', '',
          LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);  // Blank Currency, ABN and Random - Direct Unit Cost.
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo := PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");

        // Exercise.
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));  // Blank Currency Code.

        // [THEN] Verify Posted Purchase Order - Remaining Unrealized Amount, Unrealized Amount (LCY).
        VerifyPurchaseInvoiceWHTEntry(
          PurchaseLine."Document Type"::Invoice, PurchaseLine."Buy-from Vendor No.", 0,
          CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %"));  // Amount - 0.

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchInvStatsMoreThanWHTMinInvAmtWithPayment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics";
        WHTAmount: Decimal;
        DocumentNo: Code[20];
        VendorNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
    begin
        // [SCENARIO] WHT Amount - Purchase Invoice Statistics Page, Base and Amount - WHT Entry and Post Purchase order with more Than the (WHT minimum Invoice Amount) G/L Account for a Vendor and make payment.

        // [GIVEN] Create and Post Purchase Order with Excess WHT Minimum Invoice Amount, Post General Journal Line - Applies To Document Number.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
            LibraryRandom.RandDecInRange(100, 500, 2), VendorNo);  // Random - Direct unit cost.
        WHTPostingSetup.Get(PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        WHTAmount := CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %");
        CreateAndPostGenJournalLineWithAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", GenJournalLine."Document Type"::Payment, GenJournalLine."Applies-to Doc. Type"::Invoice,
          DocumentNo, '', -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo));  // Blank Currency Code.
        PurchaseInvoiceStatistics.Trap;

        // Exercise.
        OpenStatisticsOnPostedPurchaseInvoicePage(PostedPurchaseInvoice, DocumentNo);

        // [THEN] Verify Purchase Invoice Statistics, Posted Purchase Order - Remaining Unrealized Amount, Unrealized Amount (LCY) and Posted Journal General Line - Amount, Base on WHT Entries.
        VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics, 0, WHTAmount);  // Remaining WHT Prepaid Amount - 0.
        VerifyPurchaseInvoiceWHTEntry(PurchaseLine."Document Type"::Invoice, PurchaseLine."Buy-from Vendor No.", 0, WHTAmount);  // Amount - 0.
        VerifyBaseAndAmountOnWHTEntry(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", WHTAmount);
        PostedPurchaseInvoice.Close;

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WHTWithDiffWHTPostingGroupOnPurchaseLineError()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldGSTProdPostingGroup: Code[20];
    begin
        // [SCENARIO] Error While Posting Purchase Order with Multiple Line and Different WHT Business Posting Group, WHT Business Posting Group.

        // [GIVEN] Post Purchase order with Multiple Line and Different WHT Business Posting Group, WHT Business Posting Group.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, CreateVendor(VATPostingSetup."VAT Bus. Posting Group", ''),
          CreateGLAccount(VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDecInRange(100, 500, 2), '');  // Blank - ABN Code, Currency and Random as Direct unit cost.
        CreatePurchaseLineWithWHTPostingGroups(PurchaseLine, VATPostingSetup."VAT Prod. Posting Group");

        // [WHEN] Post Purchase Document.
        asserterror PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");

        // [THEN] Verify Error While Posting Purchase Order with Multiple Line and Different WHT Business Posting Group, WHT Business Posting Group.
        Assert.ExpectedError(DiffrentWHTPostingGroupOnLineErr);

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiplePostedPurchInvAppliesToDocNoOnGenJnlLine()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseLine3: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        WHTPostingSetup: Record "WHT Posting Setup";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        VendorNo: Code[20];
        OldGSTProdPostingGroup: Code[20];
    begin
        // [SCENARIO] WHT Amount on Purchase Invoice Statistics Page, Post purchase order with (WHT minimum Invoice Amount) G/L Account for a Vendor and make payment.

        // [GIVEN] Post Purchase order, Create and Post General Journal Line - Applies To Document Number.
        GeneralLedgerSetup.Get;
        OldGSTProdPostingGroup := UpdateGLSetupAndPurchasesPayablesSetup(VATPostingSetup);
        DocumentNo :=
          CreateAndPostPurchaseOrder(
            PurchaseLine, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
            LibraryRandom.RandDecInRange(100, 500, 2), VendorNo);  // Direct Unit Cost in Random Decimal Range.
        WHTPostingSetup.Get(PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        DocumentNo2 :=
          CreateAndPostPurchaseOrder(
            PurchaseLine2, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
            LibraryRandom.RandDecInRange(100, 1000, 2), VendorNo);  // Direct Unit Cost in Random Decimal Range.
        DocumentNo3 :=
          CreateAndPostPurchaseOrder(
            PurchaseLine3, VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group",
            LibraryRandom.RandDecInRange(100, 200, 2), VendorNo);  // Direct Unit Cost in Random Decimal Range.

        // [WHEN] Post General Journal Line and Applies multiple Applies-to Doc. No.
        CreateAndPostGenJournalLineWithMultipleAppliesToDocNo(
          PurchaseLine."Buy-from Vendor No.", PurchaseLine2."Buy-from Vendor No.",
          PurchaseLine3."Buy-from Vendor No.", DocumentNo, DocumentNo2, DocumentNo3);

        // [THEN] Verify Posted Journal General Line - Amount, Base on WHT Entries.
        VerifyBaseAndAmountOnWHTEntry(
          PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount", CalculateWHTAmount(DocumentNo, WHTPostingSetup."WHT %"));
        VerifyBaseAndAmountOnWHTEntry(
          PurchaseLine2."Buy-from Vendor No.", PurchaseLine2."Line Amount", CalculateWHTAmount(DocumentNo2, WHTPostingSetup."WHT %"));
        VerifyBaseAndAmountOnWHTEntry(
          PurchaseLine3."Buy-from Vendor No.", PurchaseLine3."Line Amount", CalculateWHTAmount(DocumentNo3, WHTPostingSetup."WHT %"));

        // Tear Down.
        UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup, OldGSTProdPostingGroup);
    end;

    local procedure Initialize()
    var
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
    begin
        LibrarySetupStorage.Restore;

        if IsInitialized then
            exit;

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure CreateAndPostPurchCrMemoWithCopyDoc(VendorNo: Code[20]; PostedDocumentNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentType: Option Quote,"Blanket Order","Order",Invoice,"Return Order","Credit Memo","Posted Receipt","Posted Invoice";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo, '');  // Blank Currency.
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, DocumentType::"Posted Invoice", PostedDocumentNo, false, true);  // Include Header - False,Recalculate Lines - True.
        DeletePurchaseLineGLAccountLine(PurchaseHeader."No.");
        exit(PostPurchaseDocument(PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."No."));
    end;

    local procedure CreateAndPostCrMemoWithAdjAppliesTo(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]): Code[20]
    var
        PurchaseLine2: Record "Purchase Line";
    begin
        CreatePurchaseDocument(
          PurchaseLine2, PurchaseLine."Document Type"::"Credit Memo", PurchaseLine."Buy-from Vendor No.", PurchaseLine."No.",
          PurchaseLine."Direct Unit Cost", '');  // Blank - Currency.
        PurchaseLine2.Validate(Quantity, PurchaseLine.Quantity);
        PurchaseLine2.Modify(true);
        UpdatePurchaseCreditMemoAdjustmentAppliesTo(PurchaseLine2."Document No.", DocumentNo);
        exit(PostPurchaseDocument(PurchaseLine2."Document Type"::"Credit Memo", PurchaseLine2."Document No."));
    end;

    local procedure CreateAndPostGenJournalLineWithAppliesToDocNo(AccountNo: Code[20]; DocumentType: Option; AppliesToDocType: Option; DocumentNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, AccountNo, DocumentNo, CurrencyCode, AppliesToDocType, Amount, DocumentType);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGenJournalLineWithMultipleAppliesToDocNo(AccountNo: Code[20]; AccountNo2: Code[20]; AccountNo3: Code[20]; DocumentNo: Code[20]; DocumentNo2: Code[20]; DocumentNo3: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, AccountNo, DocumentNo, '', GenJournalLine."Applies-to Doc. Type"::Invoice,
          -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo), GenJournalLine."Document Type"::Payment);  // Blank Currency.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, AccountNo2, DocumentNo2, '', GenJournalLine."Applies-to Doc. Type"::Invoice,
          -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo2), GenJournalLine."Document Type"::Payment);  // Blank Currency.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, AccountNo3, DocumentNo3, '', GenJournalLine."Applies-to Doc. Type"::Invoice,
          -FindVendorLedgerEntryAmount(VendorLedgerEntry."Document Type"::Invoice, DocumentNo3), GenJournalLine."Document Type"::Payment);  // Blank Currency.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; DirectUnitCost: Decimal; var VendorNo: Code[20]): Code[20]
    var
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        VendorNo := CreateVendor(VATBusPostingGroup, '');
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, VendorNo,
          CreateGLAccount(VATProdPostingGroup), DirectUnitCost, '');  // Blank - ABN Code, Currency.
        FindWHTPostingSetup(WHTPostingSetup, PurchaseLine."WHT Business Posting Group", PurchaseLine."WHT Product Posting Group");
        exit(PostPurchaseDocument(PurchaseLine."Document Type"::Order, PurchaseLine."Document No."));
    end;

    local procedure CreatePurchaseLineWithWHTPostingGroups(PurchaseLine: Record "Purchase Line"; VATProdPostingGroup: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        WHTBusinessPostingGroup: Record "WHT Business Posting Group";
        WHTProductPostingGroup: Record "WHT Product Posting Group";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        LibraryAPACLocalization.CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);
        LibraryAPACLocalization.CreateWHTProductPostingGroup(WHTProductPostingGroup);
        CreateWHTPostingSetup(
          WHTPostingSetup, WHTBusinessPostingGroup.Code, WHTProductPostingGroup.Code);
        WHTPostingSetup.Validate("WHT Minimum Invoice Amount", LibraryRandom.RandDecInRange(30, 40, 2));
        WHTPostingSetup.Modify(true);
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          CreateGLAccount(VATProdPostingGroup), LibraryRandom.RandDecInDecimalRange(100, 200, 2));  // Random as Amount.
        PurchaseLine.Validate("WHT Business Posting Group", WHTPostingSetup."WHT Business Posting Group");
        PurchaseLine.Validate("WHT Product Posting Group", WHTPostingSetup."WHT Product Posting Group");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        Currency.Validate("Realized Gains Acc.", GLAccount."No.");
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; AppliesToDocNo: Code[20]; CurrencyCode: Code[10]; AppliesToDocType: Option; Amount: Decimal; DocumentType: Option)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          DocumentType, GenJournalLine."Account Type"::Vendor, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CalculatePurchCrMemoHdrWHTAmount(DocumentNo: Code[20]; WHTPct: Decimal): Decimal
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoHdr.CalcFields(Amount);
        exit(PurchCrMemoHdr.Amount * WHTPct / 100);
    end;

    local procedure CalculateWHTAmount(DocumentNo: Code[20]; WHTPct: Decimal): Decimal
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields(Amount);
        exit(PurchInvHeader.Amount * WHTPct / 100);
    end;

    local procedure CreateGLAccount(VATProdPostingGroup: Code[20]): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGenProductPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProductPostingGroup.Code);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]; ABN: Text[11]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate(ABN, ABN);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; VendorNo: Code[20]; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Option; VendorNo: Code[20]; No: Code[20]; DirectUnitCost: Decimal; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VendorNo, CurrencyCode);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", No, DirectUnitCost);
    end;

    local procedure CreatePurchaseOrderWithMultipleLines(var PurchaseLine: Record "Purchase Line"; Type: Option; No: Code[20]; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; CurrencyCode: Code[10]; ABN: Text[11]; DirectUnitCost: Decimal; var VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        VendorNo := CreateVendor(VATBusPostingGroup, ABN);
        CreatePurchaseDocument(
          PurchaseLine, PurchaseLine."Document Type"::Order, VendorNo, CreateGLAccount(VATProdPostingGroup),
          LibraryRandom.RandDecInRange(100, 1000, 2), CurrencyCode);  // Direct Unit Cost in Random Decimal Range.
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, DirectUnitCost);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", CreateGLAccount(VATProdPostingGroup),
          LibraryRandom.RandDecInRange(100, 1000, 2));  // Direct Unit Cost in Random Decimal Range.
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Option; No: Code[20]; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandInt(5));  // Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVATPostingSetupWithZeroVATPct(VATBusPostingGroup: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Modify(true);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup"; WHTBusinessPostingGroup: Code[20]; WHTProductPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryAPACLocalization.CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup, WHTProductPostingGroup);
        LibraryERM.CreateGLAccount(GLAccount);
        WHTPostingSetup.Validate("WHT %", LibraryRandom.RandDec(10, 2));
        WHTPostingSetup.Validate("WHT Minimum Invoice Amount", LibraryRandom.RandDecInRange(50, 100, 2));
        WHTPostingSetup.Validate("Realized WHT Type", WHTPostingSetup."Realized WHT Type"::Payment);
        WHTPostingSetup.Validate("Prepaid WHT Account Code", GLAccount."No.");
        WHTPostingSetup.Validate("Payable WHT Account Code", WHTPostingSetup."Prepaid WHT Account Code");
        WHTPostingSetup.Validate("Purch. WHT Adj. Account No.", WHTPostingSetup."Prepaid WHT Account Code");
        WHTPostingSetup.Validate("Sales WHT Adj. Account No.", WHTPostingSetup."Prepaid WHT Account Code");
        WHTPostingSetup.Modify(true);
    end;

    local procedure CreateFCYInvoiceGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        LibraryAPACLocalization.CreateWHTPostingSetupWithPayableGLAccounts(WHTPostingSetup);
        WHTPostingSetup.Validate("WHT %", 2);
        WHTPostingSetup.Modify(true);
        with GenJournalLine do begin
            LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
            LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, "Document Type"::Invoice,
              "Account Type"::Vendor, CreateLocalVendor, -10);
            Validate("Posting Date", WorkDate);
            Validate("Currency Code", CreateCurrencyWithTwoExchangeRates);
            Validate("Bal. Account Type", "Bal. Account Type"::"G/L Account");
            Validate("Bal. Account No.", LibraryERM.CreateGLAccountNoWithDirectPosting);
            Validate("WHT Business Posting Group", WHTPostingSetup."WHT Business Posting Group");
            Validate("WHT Product Posting Group", WHTPostingSetup."WHT Product Posting Group");
            Modify(true);
        end;
    end;

    local procedure CreateAppliedFCYPaymentGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var InvoiceGenJournalLine: Record "Gen. Journal Line")
    begin
        with GenJournalLine do begin
            LibraryERM.CreateGeneralJnlLine(
              GenJournalLine, InvoiceGenJournalLine."Journal Template Name", InvoiceGenJournalLine."Journal Batch Name",
              "Document Type"::Payment, "Account Type"::Vendor, InvoiceGenJournalLine."Account No.", -InvoiceGenJournalLine.Amount);
            Validate("Posting Date", WorkDate + 10);
            Validate("Currency Code", InvoiceGenJournalLine."Currency Code");
            Validate("Currency Factor", 1 / 120);
            Validate("Applies-to Doc. Type", "Applies-to Doc. Type"::Invoice);
            Validate("Applies-to Doc. No.", InvoiceGenJournalLine."Document No.");
            Validate("Bal. Account Type", "Bal. Account Type"::"G/L Account");
            Validate("Bal. Account No.", InvoiceGenJournalLine."Bal. Account No.");
            Validate("WHT Business Posting Group", InvoiceGenJournalLine."WHT Business Posting Group");
            Validate("WHT Product Posting Group", InvoiceGenJournalLine."WHT Product Posting Group");
            Modify(true);
        end;
    end;

    local procedure CreateCurrencyWithTwoExchangeRates(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate, 80, 80);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate + 10, 100, 100);
        Currency.Validate("Realized Gains Acc.", LibraryERM.CreateGLAccountNo);
        Currency.Validate("Realized Losses Acc.", LibraryERM.CreateGLAccountNo);
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateLocalVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.ABN := '';
        Vendor."Foreign Vend" := false;
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure DeletePurchaseLineGLAccountLine(DocumentNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.FindLast;
        PurchaseLine.Delete(true);  // Deleting last Purchase Line of Type - G/L Account.
    end;

    local procedure FilterOnWHTEntry(var WHTEntry: Record "WHT Entry"; DocumentType: Option; BillToPayToNo: Code[20])
    begin
        WHTEntry.SetRange("Document Type", DocumentType);
        WHTEntry.SetRange("Bill-to/Pay-to No.", BillToPayToNo);
    end;

    local procedure FindWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup"; WHTBusinessPostingGroup: Code[20]; WHTProductPostingGroup: Code[20])
    begin
        // Enable test cases in NZ, create WHT Posting Setup.
        if not WHTPostingSetup.Get(WHTBusinessPostingGroup, WHTProductPostingGroup) then
            CreateWHTPostingSetup(
              WHTPostingSetup, WHTBusinessPostingGroup, WHTProductPostingGroup);  // VAT Product Posting Group - blank.
    end;

    local procedure FindVendorLedgerEntryAmount(DocumentType: Option; DocumentNo: Code[20]): Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, DocumentType, DocumentNo);
        VendorLedgerEntry.CalcFields(Amount);
        exit(VendorLedgerEntry.Amount - VendorLedgerEntry."Remaining Pmt. Disc. Possible")
    end;

    local procedure OpenStatisticsOnPostedPurchaseInvoicePage(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice"; No: Code[20])
    begin
        PostedPurchaseInvoice.OpenEdit;
        PostedPurchaseInvoice.FILTER.SetFilter("No.", No);
        PostedPurchaseInvoice.Statistics.Invoke;  // Open Statistics Page.
    end;

    local procedure OpenStatisticsOnPostedPurchaseCreditMemoPage(var PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo"; No: Code[20])
    begin
        PostedPurchaseCreditMemo.OpenEdit;
        PostedPurchaseCreditMemo.FILTER.SetFilter("No.", No);
        PostedPurchaseCreditMemo.Statistics.Invoke;  // Open Statistics Page.
    end;

    local procedure PostPurchaseDocument(DocumentType: Option; DocumentNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(DocumentType, DocumentNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure UpdateCompanyInformationABN(ABN: Text[11]) OldABN: Text[11]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get;
        OldABN := CompanyInformation.ABN;
        CompanyInformation.Validate(ABN, ABN);
        CompanyInformation.Modify(true);
    end;

    local procedure UpdateLocalFunctionalitiesOnGeneralLedgerSetup(EnableGST: Boolean; EnableWHT: Boolean; GSTReport: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get;
        GeneralLedgerSetup.Validate("Enable GST (Australia)", EnableGST);
        GeneralLedgerSetup.Validate("Enable WHT", EnableWHT);
        GeneralLedgerSetup.Validate("GST Report", GSTReport);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateGSTProdPostingGroupOnPurchasesSetup(GSTProdPostingGroup: Code[20]) OldGSTProdPostingGroup: Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        OldGSTProdPostingGroup := PurchasesPayablesSetup."GST Prod. Posting Group";
        PurchasesPayablesSetup.Validate("GST Prod. Posting Group", GSTProdPostingGroup);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetupAndPurchasesSetup(GeneralLedgerSetup: Record "General Ledger Setup"; OldGSTProdPostingGroup: Code[20])
    begin
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."Enable WHT", GeneralLedgerSetup."GST Report");
        UpdateGSTProdPostingGroupOnPurchasesSetup(OldGSTProdPostingGroup);
    end;

    local procedure UpdateGLSetupAndPurchasesPayablesSetup(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    begin
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // Enable GST (Australia),Enable WHT and GST Report as True.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(UpdateGSTProdPostingGroupOnPurchasesSetup(CreateVATPostingSetupWithZeroVATPct(VATPostingSetup."VAT Bus. Posting Group")));
    end;

    local procedure UpdatePaymentDiscountOnPurchaseHeader(PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandInt(5));
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdatePurchaseCreditMemoAdjustmentAppliesTo(No: Code[20]; AdjustmentAppliesTo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Credit Memo", No);
        PurchaseHeader.Validate("Adjustment Applies-to", AdjustmentAppliesTo);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateVendorABN(No: Code[20]; ABN: Text[11])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(No);
        Vendor.Validate(ABN, ABN);
        Vendor.Modify(true);
    end;

    local procedure VerifyBaseAndAmountOnWHTEntry(BillToPayToNo: Code[20]; Base: Decimal; Amount: Decimal)
    var
        WHTEntry: Record "WHT Entry";
    begin
        FilterOnWHTEntry(WHTEntry, WHTEntry."Document Type"::Payment, BillToPayToNo);
        WHTEntry.FindFirst;
        Assert.AreNearlyEqual(Amount, WHTEntry.Amount, LibraryERM.GetAmountRoundingPrecision, ValueMustBeSameMsg);
        Assert.AreNearlyEqual(Base, WHTEntry.Base, LibraryERM.GetAmountRoundingPrecision, ValueMustBeSameMsg);
    end;

    local procedure VerifyWHTEntry(DocumentType: Option; BillToPayToNo: Code[20]; Amount: Decimal; UnrealizedAmount: Decimal)
    var
        WHTEntry: Record "WHT Entry";
    begin
        FilterOnWHTEntry(WHTEntry, DocumentType, BillToPayToNo);
        WHTEntry.FindFirst;
        Assert.AreNearlyEqual(Amount, WHTEntry.Amount, LibraryERM.GetAmountRoundingPrecision, ValueMustBeSameMsg);
        Assert.AreNearlyEqual(UnrealizedAmount, WHTEntry."Unrealized Amount", LibraryERM.GetAmountRoundingPrecision, ValueMustBeSameMsg);
    end;

    local procedure VerifyPurchCreditMemoStatisticsPageAndWHTEntry(PurchCreditMemoStatistics: TestPage "Purch. Credit Memo Statistics"; PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo"; DocumentType: Option; BuyFromVendorNo: Code[20]; RemWHTPrepaidAmount: Decimal; PaidWHTPrepaidAmount: Decimal)
    begin
        VerifyPurchCreditMemoStatisticsPage(PurchCreditMemoStatistics, RemWHTPrepaidAmount, PaidWHTPrepaidAmount);
        VerifyWHTEntry(DocumentType, BuyFromVendorNo, PaidWHTPrepaidAmount, RemWHTPrepaidAmount);
        PostedPurchaseCreditMemo.Close;
    end;

    local procedure VerifyPurchaseInvoiceStatisticsPageAndWHTEntry(PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics"; PostedPurchaseInvoice: TestPage "Posted Purchase Invoice"; DocumentType: Option; BuyFromVendorNo: Code[20]; RemWHTPrepaidAmount: Decimal; PaidWHTPrepaidAmount: Decimal; Amount: Decimal; UnrealizedAmount: Decimal)
    begin
        VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics, RemWHTPrepaidAmount, PaidWHTPrepaidAmount);
        VerifyWHTEntry(DocumentType, BuyFromVendorNo, Amount, UnrealizedAmount);
        PostedPurchaseInvoice.Close;
    end;

    local procedure VerifyPurchaseInvoiceStatisticsPage(PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics"; RemWHTPrepaidAmount: Decimal; PaidWHTPrepaidAmount: Decimal)
    begin
        Assert.AreNearlyEqual(
          RemWHTPrepaidAmount, PurchaseInvoiceStatistics."Rem. WHT Prepaid Amount (LCY)".AsDEcimal,
          LibraryERM.GetAmountRoundingPrecision, ValueMustBeSameMsg);
        Assert.AreNearlyEqual(
          PaidWHTPrepaidAmount, PurchaseInvoiceStatistics."Paid WHT Prepaid Amount (LCY)".AsDEcimal,
          LibraryERM.GetAmountRoundingPrecision, ValueMustBeSameMsg);
        PurchaseInvoiceStatistics.OK.Invoke;
    end;

    local procedure VerifyPurchCreditMemoStatisticsPage(PurchCreditMemoStatistics: TestPage "Purch. Credit Memo Statistics"; RemWHTPrepaidAmount: Decimal; PaidWHTPrepaidAmount: Decimal)
    begin
        Assert.AreNearlyEqual(
          RemWHTPrepaidAmount, PurchCreditMemoStatistics."Rem. WHT Prepaid Amount (LCY)".AsDEcimal,
          LibraryERM.GetAmountRoundingPrecision, ValueMustBeSameMsg);
        Assert.AreNearlyEqual(
          PaidWHTPrepaidAmount, PurchCreditMemoStatistics."Paid WHT Prepaid Amount (LCY)".AsDEcimal,
          LibraryERM.GetAmountRoundingPrecision, ValueMustBeSameMsg);
        PurchCreditMemoStatistics.OK.Invoke;
    end;

    local procedure VerifyPurchaseInvoiceWHTEntry(DocumentType: Option; BillToPayToNo: Code[20]; RemainingUnrealizedAmount: Decimal; UnrealizedAmountLCY: Decimal)
    var
        WHTEntry: Record "WHT Entry";
    begin
        FilterOnWHTEntry(WHTEntry, DocumentType, BillToPayToNo);
        WHTEntry.FindFirst;
        Assert.AreNearlyEqual(
          RemainingUnrealizedAmount, WHTEntry."Remaining Unrealized Amount", LibraryERM.GetAmountRoundingPrecision, ValueMustBeSameMsg);
        Assert.AreNearlyEqual(
          UnrealizedAmountLCY, WHTEntry."Unrealized Amount (LCY)", LibraryERM.GetAmountRoundingPrecision, ValueMustBeSameMsg);
    end;

    local procedure VerifyGSTPurchaseEntry(DocumentNo: Code[20]; DocumentLineType: Option)
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        // Verify GST Purchase Entry Created with Zero Amount.
        PurchasesPayablesSetup.Get;
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        GSTPurchaseEntry.SetRange("Document Line Type", DocumentLineType);
        GSTPurchaseEntry.FindFirst;
        GSTPurchaseEntry.TestField("VAT Prod. Posting Group", PurchasesPayablesSetup."GST Prod. Posting Group");
        GSTPurchaseEntry.TestField(Amount, 0);
    end;

    local procedure VerifyGSTPurchaseEntries(DocumentNo: Code[20])
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        // Verify GST Purchase Entry Created for different Line Type with Zero Amount.
        VerifyGSTPurchaseEntry(DocumentNo, GSTPurchaseEntry."Document Line Type"::"G/L Account");
        VerifyGSTPurchaseEntry(DocumentNo, GSTPurchaseEntry."Document Line Type"::Item);
    end;

    local procedure VerifyPaymentDiscountOnDetailedVendorLedgEntry(DocumentNo: Code[20])
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        Amount: Decimal;
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields(Amount);
        DetailedVendorLedgEntry.SetRange("Entry Type", DetailedVendorLedgEntry."Entry Type"::"Payment Discount");
        DetailedVendorLedgEntry.SetRange("Document Type", DetailedVendorLedgEntry."Document Type"::Payment);
        DetailedVendorLedgEntry.SetRange("Vendor No.", PurchInvHeader."Buy-from Vendor No.");
        DetailedVendorLedgEntry.FindFirst;
        Amount := PurchInvHeader.Amount * PurchInvHeader."Payment Discount %" / 100;
        Assert.AreNearlyEqual(Amount, DetailedVendorLedgEntry.Amount, LibraryERM.GetAmountRoundingPrecision, ValueMustBeSameMsg);
    end;

    local procedure VerifyPurchaseInvoiceStatisticsWHTAndGSTEntries(PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics"; PostedPurchaseInvoice: TestPage "Posted Purchase Invoice"; DocumentNo: Code[20]; WHTAmount: Decimal; VendorNo: Code[20])
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
        WHTEntry: Record "WHT Entry";
    begin
        VerifyPurchaseInvoiceStatisticsPageAndWHTEntry(
          PurchaseInvoiceStatistics, PostedPurchaseInvoice, WHTEntry."Document Type"::Invoice, VendorNo, 0, WHTAmount, 0, WHTAmount);  // Remaining WHT Prepaid Amount and Amount - 0.
        VerifyWHTEntry(WHTEntry."Document Type"::Payment, VendorNo, WHTAmount, 0);  // Unrealized Amount - 0.
        VerifyGSTPurchaseEntry(DocumentNo, GSTPurchaseEntry."Document Line Type"::"G/L Account");
    end;

    local procedure VerifyGLEntryWHTAmount(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLEntry: Record "G/L Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        WHTPostingSetup.Get(GenJournalLine."WHT Business Posting Group", GenJournalLine."WHT Product Posting Group");
        GLEntry.SetRange("Document Type", GenJournalLine."Document Type");
        GLEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GLEntry.SetRange("G/L Account No.", WHTPostingSetup."Payable WHT Account Code");
        GLEntry.FindFirst;
        GLEntry.TestField(Amount, -24);
    end;
}

