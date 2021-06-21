table 99000829 "Planning Component"
{
    Caption = 'Planning Component';
    DrillDownPageID = "Planning Component List";
    LookupPageID = "Planning Component List";

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            TableRelation = "Req. Wksh. Template";
        }
        field(2; "Worksheet Batch Name"; Code[10])
        {
            Caption = 'Worksheet Batch Name';
            TableRelation = "Requisition Wksh. Name".Name WHERE("Worksheet Template Name" = FIELD("Worksheet Template Name"));
        }
        field(3; "Worksheet Line No."; Integer)
        {
            Caption = 'Worksheet Line No.';
            TableRelation = "Requisition Line"."Line No." WHERE("Worksheet Template Name" = FIELD("Worksheet Template Name"),
                                                                 "Journal Batch Name" = FIELD("Worksheet Batch Name"));
        }
        field(5; "Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Line No.';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item WHERE(Type = FILTER(Inventory | "Non-Inventory"));

            trigger OnValidate()
            begin
                ReservePlanningComponent.VerifyChange(Rec, xRec);
                CalcFields("Reserved Qty. (Base)");
                TestField("Reserved Qty. (Base)", 0);

                if "Item No." = '' then begin
                    "Dimension Set ID" := 0;
                    "Shortcut Dimension 1 Code" := '';
                    "Shortcut Dimension 2 Code" := '';
                    exit;
                end;

                GetItem;
                Description := Item.Description;
                Validate("Unit of Measure Code", Item."Base Unit of Measure");
                GetUpdateFromSKU;
                CreateDim(DATABASE::Item, "Item No.");
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            begin
                TestField("Item No.");

                GetItem;
                GetGLSetup;

                "Unit Cost" := Item."Unit Cost";

                if "Unit of Measure Code" <> '' then begin
                    "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                    "Unit Cost" :=
                      Round(
                        Item."Unit Cost" * "Qty. per Unit of Measure",
                        GLSetup."Unit-Amount Rounding Precision");
                end else
                    "Qty. per Unit of Measure" := 1;

                "Indirect Cost %" := Round(Item."Indirect Cost %" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);

                "Overhead Rate" := Item."Overhead Rate";

                "Direct Unit Cost" :=
                  Round(
                    ("Unit Cost" - "Overhead Rate" * "Qty. per Unit of Measure") / (1 + "Indirect Cost %" / 100),
                    GLSetup."Unit-Amount Rounding Precision");

                Validate("Calculation Formula");
            end;
        }
        field(14; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(15; Position; Code[10])
        {
            Caption = 'Position';
        }
        field(16; "Position 2"; Code[10])
        {
            Caption = 'Position 2';
        }
        field(17; "Position 3"; Code[10])
        {
            Caption = 'Position 3';
        }
        field(18; "Lead-Time Offset"; DateFormula)
        {
            Caption = 'Lead-Time Offset';
        }
        field(19; "Routing Link Code"; Code[10])
        {
            Caption = 'Routing Link Code';
            TableRelation = "Routing Link";

            trigger OnValidate()
            var
                PlanningRtngLine: Record "Planning Routing Line";
            begin
                Validate("Expected Quantity", Quantity * PlanningNeeds);

                "Due Date" := ReqLine."Starting Date";
                "Due Time" := ReqLine."Starting Time";
                if "Routing Link Code" <> '' then begin
                    PlanningRtngLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
                    PlanningRtngLine.SetRange("Worksheet Batch Name", "Worksheet Batch Name");
                    PlanningRtngLine.SetRange("Worksheet Line No.", "Worksheet Line No.");
                    PlanningRtngLine.SetRange("Routing Link Code", "Routing Link Code");
                    if PlanningRtngLine.FindFirst then begin
                        "Due Date" := PlanningRtngLine."Starting Date";
                        "Due Time" := PlanningRtngLine."Starting Time";
                    end;
                end;
                if Format("Lead-Time Offset") <> '' then begin
                    if "Due Date" = 0D then
                        "Due Date" := ReqLine."Ending Date";
                    "Due Date" :=
                      "Due Date" -
                      (CalcDate("Lead-Time Offset", WorkDate) - WorkDate);
                    "Due Time" := 0T;
                end;

                OnValidateRoutingLinkCodeOnBeforeValidateDueDate(Rec, ReqLine);
                Validate("Due Date");
            end;
        }
        field(20; "Scrap %"; Decimal)
        {
            BlankNumbers = BlankNeg;
            Caption = 'Scrap %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;

            trigger OnValidate()
            begin
                Validate("Expected Quantity", Quantity * PlanningNeeds);
            end;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code WHERE("Item No." = FIELD("Item No."));

            trigger OnValidate()
            begin
                ReservePlanningComponent.VerifyChange(Rec, xRec);
                CalcFields("Reserved Qty. (Base)");
                TestField("Reserved Qty. (Base)", 0);
                GetUpdateFromSKU;
            end;
        }
        field(25; "Expected Quantity"; Decimal)
        {
            Caption = 'Expected Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                if Item.Get("Item No.") and ("Ref. Order Type" <> "Ref. Order Type"::Assembly) then
                    if Item."Rounding Precision" > 0 then
                        "Expected Quantity" := Round("Expected Quantity", Item."Rounding Precision", '>');
                "Expected Quantity (Base)" := Round("Expected Quantity" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                "Net Quantity (Base)" := "Expected Quantity (Base)" - "Original Expected Qty. (Base)";

                ReservePlanningComponent.VerifyQuantity(Rec, xRec);

                "Cost Amount" := Round("Expected Quantity" * "Unit Cost");
                "Overhead Amount" :=
                  Round(
                    "Expected Quantity" *
                    (("Direct Unit Cost" * "Indirect Cost %" / 100) + "Overhead Rate" * "Qty. per Unit of Measure"));
                "Direct Cost Amount" := Round("Expected Quantity" * "Direct Unit Cost");
            end;
        }
        field(28; "Flushing Method"; Option)
        {
            Caption = 'Flushing Method';
            OptionCaption = 'Manual,Forward,Backward,Pick + Forward,Pick + Backward';
            OptionMembers = Manual,Forward,Backward,"Pick + Forward","Pick + Backward";
        }
        field(30; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location WHERE("Use As In-Transit" = CONST(false));

            trigger OnValidate()
            begin
                ReservePlanningComponent.VerifyChange(Rec, xRec);
                GetUpdateFromSKU;
                GetDefaultBin;
            end;
        }
        field(31; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                Modify;
            end;
        }
        field(32; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                Modify;
            end;
        }
        field(33; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code WHERE("Location Code" = FIELD("Location Code"));

            trigger OnValidate()
            begin
                ReservePlanningComponent.VerifyChange(Rec, xRec);
            end;
        }
        field(35; "Supplied-by Line No."; Integer)
        {
            Caption = 'Supplied-by Line No.';
            TableRelation = "Requisition Line"."Line No." WHERE("Worksheet Template Name" = FIELD("Worksheet Template Name"),
                                                                 "Journal Batch Name" = FIELD("Worksheet Batch Name"),
                                                                 "Line No." = FIELD("Supplied-by Line No."));
        }
        field(36; "Planning Level Code"; Integer)
        {
            Caption = 'Planning Level Code';
            Editable = false;
        }
        field(37; "Ref. Order Status"; Option)
        {
            Caption = 'Ref. Order Status';
            OptionCaption = 'Simulated,Planned,Firm Planned,Released';
            OptionMembers = Simulated,Planned,"Firm Planned",Released;
        }
        field(38; "Ref. Order No."; Code[20])
        {
            Caption = 'Ref. Order No.';
        }
        field(39; "Ref. Order Line No."; Integer)
        {
            Caption = 'Ref. Order Line No.';
        }
        field(40; Length; Decimal)
        {
            Caption = 'Length';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(41; Width; Decimal)
        {
            Caption = 'Width';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(42; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(43; Depth; Decimal)
        {
            Caption = 'Depth';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(44; "Calculation Formula"; Option)
        {
            Caption = 'Calculation Formula';
            OptionCaption = ' ,Length,Length * Width,Length * Width * Depth,Weight';
            OptionMembers = " ",Length,"Length * Width","Length * Width * Depth",Weight;

            trigger OnValidate()
            begin
                case "Calculation Formula" of
                    "Calculation Formula"::" ":
                        Quantity := "Quantity per";
                    "Calculation Formula"::Length:
                        Quantity := Round(Length * "Quantity per", UOMMgt.QtyRndPrecision);
                    "Calculation Formula"::"Length * Width":
                        Quantity := Round(Length * Width * "Quantity per", UOMMgt.QtyRndPrecision);
                    "Calculation Formula"::"Length * Width * Depth":
                        Quantity := Round(Length * Width * Depth * "Quantity per", UOMMgt.QtyRndPrecision);
                    "Calculation Formula"::Weight:
                        Quantity := Round(Weight * "Quantity per", UOMMgt.QtyRndPrecision);
                end;
                OnValidateCalculationFormulaOnAfterSetQuantity(Rec);
                "Quantity (Base)" := Quantity * "Qty. per Unit of Measure";
                Validate("Expected Quantity", Quantity * PlanningNeeds);
            end;
        }
        field(45; "Quantity per"; Decimal)
        {
            Caption = 'Quantity per';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(46; "Ref. Order Type"; Option)
        {
            Caption = 'Ref. Order Type';
            Editable = false;
            OptionCaption = ' ,Purchase,Prod. Order,Transfer,Assembly';
            OptionMembers = " ",Purchase,"Prod. Order",Transfer,Assembly;
        }
        field(50; "Unit Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Unit Cost';

            trigger OnValidate()
            begin
                TestField("Item No.");

                GetItem;
                GetGLSetup;

                if Item."Costing Method" = Item."Costing Method"::Standard then begin
                    if CurrFieldNo = FieldNo("Unit Cost") then
                        Error(
                          Text001,
                          FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");

                    "Unit Cost" :=
                      Round(Item."Unit Cost" * "Qty. per Unit of Measure");
                    "Indirect Cost %" :=
                      Round(Item."Indirect Cost %" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision);
                    "Overhead Rate" := Item."Overhead Rate";
                    "Direct Unit Cost" :=
                      Round(("Unit Cost" - "Overhead Rate" * "Qty. per Unit of Measure") / (1 + "Indirect Cost %" / 100),
                        GLSetup."Unit-Amount Rounding Precision");
                end;

                Validate("Expected Quantity");
            end;
        }
        field(51; "Cost Amount"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Cost Amount';
        }
        field(52; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            var
                CheckDateConflict: Codeunit "Reservation-Check Date Confl.";
            begin
                CheckDateConflict.PlanningComponentCheck(Rec, CurrFieldNo <> 0);
                UpdateDatetime;
            end;
        }
        field(53; "Due Time"; Time)
        {
            Caption = 'Due Time';

            trigger OnValidate()
            begin
                UpdateDatetime;
            end;
        }
        field(55; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            DecimalPlaces = 2 : 5;
        }
        field(56; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Direct Unit Cost" :=
                  Round("Unit Cost" / (1 + "Indirect Cost %" / 100) - "Overhead Rate" * "Qty. per Unit of Measure");
            end;
        }
        field(57; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Indirect Cost %");
            end;
        }
        field(58; "Direct Cost Amount"; Decimal)
        {
            Caption = 'Direct Cost Amount';
            DecimalPlaces = 2 : 2;
        }
        field(59; "Overhead Amount"; Decimal)
        {
            Caption = 'Overhead Amount';
            DecimalPlaces = 2 : 2;
        }
        field(60; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(62; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(63; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = - Sum ("Reservation Entry"."Quantity (Base)" WHERE("Source ID" = FIELD("Worksheet Template Name"),
                                                                            "Source Ref. No." = FIELD("Line No."),
                                                                            "Source Type" = CONST(99000829),
                                                                            "Source Subtype" = CONST("0"),
                                                                            "Source Batch Name" = FIELD("Worksheet Batch Name"),
                                                                            "Source Prod. Order Line" = FIELD("Worksheet Line No."),
                                                                            "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(71; "Reserved Quantity"; Decimal)
        {
            CalcFormula = - Sum ("Reservation Entry".Quantity WHERE("Source ID" = FIELD("Worksheet Template Name"),
                                                                   "Source Ref. No." = FIELD("Line No."),
                                                                   "Source Type" = CONST(99000829),
                                                                   "Source Subtype" = CONST("0"),
                                                                   "Source Batch Name" = FIELD("Worksheet Batch Name"),
                                                                   "Source Prod. Order Line" = FIELD("Worksheet Line No."),
                                                                   "Reservation Status" = CONST(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(73; "Expected Quantity (Base)"; Decimal)
        {
            Caption = 'Expected Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(74; "Original Expected Qty. (Base)"; Decimal)
        {
            BlankZero = true;
            Caption = 'Original Expected Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(75; "Net Quantity (Base)"; Decimal)
        {
            Caption = 'Net Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(76; "Due Date-Time"; DateTime)
        {
            Caption = 'Due Date-Time';

            trigger OnValidate()
            begin
                "Due Date" := DT2Date("Due Date-Time");
                "Due Time" := DT2Time("Due Date-Time");
                Validate("Due Date");
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                ShowDimensions;
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(99000875; Critical; Boolean)
        {
            Caption = 'Critical';
        }
        field(99000915; "Planning Line Origin"; Option)
        {
            Caption = 'Planning Line Origin';
            Editable = false;
            OptionCaption = ' ,Action Message,Planning,Order Planning';
            OptionMembers = " ","Action Message",Planning,"Order Planning";
        }
    }

    keys
    {
        key(Key1; "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Variant Code", "Location Code", "Due Date", "Planning Line Origin")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Expected Quantity (Base)", "Cost Amount";
        }
        key(Key3; "Item No.", "Variant Code", "Location Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Planning Line Origin", "Due Date")
        {
            Enabled = false;
            MaintainSIFTIndex = false;
            MaintainSQLIndex = false;
            SumIndexFields = "Expected Quantity (Base)", "Cost Amount";
        }
        key(Key4; "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Item No.")
        {
            MaintainSQLIndex = false;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        ReservePlanningComponent.DeleteLine(Rec);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
    end;

    trigger OnInsert()
    begin
        ReservePlanningComponent.VerifyQuantity(Rec, xRec);

        ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
        ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");

        GetReqLine;
        "Planning Line Origin" := ReqLine."Planning Line Origin";
        if "Planning Line Origin" <> "Planning Line Origin"::"Order Planning" then
            TestField("Worksheet Template Name");

        "Due Date" := ReqLine."Starting Date";
    end;

    trigger OnModify()
    var
        Item: Record Item;
    begin
        ReservePlanningComponent.VerifyChange(Rec, xRec);

        if "Location Code" <> '' then
            if Item.Get("Item No.") and (Item.Type = Item.Type::"Non-Inventory") then
                Error(LocationCodeMustBeBlankErr);
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'You cannot change %1 when %2 is %3.';
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
        GLSetup: Record "General Ledger Setup";
        ReqLine: Record "Requisition Line";
        Location: Record Location;
        ReservEngineMgt: Codeunit "Reservation Engine Mgt.";
        ReservePlanningComponent: Codeunit "Plng. Component-Reserve";
        UOMMgt: Codeunit "Unit of Measure Management";
        DimMgt: Codeunit DimensionManagement;
        Reservation: Page Reservation;
        GLSetupRead: Boolean;
        LocationCodeMustBeBlankErr: Label 'The Location Code field must be blank for items of type Non-Inventory.';

    procedure Caption(): Text
    var
        ReqWkshName: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
    begin
        if GetFilters = '' then
            exit('');

        if not ReqWkshName.Get("Worksheet Template Name", "Worksheet Batch Name") then
            exit('');

        if not ReqLine.Get("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.") then
            Clear(ReqLine);

        exit(
          StrSubstNo('%1 %2 %3 %4 %5',
            "Worksheet Batch Name", ReqWkshName.Description, ReqLine.Type, ReqLine."No.", ReqLine.Description));
    end;

    local procedure PlanningNeeds(): Decimal
    var
        PlanningRtngLine: Record "Planning Routing Line";
        NeededQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePlanningNeeds(Rec, NeededQty, IsHandled);
        if IsHandled then
            exit(NeededQty);

        GetReqLine;

        "Due Date" := ReqLine."Starting Date";

        PlanningRtngLine.Reset;
        PlanningRtngLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", "Worksheet Batch Name");
        PlanningRtngLine.SetRange("Worksheet Line No.", "Worksheet Line No.");
        if "Routing Link Code" <> '' then
            PlanningRtngLine.SetRange("Routing Link Code", "Routing Link Code");
        if PlanningRtngLine.FindFirst then
            NeededQty :=
              ReqLine.Quantity * (1 + ReqLine."Scrap %" / 100) *
              (1 + PlanningRtngLine."Scrap Factor % (Accumulated)") * (1 + "Scrap %" / 100) +
              PlanningRtngLine."Fixed Scrap Qty. (Accum.)"
        else
            NeededQty :=
              ReqLine.Quantity * (1 + ReqLine."Scrap %" / 100) * (1 + "Scrap %" / 100);

        OnAfterPlanningNeeds(Rec, ReqLine, PlanningRtngLine, NeededQty);
        exit(NeededQty);
    end;

    procedure ShowReservation()
    begin
        TestField("Item No.");
        Clear(Reservation);
        Reservation.SetPlanningComponent(Rec);
        Reservation.RunModal;
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    begin
        TestField("Item No.");
        ReservEngineMgt.InitFilterAndSortingLookupFor(ReservEntry, true);
        ReservePlanningComponent.FilterReservFor(ReservEntry, Rec);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    procedure TransferFromComponent(var ProdOrderComp: Record "Prod. Order Component")
    begin
        "Ref. Order Type" := "Ref. Order Type"::"Prod. Order";
        "Ref. Order Status" := ProdOrderComp.Status;
        "Ref. Order No." := ProdOrderComp."Prod. Order No.";
        "Ref. Order Line No." := ProdOrderComp."Prod. Order Line No.";
        "Line No." := ProdOrderComp."Line No.";
        "Item No." := ProdOrderComp."Item No.";
        Description := ProdOrderComp.Description;
        "Unit of Measure Code" := ProdOrderComp."Unit of Measure Code";
        "Quantity per" := ProdOrderComp."Quantity per";
        Quantity := ProdOrderComp.Quantity;
        Position := ProdOrderComp.Position;
        "Position 2" := ProdOrderComp."Position 2";
        "Position 3" := ProdOrderComp."Position 3";
        "Lead-Time Offset" := ProdOrderComp."Lead-Time Offset";
        "Routing Link Code" := ProdOrderComp."Routing Link Code";
        "Scrap %" := ProdOrderComp."Scrap %";
        "Variant Code" := ProdOrderComp."Variant Code";
        "Expected Quantity" := ProdOrderComp."Expected Quantity";
        "Location Code" := ProdOrderComp."Location Code";
        "Dimension Set ID" := ProdOrderComp."Dimension Set ID";
        "Shortcut Dimension 1 Code" := ProdOrderComp."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := ProdOrderComp."Shortcut Dimension 2 Code";
        "Bin Code" := ProdOrderComp."Bin Code";
        Length := ProdOrderComp.Length;
        Width := ProdOrderComp.Width;
        Weight := ProdOrderComp.Weight;
        Depth := ProdOrderComp.Depth;
        "Calculation Formula" := ProdOrderComp."Calculation Formula";
        "Planning Level Code" := ProdOrderComp."Planning Level Code";
        "Unit Cost" := ProdOrderComp."Unit Cost";
        "Cost Amount" := ProdOrderComp."Cost Amount";
        "Due Date" := ProdOrderComp."Due Date";
        "Direct Unit Cost" := ProdOrderComp."Direct Unit Cost";
        "Indirect Cost %" := ProdOrderComp."Indirect Cost %";
        "Overhead Rate" := ProdOrderComp."Overhead Rate";
        "Direct Cost Amount" := ProdOrderComp."Direct Cost Amount";
        "Overhead Amount" := ProdOrderComp."Overhead Amount";
        "Qty. per Unit of Measure" := ProdOrderComp."Qty. per Unit of Measure";
        "Quantity (Base)" := ProdOrderComp."Quantity (Base)";
        "Expected Quantity (Base)" := ProdOrderComp."Expected Qty. (Base)";
        "Original Expected Qty. (Base)" := ProdOrderComp."Expected Qty. (Base)";
        UpdateDatetime;

        OnAfterTransferFromComponent(Rec, ProdOrderComp);
    end;

    procedure TransferFromAsmLine(var AsmLine: Record "Assembly Line")
    begin
        "Ref. Order Type" := "Ref. Order Type"::Assembly;
        "Ref. Order Status" := AsmLine."Document Type";
        "Ref. Order No." := AsmLine."Document No.";
        "Ref. Order Line No." := AsmLine."Line No.";
        "Line No." := AsmLine."Line No.";
        "Item No." := AsmLine."No.";
        Description := CopyStr(AsmLine.Description, 1, MaxStrLen(Description));
        "Unit of Measure Code" := AsmLine."Unit of Measure Code";
        "Quantity per" := AsmLine."Quantity per";
        Quantity := AsmLine."Quantity per";
        "Lead-Time Offset" := AsmLine."Lead-Time Offset";
        Position := AsmLine.Position;
        "Position 2" := AsmLine."Position 2";
        "Position 3" := AsmLine."Position 3";
        "Variant Code" := AsmLine."Variant Code";
        "Expected Quantity" := AsmLine.Quantity;
        "Location Code" := AsmLine."Location Code";
        "Dimension Set ID" := AsmLine."Dimension Set ID";
        "Shortcut Dimension 1 Code" := AsmLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := AsmLine."Shortcut Dimension 2 Code";
        "Bin Code" := AsmLine."Bin Code";
        "Unit Cost" := AsmLine."Unit Cost";
        "Cost Amount" := AsmLine."Cost Amount";
        "Due Date" := AsmLine."Due Date";
        "Qty. per Unit of Measure" := AsmLine."Qty. per Unit of Measure";
        "Quantity (Base)" := AsmLine."Quantity per";
        "Expected Quantity (Base)" := AsmLine."Quantity (Base)";
        "Original Expected Qty. (Base)" := AsmLine."Quantity (Base)";
        UpdateDatetime;

        OnAfterTransferFromAsmLine(Rec, AsmLine);
    end;

    local procedure GetUpdateFromSKU()
    var
        SKU: Record "Stockkeeping Unit";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
    begin
        GetPlanningParameters.AtSKU(SKU, "Item No.", "Variant Code", "Location Code");
        Validate("Flushing Method", SKU."Flushing Method");
    end;

    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        ReservePlanningComponent.Block(SetBlock);
    end;

    local procedure UpdateDatetime()
    begin
        "Due Date-Time" := CreateDateTime("Due Date", "Due Time");
    end;

    procedure OpenItemTrackingLines()
    begin
        if "Item No." <> '' then
            ReservePlanningComponent.CallItemTracking(Rec);
    end;

    procedure CreateDim(Type1: Integer; No1: Code[20])
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        DimensionSetIDArr: array[10] of Integer;
    begin
        TableID[1] := Type1;
        No[1] := No1;
        OnAfterCreateDimTableIDs(Rec, CurrFieldNo, TableID, No);

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        GetReqLine;
        DimensionSetIDArr[1] :=
          DimMgt.GetRecDefaultDimID(Rec, CurrFieldNo, TableID, No, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);
        DimensionSetIDArr[2] := ReqLine."Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.GetCombinedDimensionSetID(DimensionSetIDArr, "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get;
        GLSetupRead := true;
    end;

    local procedure GetItem()
    begin
        if "Item No." <> Item."No." then
            Item.Get("Item No.");
    end;

    local procedure GetReqLine()
    begin
        if (ReqLine."Worksheet Template Name" = "Worksheet Template Name") and
           (ReqLine."Journal Batch Name" = "Worksheet Batch Name") and
           (ReqLine."Line No." = "Worksheet Line No.")
        then
            exit;

        ReqLine.Get("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure GetDefaultBin()
    begin
        if (Quantity * xRec.Quantity > 0) and
           ("Item No." = xRec."Item No.") and
           ("Location Code" = xRec."Location Code") and
           ("Variant Code" = xRec."Variant Code")
        then
            exit;

        "Bin Code" := '';
        if ("Location Code" <> '') and ("Item No." <> '') then
            Validate("Bin Code", GetToBin);
    end;

    local procedure FindFirstRtngLine(var PlanningRoutingLine: Record "Planning Routing Line"; ReqLine: Record "Requisition Line"): Boolean
    begin
        PlanningRoutingLine.Reset;
        PlanningRoutingLine.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", ReqLine."Line No.");
        PlanningRoutingLine.SetFilter("No.", '<>%1', '');
        PlanningRoutingLine.SetRange("Previous Operation No.", '');
        if "Routing Link Code" <> '' then begin
            PlanningRoutingLine.SetRange("Routing Link Code", "Routing Link Code");
            PlanningRoutingLine.SetRange("Previous Operation No.");
            if PlanningRoutingLine.Count = 0 then begin
                PlanningRoutingLine.SetRange("Routing Link Code");
                PlanningRoutingLine.SetRange("Previous Operation No.", '');
            end;
        end;

        exit(PlanningRoutingLine.FindFirst);
    end;

    local procedure FilterLinesWithItemToPlan(var Item: Record Item)
    begin
        Reset;
        SetCurrentKey("Item No.");
        SetRange("Item No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Due Date", Item.GetFilter("Date Filter"));
        Item.CopyFilter("Global Dimension 1 Filter", "Shortcut Dimension 1 Code");
        Item.CopyFilter("Global Dimension 2 Filter", "Shortcut Dimension 2 Code");
        SetFilter("Quantity (Base)", '<>0');
    end;

    procedure FindLinesWithItemToPlan(var Item: Record Item): Boolean
    begin
        FilterLinesWithItemToPlan(Item);
        exit(Find('-'));
    end;

    procedure FindCurrForecastName(var ForecastName: Code[10]): Boolean
    var
        UntrackedPlngElement: Record "Untracked Planning Element";
    begin
        UntrackedPlngElement.SetRange("Worksheet Template Name", "Worksheet Template Name");
        UntrackedPlngElement.SetRange("Worksheet Batch Name", "Worksheet Batch Name");
        UntrackedPlngElement.SetRange("Item No.", "Item No.");
        UntrackedPlngElement.SetRange("Source Type", DATABASE::"Production Forecast Entry");
        if UntrackedPlngElement.FindFirst then begin
            ForecastName := CopyStr(UntrackedPlngElement."Source ID", 1, 10);
            exit(true);
        end;
    end;

    procedure SetRequisitionLine(RequisitionLine: Record "Requisition Line")
    begin
        ReqLine := RequisitionLine;
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID",
            StrSubstNo(
              '%1 %2 %3', "Worksheet Template Name", "Worksheet Batch Name",
              "Worksheet Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    local procedure GetToBin() BinCode: Code[20]
    begin
        GetLocation("Location Code");
        GetReqLine;
        BinCode := GetRefOrderTypeBin;
        if BinCode <> '' then
            exit;
        exit(GetWMSDefaultBin);
    end;

    local procedure GetRefOrderTypeBin() BinCode: Code[20]
    var
        PlanningRoutingLine: Record "Planning Routing Line";
        WMSManagement: Codeunit "WMS Management";
    begin
        case ReqLine."Ref. Order Type" of
            ReqLine."Ref. Order Type"::"Prod. Order":
                begin
                    if "Location Code" = ReqLine."Location Code" then
                        if FindFirstRtngLine(PlanningRoutingLine, ReqLine) then
                            BinCode := WMSManagement.GetProdCenterBinCode(
                                PlanningRoutingLine.Type, PlanningRoutingLine."No.", "Location Code", true, "Flushing Method");
                    if BinCode <> '' then
                        exit(BinCode);
                    BinCode := GetFlushingMethodBin;
                end;
            ReqLine."Ref. Order Type"::Assembly:
                BinCode := Location."To-Assembly Bin Code";
        end;
    end;

    local procedure GetFlushingMethodBin(): Code[20]
    begin
        case "Flushing Method" of
            "Flushing Method"::Manual,
          "Flushing Method"::"Pick + Forward",
          "Flushing Method"::"Pick + Backward":
                exit(Location."To-Production Bin Code");
            "Flushing Method"::Forward,
          "Flushing Method"::Backward:
                exit(Location."Open Shop Floor Bin Code");
        end;
    end;

    local procedure GetWMSDefaultBin(): Code[20]
    var
        WMSManagement: Codeunit "WMS Management";
        BinCode: Code[20];
    begin
        if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", BinCode);
        exit(BinCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDimTableIDs(var PlanningComponent: Record "Planning Component"; CallingFieldNo: Integer; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPlanningNeeds(PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line"; PlanningRoutingLine: Record "Planning Routing Line"; var NeededQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromComponent(var PlanningComponent: Record "Planning Component"; var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAsmLine(var PlanningComponent: Record "Planning Component"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var PlanningComponent: Record "Planning Component"; var xPlanningComponent: Record "Planning Component"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var PlanningComponent: Record "Planning Component"; var xPlanningComponent: Record "Planning Component"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePlanningNeeds(var PlanningComponent: Record "Planning Component"; var NeededQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCalculationFormulaOnAfterSetQuantity(var PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRoutingLinkCodeOnBeforeValidateDueDate(var PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line")
    begin
    end;
}

