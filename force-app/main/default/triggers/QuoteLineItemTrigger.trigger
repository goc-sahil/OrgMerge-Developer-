trigger QuoteLineItemTrigger on QuoteLineItem (before insert,after insert, after update, after delete, after undelete) {
    Set<Id> quoteIds = new Set<Id>();
	if (Trigger.isBefore && Trigger.isInsert) {
        system.debug('in the trigger');
        QuoteLineItemTriggerHandler.setSubscriptionTerm(Trigger.new);
    }
    if (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete) {
        for (QuoteLineItem qli : Trigger.new) {
            if (qli.QuoteId != null) {
                quoteIds.add(qli.QuoteId);
            }
        }
    }

    if (Trigger.isUpdate || Trigger.isDelete) {
        for (QuoteLineItem qli : Trigger.old) {
            if (qli.QuoteId != null) {
                quoteIds.add(qli.QuoteId);
            }
        }
    }

    if (!quoteIds.isEmpty()) {
        QuoteLineItemHelper.updateQuoteTotals(quoteIds);
    }
}