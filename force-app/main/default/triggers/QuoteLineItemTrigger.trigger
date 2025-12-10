trigger QuoteLineItemTrigger on QuoteLineItem (before insert, after insert, after update, after delete, after undelete) {
    Set<Id> quoteIds = new Set<Id>();
    Set<Id> quoteLineItemIds = new Set<Id>();
    
    if (Trigger.isBefore && Trigger.isInsert) {
        system.debug('in the trigger');
        QuoteLineItemTriggerHandler.setSubscriptionTerm(Trigger.new);
    }
    
    // Collect Quote IDs for quote total updates
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (QuoteLineItem qli : Trigger.new) {
            if (qli.QuoteId != null) {
                quoteIds.add(qli.QuoteId);
            }
            // Collect QuoteLineItem IDs for aggregated total price updates
            quoteLineItemIds.add(qli.Id);
        }
    }

    if (Trigger.isUpdate || Trigger.isDelete) {
        for (QuoteLineItem qli : Trigger.old) {
            if (qli.QuoteId != null) {
                quoteIds.add(qli.QuoteId);
            }
            // Collect QuoteLineItem IDs for aggregated total price updates
            quoteLineItemIds.add(qli.Id);
        }
    }

    // Update Quote totals (existing functionality)
    if (!quoteIds.isEmpty()) {
        QuoteLineItemHelper.updateQuoteTotals(quoteIds);
    }
    
    // Update Aggregated Total Price for parent-child QuoteLineItems
    if (!quoteLineItemIds.isEmpty()) {
        //QuoteLineItemHelper.updateAggregatedTotalPrice(quoteLineItemIds);
    }
}