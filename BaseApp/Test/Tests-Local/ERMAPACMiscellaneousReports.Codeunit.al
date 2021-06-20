codeunit 141076 "ERM APAC Miscellaneous Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmtRcdNotInvoicedCap: Label 'Purchase_Line__Amt__Rcd__Not_Invoiced_';
        BuyFromVendorNoFilterTxt: Label '%1|%2';
        NextRowExistMsg: Label 'Next Row exist.';
        PayToVendorNoCap: Label 'Purchase_Header__Pay_to_Vendor_No__';
        QtyRcdNotInvoicedCap: Label 'Purchase_Line__Qty__Rcd__Not_Invoiced_';
        QuantityInvoicedCap: Label 'Purchase_Line__Quantity_Invoiced_';
        QuantityReceivedCap: Label 'Purchase_Line__Quantity_Received_';
        ReceivedQuantityCap: Label 'ReceivedQty';
        ReceivedCostCap: Label 'ReceivedCost';
        TotalBalanceAmountCap: Label 'TotalBalanceAmount';
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [HandlerFunctions('ItemsReceivedAndNotInvoicedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure MultiplePOItemsReceivedAndNotInvoicedReport()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        Quantity: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [Items Received and Not Invoiced]
        // [SCENARIO] values on Items Received and Not Invoiced report after posting multiple Purchase Order as Receive and Invoice.

        // Setup: Create and post two Purchase Orders for different Vendors.
        Initialize;
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndPostPurchaseOrder(PurchaseLine, true, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDec(10, 2));  // True for Invoice. Random value used for Quantity and Qty. to Invoice.
        CreateAndPostPurchaseOrder(PurchaseLine2, true, Quantity, Quantity);  // True for Invoice. Random value used for Quantity and Qty. to Invoice.
        EnqueueValuesForItemsRcdAndNotInvdRqstPageHandler(PurchaseLine."Buy-from Vendor No.", PurchaseLine2."Buy-from Vendor No.");

        // Exercise and Verify: Run Items Received and Not Invoiced report and verify Xml values for first Purchase Order and verify No row exist for second Purchase Order.
        RunItemsRcdAndNotInvdRptAndVerifyXmlValues(PurchaseLine);
        LibraryReportDataset.SetRange(PayToVendorNoCap, PurchaseLine2."Buy-from Vendor No.");
        Assert.IsFalse(LibraryReportDataset.GetNextRow, NextRowExistMsg);
    end;

    [Test]
    [HandlerFunctions('ItemsReceivedAndNotInvoicedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostPOAsInvoiceItemsReceivedAndNotInvoicedReport()
    begin
        // [FEATURE] [Purchase] [Order] [Items Received and Not Invoiced]
        // [SCENARIO] values on Items Received and Not Invoiced report after posting Purchase Order as Receive and Invoice.
        PostPOItemsReceivedAndNotInvoicedReport(true);  // True for Invoice.
    end;

    [Test]
    [HandlerFunctions('ItemsReceivedAndNotInvoicedRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostPOAsReceiveItemsReceivedAndNotInvoicedReport()
    begin
        // [FEATURE] [Purchase] [Order] [Items Received and Not Invoiced]
        // [SCENARIO] values on Items Received and Not Invoiced report after posting Purchase Order as Receive.
        PostPOItemsReceivedAndNotInvoicedReport(false);  // False for Invoice.
    end;

    local procedure PostPOItemsReceivedAndNotInvoicedReport(Invoice: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create and post Purchase Order.
        Initialize;
        CreateAndPostPurchaseOrder(
          PurchaseLine, Invoice, LibraryRandom.RandDecInRange(10, 50, 2), LibraryRandom.RandDec(10, 2));  // Random value for Quantity and Qty. To Invoice.
        EnqueueValuesForItemsRcdAndNotInvdRqstPageHandler(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");

        // Exercise and Verify.
        RunItemsRcdAndNotInvdRptAndVerifyXmlValues(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('StockCardRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderValueOnStockCardReport()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Order] [Stock Card]
        // [SCENARIO] values on Report - Stock Card after posting Purchase Order.

        // Setup: Create and Post Purchase Order.
        Initialize;
        CreateAndPostPurchaseOrder(
          PurchaseLine, true, LibraryRandom.RandDecInRange(50, 100, 2), LibraryRandom.RandDecInRange(10, 50, 2));  // True for Invoice. Random value used for Quantity and Qty. to Invoice.
        LibraryVariableStorage.Enqueue(PurchaseLine."No.");

        // Exercise.
        RunStockCardReport(PurchaseLine."No.");

        // Verify: Verify Received Quantity, Received Cost and Amount On Report - Stock Card.
        VerifyReceivedQuantityCostAndAmountOnStockCardReport(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReport()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice]
        // [SCENARIO 362109] Print VAT Amount in "Purchase - Invoice" report
        Initialize;
        // [GIVEN] Posted Purchase Invoice with tax amount = "X"
        CreateAndPostPurchaseDocument(DocumentNo, VATAmount, PurchaseHeader."Document Type"::Invoice);
        // [WHEN] Preview "Purchase - Invoice" report
        RunPurchaseInvoiceReport(DocumentNo);
        // [THEN] VAT Amount in report VAT specification = "X"
        VerifyPurchaseDocumentVATAmount(VATAmount);
    end;

    [Test]
    [HandlerFunctions('PurchaseCrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoReport()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo]
        // [SCENARIO 362109] Print VAT Amount in "Purchase - Credit Memo" report
        Initialize;
        // [GIVEN] Posted Purchase Credit Memo with tax amount = "X"
        CreateAndPostPurchaseDocument(DocumentNo, VATAmount, PurchaseHeader."Document Type"::"Credit Memo");
        // [WHEN] Preview "Purchase - Credit Memo" report
        RunPurchaseCrMemoReport(DocumentNo);
        // [THEN] VAT Amount in report VAT specification = "X"
        VerifyPurchaseDocumentVATAmount(VATAmount);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicetReport()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 362109] Print VAT Amount in "Sales - Invoice" report
        Initialize;
        // [GIVEN] Posted Sales Invoice with tax amount = "X"
        CreateAndPostSalesDocument(DocumentNo, VATAmount, SalesHeader."Document Type"::Invoice);
        // [WHEN] Preview "Sales - Invoice" report
        RunSalesInvoiceReport(DocumentNo);
        // [THEN] VAT Amount in report VAT specification = "X"
        VerifySalesDocumentVATAmount(VATAmount);
    end;

    [Test]
    [HandlerFunctions('SalesCrMemoReportHandler')]
    [Scope('OnPrem')]
    procedure SalesCrMemoReport()
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 362109] Print VAT Amount in "Sales - Credit Memo" report
        Initialize;
        // [GIVEN] Posted Sales Credit Memo with tax amount = "X"
        CreateAndPostSalesDocument(DocumentNo, VATAmount, SalesHeader."Document Type"::"Credit Memo");
        // [WHEN] Preview "Sales - Credit Memo" report
        RunSalesCreditMemoReport(DocumentNo);
        // [THEN] VAT Amount in report VAT specification = "X"
        VerifySalesDocumentVATAmount(VATAmount);
    end;

    [Test]
    [HandlerFunctions('BankAccountReconciliationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReversedEntriesAreNotShownInBankAccountReconciliation()
    var
        BankAccount: Record "Bank Account";
        ExpectedDocumentNo: array[2] of Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [Reverse] [Bank Account Reconciliation]
        // [SCENARIO 231426] Reversed Bank Account Ledger Entries are not shown when report "Bank Account Reconciliation" is printed.
        Initialize;

        ExpectedDocumentNo[1] := LibraryUtility.GenerateGUID;
        ExpectedDocumentNo[2] := LibraryUtility.GenerateGUID;

        // [GIVEN] Bank Account "B"
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.SetRecFilter;

        // [GIVEN] Bank Account Ledger Entry for Payment "P1"
        MockBankAccountLedgerEntry(ExpectedDocumentNo[1], BankAccount."No.", false, -LibraryRandom.RandDecInRange(1000, 2000, 2));

        // [GIVEN] Bank Account Ledger Entry for Payment "P2"
        // [GIVEN] Reversed Bank Account Ledger Entry for Payment "P2"
        Amount := LibraryRandom.RandDecInRange(1000, 2000, 2);
        MockBankAccountLedgerEntry(ExpectedDocumentNo[2], BankAccount."No.", true, -Amount);
        MockBankAccountLedgerEntry(ExpectedDocumentNo[2], BankAccount."No.", true, Amount);

        Commit;

        // [WHEN] Run report "Bank Account Reconciliation" for "B".
        REPORT.RunModal(REPORT::"Bank Account Reconciliation", true, false, BankAccount);

        // [THEN] Payment "X" exists in export XML.
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementTagWithValueExists('Bank_Account_Ledger_Entry1__Document_No__', ExpectedDocumentNo[1]);

        // [THEN] Payment "Y" doesn't exist in export XML.
        LibraryReportDataset.AssertElementTagWithValueNotExist('Bank_Account_Ledger_Entry1__Document_No__', ExpectedDocumentNo[2]);
        LibraryReportDataset.AssertElementTagWithValueNotExist('Bank_Account_Ledger_Entry2__Document_No__', ExpectedDocumentNo[2]);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear;
    end;

    local procedure MockBankAccountLedgerEntry(DocumentNo: Code[20]; BankAccountNo: Code[20]; Reversed: Boolean; Amount: Decimal)
    var
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(BankAccountLedgerEntry, BankAccountLedgerEntry.FieldNo("Entry No."));
        BankAccountLedgerEntry."Bank Account No." := BankAccountNo;
        BankAccountLedgerEntry."Document No." := DocumentNo;
        BankAccountLedgerEntry.Reversed := Reversed;
        BankAccountLedgerEntry.Open := true;
        BankAccountLedgerEntry.Amount := Amount;
        BankAccountLedgerEntry.Insert;
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseLine: Record "Purchase Line"; Invoice: Boolean; Quantity: Decimal; QtyToInvoice: Decimal)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Qty. to Invoice", QtyToInvoice);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice);  // True for Receive.
    end;

    local procedure CreateAndPostPurchaseDocument(var DocumentNo: Code[20]; var VATAmount: Decimal; DocType: Option)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, Vendor."No.");
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Credit Memo" then begin
            PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
            PurchaseHeader.Modify(true);
        end;
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(1000));
        PurchaseLine.Modify(true);
        VATAmount := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesDocument(var DocumentNo: Code[20]; var VATAmount: Decimal; DocType: Option)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(1000));
        SalesLine.Modify(true);
        VATAmount := SalesLine."Amount Including VAT" - SalesLine.Amount;
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure EnqueueValuesForItemsRcdAndNotInvdRqstPageHandler(BuyFromVendorNo: Code[20]; BuyFromVendorNo2: Code[20])
    begin
        // Enqueue values for ItemsReceivedAndNotInvoicedRequestPageHandler.
        LibraryVariableStorage.Enqueue(BuyFromVendorNo);
        LibraryVariableStorage.Enqueue(BuyFromVendorNo2);
    end;

    local procedure RunItemsRcdAndNotInvdRptAndVerifyXmlValues(var PurchaseLine: Record "Purchase Line")
    begin
        // Exercise.
        REPORT.Run(REPORT::"Items Received & Not Invoiced");  // Opens ItemsReceivedAndNotInvoicedRequestPageHandler.

        // Verify: Values on Items Received and not Invoiced Report.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        LibraryReportDataset.LoadDataSetFile;
        VerifyValuesOnItemsReceivedAndNotInvoicedReport(
          PurchaseLine."Quantity Invoiced", PurchaseLine."Quantity Received", PurchaseLine."Qty. Rcd. Not Invoiced",
          PurchaseLine."Amt. Rcd. Not Invoiced");
    end;

    local procedure RunStockCardReport(ItemNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        StockCard: Report "Stock Card";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        StockCard.SetTableView(ItemLedgerEntry);
        StockCard.Run;  // Opens StockCardRequestPageHandler.
    end;

    local procedure RunPurchaseInvoiceReport(DocumentNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchaseInvoice: Report "Purchase - Invoice";
    begin
        PurchInvHeader.SetRange("No.", DocumentNo);
        PurchaseInvoice.SetTableView(PurchInvHeader);
        PurchaseInvoice.InitializeRequest(0, false, false);
        PurchaseInvoice.Run;
    end;

    local procedure RunPurchaseCrMemoReport(DocumentNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchaseCreditMemo: Report "Purchase - Credit Memo";
    begin
        PurchCrMemoHdr.SetRange("No.", DocumentNo);
        PurchaseCreditMemo.SetTableView(PurchCrMemoHdr);
        PurchaseCreditMemo.InitializeRequest(0, false, false);
        PurchaseCreditMemo.Run;
    end;

    local procedure RunSalesInvoiceReport(DocumentNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoice: Report "Sales - Invoice";
    begin
        SalesInvoiceHeader.SetRange("No.", DocumentNo);
        SalesInvoice.SetTableView(SalesInvoiceHeader);
        SalesInvoice.InitializeRequest(0, false, false, false, false, false, false, false);
        SalesInvoice.Run;
    end;

    local procedure RunSalesCreditMemoReport(DocumentNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCreditMemoReport: Report "Sales - Credit Memo";
    begin
        SalesCrMemoHeader.SetRange("No.", DocumentNo);
        SalesCreditMemoReport.SetTableView(SalesCrMemoHeader);
        SalesCreditMemoReport.InitializeRequest(0, false, false, false, false, false);
        SalesCreditMemoReport.Run;
    end;

    local procedure VerifyReceivedQuantityCostAndAmountOnStockCardReport(PurchaseLine: Record "Purchase Line")
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists(
          ReceivedQuantityCap, Round(PurchaseLine."Qty. to Invoice", LibraryERM.GetAmountRoundingPrecision));
        LibraryReportDataset.AssertElementWithValueExists(ReceivedCostCap, PurchaseLine."Direct Unit Cost");
        LibraryReportDataset.AssertElementWithValueExists(
          TotalBalanceAmountCap, PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost");
    end;

    local procedure VerifyValuesOnItemsReceivedAndNotInvoicedReport(QuantityInvoiced: Decimal; QuantityReceived: Decimal; QtyRcdNotInvoiced: Decimal; AmtRcdNotInvoiced: Decimal)
    begin
        LibraryReportDataset.AssertElementWithValueExists(QuantityInvoicedCap, QuantityInvoiced);
        LibraryReportDataset.AssertElementWithValueExists(QuantityReceivedCap, QuantityReceived);
        LibraryReportDataset.AssertElementWithValueExists(QtyRcdNotInvoicedCap, QtyRcdNotInvoiced);
        LibraryReportDataset.AssertElementWithValueExists(AmtRcdNotInvoicedCap, AmtRcdNotInvoiced);
    end;

    local procedure VerifyPurchaseDocumentVATAmount(VATAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('VATAmountLineVATAmount', VATAmount);
    end;

    local procedure VerifySalesDocumentVATAmount(VATAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile;
        LibraryReportDataset.AssertElementWithValueExists('VATAmt_VATAmtLine', VATAmount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemsReceivedAndNotInvoicedRequestPageHandler(var ItemsReceivedAndNotInvoiced: TestRequestPage "Items Received & Not Invoiced")
    var
        BuyFromVendorNo: Variant;
        BuyFromVendorNo2: Variant;
    begin
        LibraryVariableStorage.Dequeue(BuyFromVendorNo);
        LibraryVariableStorage.Dequeue(BuyFromVendorNo2);
        ItemsReceivedAndNotInvoiced."Purchase Header".SetFilter(
          "Buy-from Vendor No.", StrSubstNo(BuyFromVendorNoFilterTxt, BuyFromVendorNo, BuyFromVendorNo2));
        ItemsReceivedAndNotInvoiced.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StockCardRequestPageHandler(var StockCard: TestRequestPage "Stock Card")
    var
        ItemNo: Variant;
        GroupTotals: Option Location;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        StockCard.GroupTotals.SetValue(GroupTotals::Location);
        StockCard."Item Ledger Entry".SetFilter("Item No.", ItemNo);
        StockCard."Item Ledger Entry".SetFilter("Posting Date", Format(WorkDate));
        StockCard.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReportHandler(var PurchaseInvoice: TestRequestPage "Purchase - Invoice")
    begin
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoReportHandler(var PurchaseCrMemo: TestRequestPage "Purchase - Credit Memo")
    begin
        PurchaseCrMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceReportHandler(var SalesInvoice: TestRequestPage "Sales - Invoice")
    begin
        SalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesCrMemoReportHandler(var SalesCrMemo: TestRequestPage "Sales - Credit Memo")
    begin
        SalesCrMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountReconciliationRequestPageHandler(var BankAccountReconciliation: TestRequestPage "Bank Account Reconciliation")
    begin
        BankAccountReconciliation.SaveAsXml(LibraryReportDataset.GetParametersFileName, LibraryReportDataset.GetFileName);
    end;
}

