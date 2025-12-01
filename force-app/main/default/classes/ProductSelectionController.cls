/**
 * Controller for the Product Selection LWC component
 */
public with sharing class ProductSelectionController {
        
    @AuraEnabled(cacheable=false)
    public static List<OpportunityLineItem> getAllOpportunityLineItems(String opportunityId) {
        try {
            List<OpportunityLineItem> lineItems = [
                SELECT Id, Product2Id, UnitPrice, Quantity, ListPrice,
                       Product2.Name, Product2.ProductCode, Product2.Description, Product2.Family, CurrencyIsoCode,PricebookEntryId
                FROM OpportunityLineItem 
                WHERE OpportunityId = :opportunityId
                ORDER BY CreatedDate DESC
            ];
            // Debug the results
            // System.debug('OpportunityLineItems: ' + JSON.serialize(lineItems));
            for (OpportunityLineItem item : lineItems) {
                // System.debug('Item ID: ' + item.Id + ', Quantity: ' + item.Quantity);
            }
            return lineItems;
        } catch(Exception e) {
            // System.debug('Error in getAllOpportunityLineItems: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }
    /**
     * Retrieves Opportunity Line Items for a given Opportunity
     * @param opportunityId The Id of the Opportunity
     * @param limitSize The number of records to return
     * @param offset The offset for pagination
     * @return List of OpportunityLineItem records with Product2 relationship
     */
    @AuraEnabled(cacheable=true)
public static List<OpportunityLineItem> getOpportunityLineItems(Id opportunityId, Integer limitSize, Integer offset) {
    // Security check
    if (!Schema.sObjectType.OpportunityLineItem.isAccessible() || 
        !Schema.sObjectType.Product2.isAccessible()) {
        throw new AuraHandledException('Insufficient access rights');
    }
    
    try {
        return [
            SELECT Id, UnitPrice, ListPrice, Product2Id, Product2.Name, Product2.ProductCode, Quantity,
                   Product2.Description, Product2.Family, PricebookEntryId, CurrencyIsoCode
            FROM OpportunityLineItem 
            WHERE OpportunityId = :opportunityId 
            WITH SECURITY_ENFORCED
            ORDER BY Product2.Name ASC
            LIMIT :limitSize
            OFFSET :offset
        ];
    } catch (Exception e) {
        throw new AuraHandledException('Error fetching Opportunity Line Items: ' + e.getMessage());
    }
}
    
    /**
     * Retrieves Products from a specific Pricebook
     * @param pricebookId The Id of the Pricebook
     * @return List of PricebookEntry records with Product2 relationship
     */
    @AuraEnabled(cacheable=true)
public static List<PricebookEntry> getProductsFromPricebook(Id pricebookId, Integer limitSize, Integer offset, String CurrencyIsoCode) {
    // Security check
    if (!Schema.sObjectType.PricebookEntry.isAccessible() || 
        !Schema.sObjectType.Product2.isAccessible()) {
        throw new AuraHandledException('Insufficient access rights');
    }
    
    try {
        return [
            SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.ProductCode, 
                   Product2.Description, Product2.Family, CurrencyIsoCode
            FROM PricebookEntry 
            WHERE Pricebook2Id = :pricebookId AND IsActive = true AND CurrencyIsoCode = :CurrencyIsoCode
            WITH SECURITY_ENFORCED
            ORDER BY Product2.Name ASC
            LIMIT :limitSize
            OFFSET :offset
        ];
    } catch (Exception e) {
        throw new AuraHandledException('Error fetching Pricebook products: ' + e.getMessage());
    }
}
    @AuraEnabled
public static void createQuoteLineItems(List<QuoteLineItem> quoteLineItems, String pricebook2Id) {
    try {
        // System.debug('quoteLineItems==>' + JSON.serialize(quoteLineItems));
        // Validate input
        if (quoteLineItems == null || quoteLineItems.isEmpty()) {
            throw new AuraHandledException('No quote line items provided.');
        }
        if (String.isBlank(pricebook2Id)) {
            throw new AuraHandledException('Pricebook2Id is required.');
        }

        // Validate QuoteId and Quote Name
        String quoteId = quoteLineItems[0].QuoteId;
        if (String.isBlank(quoteId)) {
            throw new AuraHandledException('QuoteId is missing in quote line items.');
        }

        List<Quote> quotes = [SELECT Id, Name, Pricebook2Id,CurrencyIsoCode FROM Quote WHERE Id = :quoteId LIMIT 1];
        if (quotes.isEmpty()) {
            throw new AuraHandledException('Invalid QuoteId: Quote not found.');
        }
        if (String.isBlank(quotes[0].Name)) {
            throw new AuraHandledException('Quote is missing a Name.');
        }
        if (quotes[0].Pricebook2Id != pricebook2Id) {
            throw new AuraHandledException('Pricebook2Id does not match the Quote\'s Pricebook2Id.');
        }

        // Collect Product2Ids to fetch PricebookEntries
        Set<Id> product2Ids = new Set<Id>();
        for (QuoteLineItem qli : quoteLineItems) {
            if (qli.Product2Id != null) {
                product2Ids.add(qli.Product2Id);
            } else {
                throw new AuraHandledException('Product2Id is missing for a QuoteLineItem.');
            }
        }

        // Fetch PricebookEntries with UnitPrice
        Map<Id, PricebookEntry> productToPricebookEntry = new Map<Id, PricebookEntry>();
        for (PricebookEntry pbe : [
            SELECT Id, Product2Id, UnitPrice 
            FROM PricebookEntry 
            WHERE Product2Id IN :product2Ids AND Pricebook2Id = :pricebook2Id AND IsActive = true AND CurrencyIsoCode = :quotes[0].CurrencyIsoCode
        ]) {
            productToPricebookEntry.put(pbe.Product2Id, pbe);
        }

        // Assign PricebookEntryId, set SortOrder, and validate
        for (QuoteLineItem qli : quoteLineItems) {
            PricebookEntry pbe = productToPricebookEntry.get(qli.Product2Id);
            if (pbe == null) {
                throw new AuraHandledException('No active PricebookEntry found for Product2Id: ' + qli.Product2Id);
            }
            qli.PricebookEntryId = pbe.Id;

            // Set SortOrder from Order__c
            if (qli.Order__c != null) {
                qli.SortOrder = Integer.valueOf(qli.Order__c); // Assuming Order__c is a number field
            } else {
                throw new AuraHandledException('Order__c is missing for Product2Id: ' + qli.Product2Id);
            }
            // Set Is_Cloned__c (default to false if not provided)
            //qli.Is_Cloned__c = qli.Is_Cloned__c != null ? qli.Is_Cloned__c : false;

            // Log UnitPrice comparison for debugging
            // System.debug('Product2Id: ' + qli.Product2Id);
            // System.debug('PricebookEntry UnitPrice: ' + pbe.UnitPrice);
            // System.debug('QuoteLineItem UnitPrice: ' + qli.UnitPrice);
            // if (qli.UnitPrice != pbe.UnitPrice) {
            //     System.debug('WARNING: UnitPrice mismatch for Product2Id ' + qli.Product2Id + 
            //                  '. PricebookEntry: ' + pbe.UnitPrice + 
            //                  ', QuoteLineItem: ' + qli.UnitPrice);
            // }

            // Validate required fields
            if (qli.Quantity == null || qli.Quantity <= 0) {
                throw new AuraHandledException('Invalid Quantity for Product2Id: ' + qli.Product2Id);
            }
            if (qli.UnitPrice == null) {
                throw new AuraHandledException('UnitPrice is missing for Product2Id: ' + qli.Product2Id);
            }
            if (qli.Order__c == null || qli.Order__c <= 0) {
                throw new AuraHandledException('Invalid Order__c value for Product2Id: ' + qli.Product2Id);
            }
        }

        // Insert QuoteLineItems
        insert quoteLineItems;

        // Log success
        // System.debug('Successfully inserted ' + quoteLineItems.size() + ' QuoteLineItems for QuoteId: ' + quoteId);
    } catch (Exception e) {
        // Log the full error for debugging
        // System.debug('Error creating quote line items: ' + e.getMessage() + '\n' + e.getStackTraceString());
        throw new AuraHandledException('Error creating quote line items: ' + e.getMessage());
    }
}
}