codeunit 130028 "License Management Starter"
{
    // This codeunit is used for reducing table data in the demo database so that it can be used for license testing.


    trigger OnRun()
    begin
        ReduceDemoData;
    end;

    var
        TableClearedSuccessfullyMsg: Label 'Table data was successfully deleted for Starter license test.';

    [Scope('OnPrem')]
    procedure ReduceDemoData()
    var
        ResCapacityEntry: Record "Res. Capacity Entry";
        Job: Record Job;
        JobLedgerEntry: Record "Job Ledger Entry";
#if not CLEAN21
        ResourceCost: Record "Resource Cost";
#endif
        JobPostingGroup: Record "Job Posting Group";
        JobJournalTemplate: Record "Job Journal Template";
        JobJournalLine: Record "Job Journal Line";
        JobPostingBuffer: Record "Job Posting Buffer";
        JobJournalBatch: Record "Job Journal Batch";
        JobRegister: Record "Job Register";
        JobJournalQuantity: Record "Job Journal Quantity";
        ICGLAccount: Record "IC G/L Account";
        ICDimension: Record "IC Dimension";
        ICDimensionValue: Record "IC Dimension Value";
        ICPartner: Record "IC Partner";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
        HandledICOutboxTrans: Record "Handled IC Outbox Trans.";
        HandledICOutboxJnlLine: Record "Handled IC Outbox Jnl. Line";
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICInboxJnlLine: Record "IC Inbox Jnl. Line";
        HandledICInboxTrans: Record "Handled IC Inbox Trans.";
        HandledICInboxJnlLine: Record "Handled IC Inbox Jnl. Line";
        ICInboxOutboxJnlLineDim: Record "IC Inbox/Outbox Jnl. Line Dim.";
        ICCommentLine: Record "IC Comment Line";
        ICOutboxSalesHeader: Record "IC Outbox Sales Header";
        ICOutboxSalesLine: Record "IC Outbox Sales Line";
        ICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
        ICOutboxPurchaseLine: Record "IC Outbox Purchase Line";
        HandledICOutboxSalesHeader: Record "Handled IC Outbox Sales Header";
        HandledICOutboxSalesLine: Record "Handled IC Outbox Sales Line";
        HandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr";
        HandledICOutboxPurchLine: Record "Handled IC Outbox Purch. Line";
        ICInboxSalesHeader: Record "IC Inbox Sales Header";
        ICInboxSalesLine: Record "IC Inbox Sales Line";
        ICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        ICInboxPurchaseLine: Record "IC Inbox Purchase Line";
        HandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header";
        HandledICInboxSalesLine: Record "Handled IC Inbox Sales Line";
        HandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header";
        HandledICInboxPurchLine: Record "Handled IC Inbox Purch. Line";
        ICDocumentDimension: Record "IC Document Dimension";
        JobTask: Record "Job Task";
        JobTaskDimension: Record "Job Task Dimension";
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
        JobWIPWarning: Record "Job WIP Warning";
#if not CLEAN21
        JobResourcePrice: Record "Job Resource Price";
        JobItemPrice: Record "Job Item Price";
        JobGLAccountPrice: Record "Job G/L Account Price";
#endif
        JobEntryNo: Record "Job Entry No.";
        JobBuffer: Record "Job Buffer";
        JobWIPBuffer: Record "Job WIP Buffer";
        JobDifferenceBuffer: Record "Job Difference Buffer";
        JobUsageLink: Record "Job Usage Link";
        JobWIPTotal: Record "Job WIP Total";
        JobPlanningLineInvoice: Record "Job Planning Line Invoice";
        CostJournalTemplate: Record "Cost Journal Template";
        CostJournalLine: Record "Cost Journal Line";
        CostJournalBatch: Record "Cost Journal Batch";
        CostType: Record "Cost Type";
        CostEntry: Record "Cost Entry";
        CostRegister: Record "Cost Register";
        CostAllocationSource: Record "Cost Allocation Source";
        CostAllocationTarget: Record "Cost Allocation Target";
        CostBudgetEntry: Record "Cost Budget Entry";
        CostBudgetName: Record "Cost Budget Name";
        CostBudgetRegister: Record "Cost Budget Register";
        CostCenter: Record "Cost Center";
        CostObject: Record "Cost Object";
        CostBudgetBuffer: Record "Cost Budget Buffer";
        ExchangeFolder: Record "Exchange Folder";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderRoutingTool: Record "Prod. Order Routing Tool";
        ProdOrderRoutingPersonnel: Record "Prod. Order Routing Personnel";
        ProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
        ProdOrderCommentLine: Record "Prod. Order Comment Line";
        ProdOrderRtngCommentLine: Record "Prod. Order Rtng Comment Line";
        ProdOrderCompCmtLine: Record "Prod. Order Comp. Cmt Line";
        PlanningErrorLog: Record "Planning Error Log";
        ResponsibilityCenter: Record "Responsibility Center";
        WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
        StandardCostWorksheetName: Record "Standard Cost Worksheet Name";
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceOrderType: Record "Service Order Type";
        ServiceItemGroup: Record "Service Item Group";
        ServiceCost: Record "Service Cost";
        ServiceCommentLine: Record "Service Comment Line";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
        ServiceShipmentBuffer: Record "Service Shipment Buffer";
        ServiceHour: Record "Service Hour";
        ServiceDocumentLog: Record "Service Document Log";
        Loaner: Record Loaner;
        LoanerEntry: Record "Loaner Entry";
        FaultArea: Record "Fault Area";
        SymptomCode: Record "Symptom Code";
        FaultReasonCode: Record "Fault Reason Code";
        FaultCode: Record "Fault Code";
        ResolutionCode: Record "Resolution Code";
        FaultResolCodRelationship: Record "Fault/Resol. Cod. Relationship";
        FaultAreaSymptomCode: Record "Fault Area/Symptom Code";
        RepairStatus: Record "Repair Status";
        ServiceStatusPrioritySetup: Record "Service Status Priority Setup";
        ServiceShelf: Record "Service Shelf";
        ServiceOrderPostingBuffer: Record "Service Order Posting Buffer";
        ServiceRegister: Record "Service Register";
        ServiceEmailQueue: Record "Service Email Queue";
        ServiceDocumentRegister: Record "Service Document Register";
        ServiceItem: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
        ServiceItemLog: Record "Service Item Log";
        TroubleshootingHeader: Record "Troubleshooting Header";
        TroubleshootingLine: Record "Troubleshooting Line";
        TroubleshootingSetup: Record "Troubleshooting Setup";
        ServiceOrderAllocation: Record "Service Order Allocation";
        ResourceLocation: Record "Resource Location";
        WorkHourTemplate: Record "Work-Hour Template";
        SkillCode: Record "Skill Code";
        ResourceSkill: Record "Resource Skill";
        ServiceZone: Record "Service Zone";
        ResourceServiceZone: Record "Resource Service Zone";
        ServiceContractLine: Record "Service Contract Line";
        ServiceContractHeader: Record "Service Contract Header";
        ContractGroup: Record "Contract Group";
        ContractChangeLog: Record "Contract Change Log";
        ServiceContractTemplate: Record "Service Contract Template";
        ContractGainLossEntry: Record "Contract Gain/Loss Entry";
        FiledServiceContractHeader: Record "Filed Service Contract Header";
        FiledContractLine: Record "Filed Contract Line";
        ContractServiceDiscount: Record "Contract/Service Discount";
        ServiceContractAccountGroup: Record "Service Contract Account Group";
        ServiceShipmentItemLine: Record "Service Shipment Item Line";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        StandardServiceCode: Record "Standard Service Code";
        StandardServiceLine: Record "Standard Service Line";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
        ServicePriceGroup: Record "Service Price Group";
        ServPriceGroupSetup: Record "Serv. Price Group Setup";
        ServicePriceAdjustmentGroup: Record "Service Price Adjustment Group";
        ServPriceAdjustmentDetail: Record "Serv. Price Adjustment Detail";
        ServiceLinePriceAdjmt: Record "Service Line Price Adjmt.";
        CampaignTargetGroup: Record "Campaign Target Group";
        Zone: Record Zone;
        WarehouseClass: Record "Warehouse Class";
        SpecialEquipment: Record "Special Equipment";
        PutAwayTemplateHeader: Record "Put-away Template Header";
        PutAwayTemplateLine: Record "Put-away Template Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        BinTemplate: Record "Bin Template";
        BinCreationWkshTemplate: Record "Bin Creation Wksh. Template";
        BinCreationWkshName: Record "Bin Creation Wksh. Name";
        BinCreationWorksheetLine: Record "Bin Creation Worksheet Line";
        PostedInvtPutAwayHeader: Record "Posted Invt. Put-away Header";
        PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line";
        PhysInvtItemSelection: Record "Phys. Invt. Item Selection";
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        BaseCalendar: Record "Base Calendar";
        BaseCalendarChange: Record "Base Calendar Change";
        CustomizedCalendarChange: Record "Customized Calendar Change";
        CustomizedCalendarEntry: Record "Customized Calendar Entry";
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
        MiniformHeader: Record "Miniform Header";
        MiniformLine: Record "Miniform Line";
        MiniformFunctionGroup: Record "Miniform Function Group";
        MiniformFunction: Record "Miniform Function";
        ItemIdentifier: Record "Item Identifier";
        ADCSUser: Record "ADCS User";
        WorkShift: Record "Work Shift";
        ShopCalendar: Record "Shop Calendar";
        ShopCalendarWorkingDays: Record "Shop Calendar Working Days";
        ShopCalendarHoliday: Record "Shop Calendar Holiday";
        WorkCenter: Record "Work Center";
        WorkCenterGroup: Record "Work Center Group";
        CalendarEntry: Record "Calendar Entry";
        MachineCenter: Record "Machine Center";
        CalendarAbsenceEntry: Record "Calendar Absence Entry";
        Stop: Record Stop;
        Scrap: Record Scrap;
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Family: Record Family;
        FamilyLine: Record "Family Line";
        RoutingCommentLine: Record "Routing Comment Line";
        RoutingLink: Record "Routing Link";
        StandardTask: Record "Standard Task";
        ProductionBOMVersion: Record "Production BOM Version";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        StandardTaskTool: Record "Standard Task Tool";
        StandardTaskPersonnel: Record "Standard Task Personnel";
        StandardTaskDescription: Record "Standard Task Description";
        StandardTaskQualityMeasure: Record "Standard Task Quality Measure";
        QualityMeasure: Record "Quality Measure";
        RoutingVersion: Record "Routing Version";
        ProductionMatrixBOMLine: Record "Production Matrix BOM Line";
        ProductionMatrixBOMEntry: Record "Production Matrix  BOM Entry";
        RoutingTool: Record "Routing Tool";
        RoutingPersonnel: Record "Routing Personnel";
        RoutingQualityMeasure: Record "Routing Quality Measure";
        PlanningRoutingLine: Record "Planning Routing Line";
        PlanningBuffer: Record "Planning Buffer";
        RegisteredAbsence: Record "Registered Absence";
        ProductionForecastName: Record "Production Forecast Name";
        ProductionForecastEntry: Record "Production Forecast Entry";
        CapacityConstrainedResource: Record "Capacity Constrained Resource";
        OrderPromisingLine: Record "Order Promising Line";
        ServiceLine: Record "Service Line";
    begin
        ResCapacityEntry.DeleteAll();
        Job.DeleteAll();
        JobLedgerEntry.DeleteAll();
#if not CLEAN21
        ResourceCost.DeleteAll();
#endif
        JobPostingGroup.DeleteAll();
        JobJournalTemplate.DeleteAll();
        JobJournalLine.DeleteAll();
        JobPostingBuffer.DeleteAll();
        JobJournalBatch.DeleteAll();
        JobRegister.DeleteAll();
        JobJournalQuantity.DeleteAll();
        ICGLAccount.DeleteAll();
        ICDimension.DeleteAll();
        ICDimensionValue.DeleteAll();
        ICPartner.DeleteAll();
        ICOutboxTransaction.DeleteAll();
        ICOutboxJnlLine.DeleteAll();
        HandledICOutboxTrans.DeleteAll();
        HandledICOutboxJnlLine.DeleteAll();
        ICInboxTransaction.DeleteAll();
        ICInboxJnlLine.DeleteAll();
        HandledICInboxTrans.DeleteAll();
        HandledICInboxJnlLine.DeleteAll();
        ICInboxOutboxJnlLineDim.DeleteAll();
        ICCommentLine.DeleteAll();
        ICOutboxSalesHeader.DeleteAll();
        ICOutboxSalesLine.DeleteAll();
        ICOutboxPurchaseHeader.DeleteAll();
        ICOutboxPurchaseLine.DeleteAll();
        HandledICOutboxSalesHeader.DeleteAll();
        HandledICOutboxSalesLine.DeleteAll();
        HandledICOutboxPurchHdr.DeleteAll();
        HandledICOutboxPurchLine.DeleteAll();
        ICInboxSalesHeader.DeleteAll();
        ICInboxSalesLine.DeleteAll();
        ICInboxPurchaseHeader.DeleteAll();
        ICInboxPurchaseLine.DeleteAll();
        HandledICInboxSalesHeader.DeleteAll();
        HandledICInboxSalesLine.DeleteAll();
        HandledICInboxPurchHeader.DeleteAll();
        HandledICInboxPurchLine.DeleteAll();
        ICDocumentDimension.DeleteAll();
        JobTask.DeleteAll();
        JobTaskDimension.DeleteAll();
        JobWIPEntry.DeleteAll();
        JobWIPGLEntry.DeleteAll();
        JobWIPWarning.DeleteAll();
#if not CLEAN21
        JobResourcePrice.DeleteAll();
        JobItemPrice.DeleteAll();
        JobGLAccountPrice.DeleteAll();
#endif
        JobEntryNo.DeleteAll();
        JobBuffer.DeleteAll();
        JobWIPBuffer.DeleteAll();
        JobDifferenceBuffer.DeleteAll();
        JobUsageLink.DeleteAll();
        JobWIPTotal.DeleteAll();
        JobPlanningLineInvoice.DeleteAll();
        CostJournalTemplate.DeleteAll();
        CostJournalLine.DeleteAll();
        CostJournalBatch.DeleteAll();
        CostType.DeleteAll();
        CostEntry.DeleteAll();
        CostRegister.DeleteAll();
        CostAllocationSource.DeleteAll();
        CostAllocationTarget.DeleteAll();
        CostBudgetEntry.DeleteAll();
        CostBudgetName.DeleteAll();
        CostBudgetRegister.DeleteAll();
        CostCenter.DeleteAll();
        CostObject.DeleteAll();
        CostBudgetBuffer.DeleteAll();
        ExchangeFolder.DeleteAll();
        ProdOrderRoutingLine.DeleteAll();
        ProdOrderCapacityNeed.DeleteAll();
        ProdOrderRoutingTool.DeleteAll();
        ProdOrderRoutingPersonnel.DeleteAll();
        ProdOrderRtngQltyMeas.DeleteAll();
        ProdOrderCommentLine.DeleteAll();
        ProdOrderRtngCommentLine.DeleteAll();
        ProdOrderCompCmtLine.DeleteAll();
        PlanningErrorLog.DeleteAll();
        ResponsibilityCenter.DeleteAll();
        WhseCrossDockOpportunity.DeleteAll();
        StandardCostWorksheetName.DeleteAll();
        StandardCostWorksheet.DeleteAll();
        ServiceHeader.DeleteAll();
        ServiceItemLine.DeleteAll();
        ServiceOrderType.DeleteAll();
        ServiceItemGroup.DeleteAll();
        ServiceCost.DeleteAll();
        ServiceCommentLine.DeleteAll();
        ServiceLedgerEntry.DeleteAll();
        WarrantyLedgerEntry.DeleteAll();
        ServiceShipmentBuffer.DeleteAll();
        ServiceHour.DeleteAll();
        ServiceDocumentLog.DeleteAll();
        Loaner.DeleteAll();
        LoanerEntry.DeleteAll();
        FaultArea.DeleteAll();
        SymptomCode.DeleteAll();
        FaultReasonCode.DeleteAll();
        FaultCode.DeleteAll();
        ResolutionCode.DeleteAll();
        FaultResolCodRelationship.DeleteAll();
        FaultAreaSymptomCode.DeleteAll();
        RepairStatus.DeleteAll();
        ServiceStatusPrioritySetup.DeleteAll();
        ServiceShelf.DeleteAll();
        ServiceOrderPostingBuffer.DeleteAll();
        ServiceRegister.DeleteAll();
        ServiceEmailQueue.DeleteAll();
        ServiceDocumentRegister.DeleteAll();
        ServiceItem.DeleteAll();
        ServiceItemComponent.DeleteAll();
        ServiceItemLog.DeleteAll();
        TroubleshootingHeader.DeleteAll();
        TroubleshootingLine.DeleteAll();
        TroubleshootingSetup.DeleteAll();
        ServiceOrderAllocation.DeleteAll();
        ResourceLocation.DeleteAll();
        WorkHourTemplate.DeleteAll();
        SkillCode.DeleteAll();
        ResourceSkill.DeleteAll();
        ServiceZone.DeleteAll();
        ResourceServiceZone.DeleteAll();
        ServiceContractLine.DeleteAll();
        ServiceContractHeader.DeleteAll();
        ContractGroup.DeleteAll();
        ContractChangeLog.DeleteAll();
        ServiceContractTemplate.DeleteAll();
        ContractGainLossEntry.DeleteAll();
        FiledServiceContractHeader.DeleteAll();
        FiledContractLine.DeleteAll();
        ContractServiceDiscount.DeleteAll();
        ServiceContractAccountGroup.DeleteAll();
        ServiceShipmentItemLine.DeleteAll();
        ServiceShipmentHeader.DeleteAll();
        ServiceShipmentLine.DeleteAll();
        ServiceInvoiceHeader.DeleteAll();
        ServiceInvoiceLine.DeleteAll();
        ServiceCrMemoHeader.DeleteAll();
        ServiceCrMemoLine.DeleteAll();
        StandardServiceCode.DeleteAll();
        StandardServiceLine.DeleteAll();
        StandardServiceItemGrCode.DeleteAll();
        ServicePriceGroup.DeleteAll();
        ServPriceGroupSetup.DeleteAll();
        ServicePriceAdjustmentGroup.DeleteAll();
        ServPriceAdjustmentDetail.DeleteAll();
        ServiceLinePriceAdjmt.DeleteAll();
        CampaignTargetGroup.DeleteAll();
        Zone.DeleteAll();
        WarehouseClass.DeleteAll();
        SpecialEquipment.DeleteAll();
        PutAwayTemplateHeader.DeleteAll();
        PutAwayTemplateLine.DeleteAll();
        WarehouseReceiptHeader.DeleteAll();
        WarehouseReceiptLine.DeleteAll();
        PostedWhseReceiptHeader.DeleteAll();
        PostedWhseReceiptLine.DeleteAll();
        WarehouseShipmentHeader.DeleteAll();
        WarehouseShipmentLine.DeleteAll();
        PostedWhseShipmentHeader.DeleteAll();
        PostedWhseShipmentLine.DeleteAll();
        WhseInternalPutAwayHeader.DeleteAll();
        WhseInternalPutAwayLine.DeleteAll();
        WhseInternalPickHeader.DeleteAll();
        WhseInternalPickLine.DeleteAll();
        BinTemplate.DeleteAll();
        BinCreationWkshTemplate.DeleteAll();
        BinCreationWkshName.DeleteAll();
        BinCreationWorksheetLine.DeleteAll();
        PostedInvtPutAwayHeader.DeleteAll();
        PostedInvtPutAwayLine.DeleteAll();
        PhysInvtItemSelection.DeleteAll();
        PhysInvtCountingPeriod.DeleteAll();
        BaseCalendar.DeleteAll();
        BaseCalendarChange.DeleteAll();
        CustomizedCalendarChange.DeleteAll();
        CustomizedCalendarEntry.DeleteAll();
        WhereUsedBaseCalendar.DeleteAll();
        MiniformHeader.DeleteAll();
        MiniformLine.DeleteAll();
        MiniformFunctionGroup.DeleteAll();
        MiniformFunction.DeleteAll();
        ItemIdentifier.DeleteAll();
        ADCSUser.DeleteAll();
        WorkShift.DeleteAll();
        ShopCalendar.DeleteAll();
        ShopCalendarWorkingDays.DeleteAll();
        ShopCalendarHoliday.DeleteAll();
        WorkCenter.DeleteAll();
        WorkCenterGroup.DeleteAll();
        CalendarEntry.DeleteAll();
        MachineCenter.DeleteAll();
        CalendarAbsenceEntry.DeleteAll();
        Stop.DeleteAll();
        Scrap.DeleteAll();
        RoutingHeader.DeleteAll();
        RoutingLine.DeleteAll();
        Family.DeleteAll();
        FamilyLine.DeleteAll();
        RoutingCommentLine.DeleteAll();
        RoutingLink.DeleteAll();
        StandardTask.DeleteAll();
        ProductionBOMVersion.DeleteAll();
        CapacityUnitOfMeasure.DeleteAll();
        StandardTaskTool.DeleteAll();
        StandardTaskPersonnel.DeleteAll();
        StandardTaskDescription.DeleteAll();
        StandardTaskQualityMeasure.DeleteAll();
        QualityMeasure.DeleteAll();
        RoutingVersion.DeleteAll();
        ProductionMatrixBOMLine.DeleteAll();
        ProductionMatrixBOMEntry.DeleteAll();
        RoutingTool.DeleteAll();
        RoutingPersonnel.DeleteAll();
        RoutingQualityMeasure.DeleteAll();
        PlanningRoutingLine.DeleteAll();
        PlanningBuffer.DeleteAll();
        RegisteredAbsence.DeleteAll();
        ProductionForecastName.DeleteAll();
        ProductionForecastEntry.DeleteAll();
        CapacityConstrainedResource.DeleteAll();
        OrderPromisingLine.DeleteAll();
        ServiceLine.DeleteAll(); // Included in Starter Pack, but not deleting causes data inconsistency
        Message(TableClearedSuccessfullyMsg);
    end;
}

