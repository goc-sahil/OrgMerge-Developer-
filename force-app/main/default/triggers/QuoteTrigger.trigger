trigger QuoteTrigger on Quote (before insert, before update, after insert, after update) {
    
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            QuoteNumberGenerator.generateQuoteNumbers(Trigger.new);
            // QuoteApprovalHelper.evaluateApproval(Trigger.new);
        }

        if (Trigger.isUpdate) {
            QuotePDFVersionHandler.handlePDFVersioning(Trigger.new, Trigger.oldMap);
           
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate && !QuoteTriggerHandler.hasRun) {
        QuoteTriggerHandler.hasRun = true;
        QuoteTriggerHandler.evaluateApproval(Trigger.oldMap, Trigger.new);
    }
}