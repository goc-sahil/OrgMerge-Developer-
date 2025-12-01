public with sharing class QuoteLineItemHelper {
    public static void updateQuoteTotals(Set<Id> quoteIds) {
        List<Quote> quotesToUpdate = new List<Quote>();

        // Get all relevant QuoteLineItems with required fields
        Map<Id, List<QuoteLineItem>> quoteLineItemsMap = new Map<Id, List<QuoteLineItem>>();

        for (QuoteLineItem qli : [
            SELECT QuoteId, Discount__c, Margin__c 
            FROM QuoteLineItem 
            WHERE QuoteId IN :quoteIds
        ]) {
            if (!quoteLineItemsMap.containsKey(qli.QuoteId)) {
                quoteLineItemsMap.put(qli.QuoteId, new List<QuoteLineItem>());
            }
            quoteLineItemsMap.get(qli.QuoteId).add(qli);
        }

        for (Id quoteId : quoteLineItemsMap.keySet()) {
            Decimal totalDiscount = 0;
            Decimal totalMargin = 0;

            for (QuoteLineItem qli : quoteLineItemsMap.get(quoteId)) {
                totalDiscount += (qli.Discount__c != null ? qli.Discount__c : 0);
                totalMargin   += (qli.Margin__c != null ? qli.Margin__c : 0);
            }

            // Round to 2 decimal places explicitly
            totalDiscount = totalDiscount.setScale(2, RoundingMode.HALF_UP);
            totalMargin   = totalMargin.setScale(2, RoundingMode.HALF_UP);

            quotesToUpdate.add(new Quote(
                Id = quoteId,
                Total_Discounts__c = totalDiscount,
                Quote_Margin__c = totalMargin
            ));
        }


        if (!quotesToUpdate.isEmpty()) {
            update quotesToUpdate;
            System.debug('Updating Quotes: ' + quotesToUpdate);
        }
    }
}