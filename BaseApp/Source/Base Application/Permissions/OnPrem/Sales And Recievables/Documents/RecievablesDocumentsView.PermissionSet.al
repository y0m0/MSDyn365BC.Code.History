permissionset 312 "Recievables Documents - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read posted shipments, etc.';

    Permissions = tabledata "General Posting Setup" = r,
                  tabledata "Item Reference" = R,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Report Selections" = R,
                  tabledata "Return Receipt Header" = RM,
                  tabledata "Return Receipt Line" = RM,
                  tabledata "Sales Comment Line" = RIMD,
                  tabledata "Sales Cr.Memo Header" = Rm,
                  tabledata "Sales Cr.Memo Line" = R,
                  tabledata "Sales Invoice Header" = Rm,
                  tabledata "Sales Invoice Line" = R,
                  tabledata "Sales Shipment Header" = RM,
                  tabledata "Sales Shipment Line" = RM,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "User Setup" = r,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Setup Posting Groups" = R;
}
