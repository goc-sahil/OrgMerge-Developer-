public with sharing class QuoteLineItemSorter {
    // Simple wrapper for update request coming from LWC
    public class QLIUpdate {
        @AuraEnabled public Id id {get; set;}
        @AuraEnabled public Integer sortOrder {get; set;}
    }

    @AuraEnabled(cacheable=true)
    public static List<QuoteLineItem> getQuoteLineItems(Id quoteId) {
        if (quoteId == null) {
            throw new AuraHandledException('Missing quoteId');
        }

        // Basic CRUD check
        if (!Schema.sObjectType.QuoteLineItem.isAccessible()) {
            throw new AuraHandledException('Insufficient access to QuoteLineItem.');
        }

        // Query by QuoteId only (required)
        List<QuoteLineItem> qlis = [
            SELECT Id,
                   Product_Name__c,
                   UnitPrice,
                   SortOrder,
                   CurrencyIsoCode,
                   ParentQuoteLineItemId
            FROM QuoteLineItem
            WHERE QuoteId = :quoteId
            ORDER BY SortOrder ASC NULLS LAST
        ];

        return qlis;
    }

    @AuraEnabled
    public static List<Id> updateSortOrders(List<QLIUpdate> updates) {

        System.debug('Updates received: ' + updates);
        if (updates == null || updates.isEmpty()) {
            throw new AuraHandledException('No updates provided.');
        }

        // CRUD check
        if (!Schema.sObjectType.QuoteLineItem.isUpdateable()) {
            throw new AuraHandledException('User does not have update permission on QuoteLineItem.');
        }

        // Convert to sObjects
        List<QuoteLineItem> toUpdate = new List<QuoteLineItem>();
         Id quoteId = null;
        for (QLIUpdate u : updates) {
            if (u == null || u.id == null) continue;  // Changed to lowercase
            QuoteLineItem qli = new QuoteLineItem(Id = u.id);  // Changed to lowercase
            qli.SortOrder = u.sortOrder;  // Changed to lowercase
            toUpdate.add(qli);
        }

        if (toUpdate.isEmpty()) {
            throw new AuraHandledException('No valid records to update.');
        }

        try {
            update toUpdate;
            
            if (!toUpdate.isEmpty()) {
            QuoteLineItem qli = [SELECT QuoteId FROM QuoteLineItem WHERE Id = :toUpdate[0].Id LIMIT 1];
            quoteId = qli.QuoteId;
            System.debug('Quote Id retrieved: ' + quoteId);
            }
            
            // Enqueue the pricing procedure callout
            if (quoteId != null) {
                System.debug('Enqueuing CalloutPricingProcedure for Quote: ' + quoteId);
                System.enqueueJob(new CalloutPricingProcedure(quoteId));
            }
            
            // Return updated Ids for UI refresh
            List<Id> ids = new List<Id>();
            for (QuoteLineItem q : toUpdate) ids.add(q.Id);
            return ids;
        } catch (DmlException e) {
            throw new AuraHandledException('Failed to update SortOrder: ' + e.getMessage());
        }
    }
}
