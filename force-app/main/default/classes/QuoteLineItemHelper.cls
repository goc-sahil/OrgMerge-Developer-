public with sharing class QuoteLineItemHelper {
    public static void updateQuoteTotals(Set<Id> quoteIds) {
        List<Quote> quotesToUpdate = new List<Quote>();
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
        }
    }

    /**
     * Updates Aggregated_Total_Price__c for QuoteLineItems based on parent-child relationships
     * - Parent items: Parent's NetTotalPrice + Sum of all children's NetTotalPrice
     * - Child items: Set to 0
     * 
     * Example: If Parent A has NetTotalPrice = 50 with children (10, 10, 30), 
     *          then Aggregated_Total_Price__c = 50 + 10 + 10 + 30 = 100
     */
    public static void updateAggregatedTotalPrice(Set<Id> quoteLineItemIds) {
        if (quoteLineItemIds == null || quoteLineItemIds.isEmpty()) {
            return;
        }

        Set<Id> allAffectedIds = new Set<Id>();
        Id quoteId = null;
        
        Map<Id, QuoteLineItem> affectedQLIs = new Map<Id, QuoteLineItem>([
            SELECT Id, QuoteId, ParentQuoteLineItemId, NetTotalPrice
            FROM QuoteLineItem
            WHERE Id IN :quoteLineItemIds
        ]);

        for (QuoteLineItem qli : affectedQLIs.values()) {
            allAffectedIds.add(qli.Id);
            if (qli.QuoteId != null && quoteId == null) {
                quoteId = qli.QuoteId;
            }
            if (qli.ParentQuoteLineItemId != null) {
                allAffectedIds.add(qli.ParentQuoteLineItemId);
            }
        }

        if (quoteId == null) {
            return;
        }

        if (!allAffectedIds.isEmpty()) {
            for (QuoteLineItem childQLI : [
                SELECT Id, QuoteId, ParentQuoteLineItemId
                FROM QuoteLineItem
                WHERE ParentQuoteLineItemId IN :allAffectedIds
                AND QuoteId = :quoteId
            ]) {
                allAffectedIds.add(childQLI.Id);
                if (childQLI.ParentQuoteLineItemId != null) {
                    allAffectedIds.add(childQLI.ParentQuoteLineItemId);
                }
            }
        }

        Map<Id, QuoteLineItem> allQLIsMap = new Map<Id, QuoteLineItem>([
            SELECT Id, QuoteId, ParentQuoteLineItemId, NetTotalPrice, Aggregated_Total_Price__c
            FROM QuoteLineItem
            WHERE Id IN :allAffectedIds
        ]);

        Set<Id> parentIds = new Set<Id>();
        Map<Id, List<QuoteLineItem>> parentToChildrenMap = new Map<Id, List<QuoteLineItem>>();

        for (QuoteLineItem qli : allQLIsMap.values()) {
            if (qli.ParentQuoteLineItemId == null) {
                parentIds.add(qli.Id);
                if (!parentToChildrenMap.containsKey(qli.Id)) {
                    parentToChildrenMap.put(qli.Id, new List<QuoteLineItem>());
                }
            }
        }

        if (!parentIds.isEmpty() && quoteId != null) {
            for (QuoteLineItem childQLI : [
                SELECT Id, QuoteId, ParentQuoteLineItemId, NetTotalPrice
                FROM QuoteLineItem
                WHERE ParentQuoteLineItemId IN :parentIds
                AND QuoteId = :quoteId
            ]) {
                if (!parentToChildrenMap.containsKey(childQLI.ParentQuoteLineItemId)) {
                    parentToChildrenMap.put(childQLI.ParentQuoteLineItemId, new List<QuoteLineItem>());
                }
                parentToChildrenMap.get(childQLI.ParentQuoteLineItemId).add(childQLI);
            }
        }

        List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();

        for (Id parentId : parentIds) {
            QuoteLineItem parentQLI = allQLIsMap.get(parentId);
            
            Decimal aggregatedTotal = (parentQLI != null && parentQLI.NetTotalPrice != null) 
                                        ? parentQLI.NetTotalPrice 
                                        : 0;
            
            if (parentToChildrenMap.containsKey(parentId)) {
                for (QuoteLineItem child : parentToChildrenMap.get(parentId)) {
                    aggregatedTotal += (child.NetTotalPrice != null ? child.NetTotalPrice : 0);
                }
            }

            if (parentQLI != null && parentQLI.Aggregated_Total_Price__c != aggregatedTotal) {
                qlisToUpdate.add(new QuoteLineItem(
                    Id = parentId,
                    Aggregated_Total_Price__c = aggregatedTotal
                ));
            }
        }

        for (QuoteLineItem qli : allQLIsMap.values()) {
            if (qli.ParentQuoteLineItemId != null && qli.Aggregated_Total_Price__c != 0) {
                qlisToUpdate.add(new QuoteLineItem(
                    Id = qli.Id,
                    Aggregated_Total_Price__c = 0
                ));
            }
        }

        if (!qlisToUpdate.isEmpty()) {
            update qlisToUpdate;
            System.enqueueJob(new CalloutPricingProcedure(quoteId));
        }
    }
}