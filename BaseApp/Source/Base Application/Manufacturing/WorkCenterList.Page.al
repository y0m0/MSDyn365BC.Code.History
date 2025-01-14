page 99000755 "Work Center List"
{
    AdditionalSearchTerms = 'production resource,production personnel';
    ApplicationArea = Manufacturing;
    Caption = 'Work Centers';
    CardPageID = "Work Center Card";
    Editable = false;
    PageType = List;
    SourceTable = "Work Center";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the name of the work center.';
                }
                field("Alternate Work Center"; Rec."Alternate Work Center")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an alternate work center.';
                }
                field("Work Center Group Code"; Rec."Work Center Group Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the work center group, if the work center or underlying machine center is assigned to a work center group.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                    Visible = false;
                }
                field("Indirect Cost %"; Rec."Indirect Cost %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the percentage of the center''s cost that includes indirect costs, such as machine maintenance.';
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Capacity; Capacity)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the amount of work that can be done in a specified time period. The capacity of a work center indicates how many machines or persons are working at the same time. If you enter 2, for example, the work center will take half of the time compared to a work center with the capacity of 1. ';
                }
                field(Efficiency; Efficiency)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the efficiency factor as a percentage of the work center.';
                    Visible = false;
                }
                field("Maximum Efficiency"; Rec."Maximum Efficiency")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the maximum efficiency factor of the work center.';
                    Visible = false;
                }
                field("Minimum Efficiency"; Rec."Minimum Efficiency")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the minimum efficiency factor of the work center.';
                    Visible = false;
                }
                field("Simulation Type"; Rec."Simulation Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the simulation type for the work center.';
                    Visible = false;
                }
                field("Shop Calendar Code"; Rec."Shop Calendar Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the shop calendar code that the planning of this work center refers to.';
                }
                field("Search Name"; Rec."Search Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an alternate name that you can use to search for the record in question when you cannot remember the value in the Name field.';
                }
                field("Overhead Rate"; Rec."Overhead Rate")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the overhead rate of this work center.';
                    Visible = false;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies when the work center card was last modified.';
                    Visible = false;
                }
                field("Flushing Method"; Rec."Flushing Method")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how consumption of the item (component) is calculated and handled in production processes. Manual: Enter and post consumption in the consumption journal manually. Forward: Automatically posts consumption according to the production order component lines when the first operation starts. Backward: Automatically calculates and posts consumption according to the production order component lines when the production order is finished. Pick + Forward / Pick + Backward: Variations with warehousing.';
                    Visible = false;
                }
                field("Subcontractor No."; Rec."Subcontractor No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of a subcontractor who supplies this work center.';
                    Visible = false;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Wor&k Ctr.")
            {
                Caption = 'Wor&k Ctr.';
                Image = WorkCenter;
                action("Capacity Ledger E&ntries")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Capacity Ledger E&ntries';
                    Image = CapacityLedger;
                    RunObject = Page "Capacity Ledger Entries";
                    RunPageLink = "Work Center No." = FIELD("No."),
                                  "Posting Date" = FIELD("Date Filter");
                    RunPageView = SORTING("Work Center No.", "Work Shift Code", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the capacity ledger entries of the involved production order. Capacity is recorded either as time (run time, stop time, or setup time) or as quantity (scrap quantity or output quantity).';
                }
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Manufacturing Comment Sheet";
                    RunPageLink = "No." = FIELD("No.");
                    RunPageView = WHERE("Table Name" = CONST("Work Center"));
                    ToolTip = 'View or add comments for the record.';
                }
                group(Dimensions)
                {
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    action("Dimensions-Single")
                    {
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-Single';
                        Image = Dimensions;
                        RunObject = Page "Default Dimensions";
                        RunPageLink = "Table ID" = CONST(99000754),
                                      "No." = FIELD("No.");
                        ShortCutKey = 'Alt+D';
                        ToolTip = 'View or edit the single set of dimensions that are set up for the selected record.';
                    }
                    action("Dimensions-&Multiple")
                    {
                        AccessByPermission = TableData Dimension = R;
                        ApplicationArea = Dimensions;
                        Caption = 'Dimensions-&Multiple';
                        Image = DimensionSets;
                        ToolTip = 'View or edit dimensions for a group of records. You can assign dimension codes to transactions to distribute costs and analyze historical information.';

                        trigger OnAction()
                        var
                            Work: Record "Work Center";
                            DefaultDimMultiple: Page "Default Dimensions-Multiple";
                        begin
                            CurrPage.SetSelectionFilter(Work);
                            DefaultDimMultiple.SetMultiRecord(Work, FieldNo("No."));
                            DefaultDimMultiple.RunModal();
                        end;
                    }
                }
                action("Lo&ad")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Lo&ad';
                    Image = WorkCenterLoad;
                    RunObject = Page "Work Center Load";
                    RunPageLink = "No." = FIELD("No.");
                    RunPageView = SORTING("No.");
                    ToolTip = 'View the availability of the machine or work center, including its capacity, the allocated quantity, availability after orders, and the load in percent of its total capacity.';
                }
                action(Statistics)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Work Center Statistics";
                    RunPageLink = "No." = FIELD("No."),
                                  "Date Filter" = FIELD("Date Filter"),
                                  "Work Shift Filter" = FIELD("Work Shift Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
            }
            group("Pla&nning")
            {
                Caption = 'Pla&nning';
                Image = Planning;
                action("&Calendar")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Calendar';
                    Image = MachineCenterCalendar;
                    RunObject = Page "Work Center Calendar";
                    ToolTip = 'Open the shop calendar, for example to see the load.';
                }
                action("A&bsence")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'A&bsence';
                    Image = WorkCenterAbsence;
                    RunObject = Page "Capacity Absence";
                    RunPageLink = "Capacity Type" = CONST("Work Center"),
                                  "No." = FIELD("No."),
                                  Date = FIELD("Date Filter");
                    ToolTip = 'View which working days are not available. ';
                }
                action("Ta&sk List")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ta&sk List';
                    Image = TaskList;
                    RunObject = Page "Work Center Task List";
                    RunPageLink = "No." = FIELD("No.");
                    RunPageView = SORTING(Type, "No.")
                                  WHERE(Type = CONST("Work Center"),
                                        Status = FILTER(.. Released),
                                        "Routing Status" = FILTER(<> Finished));
                    ToolTip = 'View the list of operations that are scheduled for the work center.';
                }
            }
        }
        area(processing)
        {
            action("Calculate Work Center Calendar")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Calculate Work Center Calendar';
                Image = CalcWorkCenterCalendar;
                RunObject = Report "Calculate Work Center Calendar";
                ToolTip = 'Create new calendar entries for the work center to define the available daily capacity.';
            }
        }
        area(reporting)
        {
            action("Work Center List")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Work Center List';
                Image = "Report";
                RunObject = Report "Work Center List";
                ToolTip = 'View or edit the list of work centers.';
            }
            action("Work Center Load")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Work Center Load';
                Image = "Report";
                RunObject = Report "Work Center Load";
                ToolTip = 'Get an overview of availability at the work center, such as the capacity, the allocated quantity, availability after order, and the load in percent.';
            }
            action("Work Center Load/Bar")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Work Center Load/Bar';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Work Center Load/Bar";
                ToolTip = 'View a list of work centers that are overloaded according to the plan. The efficiency or overloading is shown by efficiency bars.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Calculate Work Center Calendar_Promoted"; "Calculate Work Center Calendar")
                {
                }
                actionref("&Calendar_Promoted"; "&Calendar")
                {
                }
                actionref("A&bsence_Promoted"; "A&bsence")
                {
                }
                actionref("Ta&sk List_Promoted"; "Ta&sk List")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Work Center List_Promoted"; "Work Center List")
                {
                }
                actionref("Work Center Load_Promoted"; "Work Center Load")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Work Center', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                group(Category_Dimensions)
                {
                    Caption = 'Dimensions';
                    ShowAs = SplitButton;

                    actionref("Dimensions-&Multiple_Promoted"; "Dimensions-&Multiple")
                    {
                    }
                    actionref("Dimensions-Single_Promoted"; "Dimensions-Single")
                    {
                    }
                }
            }
        }
    }
}

