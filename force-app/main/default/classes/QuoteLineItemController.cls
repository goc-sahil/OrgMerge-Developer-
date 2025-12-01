public with sharing class QuoteLineItemController {
    @AuraEnabled(cacheable=false)
    public static List<QuoteLineItem> getQuoteLineItems(String quoteId) {
        // Query to get QuoteLineItem details
        List<QuoteLineItem> quoteLineItems = [
            SELECT Id,Product2Id, Product2.Name, Product2.ProductCode ,ListPrice, UnitPrice, Quantity, Discount,SortOrder, 
            Product2.Description,Product_Description__c, Product_Name__c,CurrencyIsoCode ,Product2.Family,PricebookEntryId,Is_Cloned__c
            FROM QuoteLineItem 
            WHERE QuoteId = :quoteId ORDER BY SortOrder ASC
        ];
        return quoteLineItems;
    }

    @AuraEnabled
    public static void updateQuoteLineItems(List<QuoteLineItem> quoteLineItems) {
        // Check if the list is not empty
        // System.debug('QuotelineItem'+quoteLineItems);
        if (quoteLineItems != null && !quoteLineItems.isEmpty()) {
            try {
                // System.debug('QuotelineItem'+quoteLineItems);
                // Update the QuoteLineItem records
                update quoteLineItems;
            } catch (DmlException e) {
                // Handle the DML exception
                throw new AuraHandledException('Error updating QuoteLineItems: ' + e.getMessage());
            }
        }
    }

    @AuraEnabled
    public static void deleteQuoteLineItem(Id quoteLineItemId) {
        try {
            // Check if the provided Id is valid and the record exists
            QuoteLineItem qli = [SELECT Id, Quote.Status FROM QuoteLineItem WHERE Id = :quoteLineItemId LIMIT 1];
            
            // Check the status of the related Quote
            if (qli.Quote.Status != 'Draft') {
                throw new AuraHandledException('You cannot delete line items when the quote status is not Draft.');
            }
            
            // Perform the delete operation
            delete qli;
        } catch (DmlException e) {
            // Handle any exceptions that occur during the deletion
            throw new AuraHandledException('Failed to delete Quote Line Item: ' + e.getMessage());
        } catch (QueryException e) {
            // Handle case where the ID provided does not match any Quote Line Item
            throw new AuraHandledException('Quote Line Item not found: ' + e.getMessage());
        }
    }

    /*@AuraEnabled
    public static void deleteQuoteLineItems(List<Id> quoteLineItemIds) {
        try {
            // Check if the provided Id is valid and the record exists
            List<QuoteLineItem> qli = [SELECT Id, Quote.Status FROM QuoteLineItem WHERE Id = :quoteLineItemIds];
            
            // Check the status of the related Quote
            // if (qli.Quote.Status != 'Draft') {
            //     throw new AuraHandledException('You cannot delete line items when the quote status is not Draft.');
            // }
            
            // Perform the delete operation
            delete qli;
        } catch (DmlException e) {
            // Handle any exceptions that occur during the deletion
            throw new AuraHandledException('Failed to delete Quote Line Item: ' + e.getMessage());
        } catch (QueryException e) {
            // Handle case where the ID provided does not match any Quote Line Item
            throw new AuraHandledException('Quote Line Item not found: ' + e.getMessage());
        }
    }*/

   /* @AuraEnabled
    public static List<QuoteLineItem> getEditQuoteLineItems(String quoteId) {
        return [SELECT Id, QuoteId, Product2Id, Product2.Name, Product_Name__c, Product2.ProductCode, 
                UnitPrice, Quantity, Discount, Product_Description__c, CurrencyIsoCode, PricebookEntryId, 
                Product2.Description, Product2.Family, Order__c 
                FROM QuoteLineItem 
                WHERE QuoteId = :quoteId];
    }*/

    /*@AuraEnabled
    public static void upsertQuoteLineItems(List<QuoteLineItem> quoteLineItems) {
        try {
            upsert quoteLineItems;
        } catch (Exception e) {
            throw new AuraHandledException('Error upserting Quote Line Items: ' + e.getMessage());
        }
    }*/

    /*@AuraEnabled
public static void upsertAndDeleteQuoteLineItems(List<QuoteLineItem> quoteLineItemsToUpsert, List<String> quoteLineItemIdsToDelete) {
    try {
        // Perform deletes first
        if (quoteLineItemIdsToDelete != null && !quoteLineItemIdsToDelete.isEmpty()) {
            List<QuoteLineItem> itemsToDelete = [SELECT Id FROM QuoteLineItem WHERE Id IN :quoteLineItemIdsToDelete];
            if (!itemsToDelete.isEmpty()) {
                delete itemsToDelete;
            }
        }

        // Perform upserts
        if (quoteLineItemsToUpsert != null && !quoteLineItemsToUpsert.isEmpty()) {
            upsert quoteLineItemsToUpsert;
        }
    } catch (Exception e) {
        throw new AuraHandledException('Error processing quote line items: ' + e.getMessage());
    }
}*/
}