permissionset 2529 "Recievables Documents - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Post sales orders, etc.';

    Permissions = tabledata "Accounting Period" = r,
                  tabledata "Activities Cue" = RIMD,
                  tabledata "Additional Fee Setup" = r,
                  tabledata "Alt. Customer Posting Group" = r,
                  tabledata "Alt. Vendor Posting Group" = r,
                  tabledata "Analysis View" = rimd,
                  tabledata "Analysis View Entry" = rim,
                  tabledata "Analysis View Filter" = r,
                  tabledata "Avg. Cost Adjmt. Entry Point" = Rim,
                  tabledata "Bank Account" = m,
                  tabledata "Bank Account Ledger Entry" = rim,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata "Check Ledger Entry" = rim,
                  tabledata Currency = r,
                  tabledata "Currency Exchange Rate" = r,
                  tabledata "Currency for Reminder Level" = r,
                  tabledata "Cust. Ledger Entry" = rim,
                  tabledata Customer = R,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Customer Posting Group" = r,
                  tabledata "Detailed Cust. Ledg. Entry" = ri,
                  tabledata "Dimension Combination" = R,
                  tabledata "Dimension Value Combination" = R,
                  tabledata "G/L Account" = r,
                  tabledata "G/L Entry - VAT Entry Link" = Ri,
                  tabledata "G/L Entry" = Ri,
                  tabledata "G/L Register" = Rim,
                  tabledata "General Ledger Setup" = rm,
                  tabledata "General Posting Setup" = r,
                  tabledata "IC Bank Account" = R,
                  tabledata "IC Comment Line" = RIMD,
                  tabledata "IC Dimension" = R,
                  tabledata "IC Dimension Value" = R,
                  tabledata "IC Document Dimension" = RIMD,
                  tabledata "IC G/L Account" = R,
                  tabledata "IC Inbox/Outbox Jnl. Line Dim." = RIMD,
                  tabledata "IC Outbox Jnl. Line" = RIMD,
                  tabledata "IC Outbox Sales Header" = RIMD,
                  tabledata "IC Outbox Sales Line" = RIMD,
                  tabledata "IC Outbox Transaction" = RIMD,
                  tabledata "IC Partner" = R,
                  tabledata "IC Setup" = R,
                  tabledata "Inventory Posting Group" = r,
                  tabledata "Inventory Posting Setup" = r,
                  tabledata Item = rm,
                  tabledata "Item Application Entry" = m,
                  tabledata "Item Charge Assignment (Purch)" = Rm,
                  tabledata "Item Charge Assignment (Sales)" = Rd,
                  tabledata "Item Ledger Entry" = Rim,
                  tabledata "Item Register" = Rim,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Item Variant" = R,
                  tabledata Job = R,
                  tabledata "Job Ledger Entry" = Rim,
                  tabledata "Job Register" = Rim,
                  tabledata "Line Fee Note on Report Hist." = rim,
                  tabledata "Lot No. Information" = R,
                  tabledata "My Customer" = Rimd,
                  tabledata "My Item" = Rimd,
                  tabledata "Order Promising Line" = RiMD,
                  tabledata "Package No. Information" = R,
                  tabledata "Planning Component" = Rm,
                  tabledata "Post Value Entry to G/L" = i,
                  tabledata "Posted Whse. Shipment Header" = R,
                  tabledata "Posted Whse. Shipment Line" = R,
                  tabledata "Prod. Order Component" = Rm,
                  tabledata "Prod. Order Line" = Rm,
                  tabledata "Purch. Rcpt. Header" = i,
                  tabledata "Purch. Rcpt. Line" = i,
                  tabledata "Purchase Header" = Rm,
                  tabledata "Purchase Line" = Rm,
                  tabledata "Reminder Level" = r,
                  tabledata "Reminder Terms" = r,
                  tabledata "Reminder Terms Translation" = r,
                  tabledata "Report Selections" = R,
                  tabledata "Res. Ledger Entry" = Ri,
                  tabledata Resource = R,
                  tabledata "Resource Register" = Rim,
                  tabledata "Return Receipt Header" = Rim,
                  tabledata "Return Receipt Line" = Rim,
                  tabledata "Sales Comment Line" = RD,
                  tabledata "Sales Cr.Memo Header" = Rim,
                  tabledata "Sales Cr.Memo Line" = Ri,
                  tabledata "Sales Cue" = R,
                  tabledata "Sales Header" = RMD,
                  tabledata "Sales Invoice Header" = Rim,
                  tabledata "Sales Invoice Line" = Rid,
                  tabledata "Sales Line" = Rd,
                  tabledata "Sales Shipment Header" = Rim,
                  tabledata "Sales Shipment Line" = Rim,
                  tabledata "Serial No. Information" = R,
                  tabledata "Service Document Register" = Rd,
                  tabledata "Service Mgt. Setup" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Shipping Agent Services" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "User Setup" = r,
                  tabledata "Value Entry" = Rim,
                  tabledata "VAT Amount Line" = RIMD,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Entry" = Ri,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Setup Posting Groups" = R,
				  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "Warehouse Request" = RIMD,
                  tabledata "Whse. Pick Request" = RIMD;
}
