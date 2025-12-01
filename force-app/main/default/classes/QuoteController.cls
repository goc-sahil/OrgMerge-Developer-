/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-19-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class QuoteController {

    @AuraEnabled(cacheable=true)
public static Map<Id, PricebookEntry> getPricebookEntriesForProducts(Id pricebookId, List<Id> productIds, String currencyIsoCode) {
    return new Map<Id, PricebookEntry>([
        SELECT Id, Product2Id, UnitPrice, CurrencyIsoCode 
        FROM PricebookEntry 
        WHERE Pricebook2Id = :pricebookId 
        AND Product2Id IN :productIds 
        AND CurrencyIsoCode = :currencyIsoCode 
        AND IsActive = true
    ]);
}

    @AuraEnabled(cacheable=false)
 public static Opportunity getOpportunityDetails(Id opportunityId) {
     try {
         Opportunity opp = [
             SELECT Id, Name, AccountId,
                    Account.Name,End_Customer__c,End_Customer__r.Name,
                    Account.ShippingStreet, Account.ShippingCity, Account.ShippingState,
                    Account.ShippingPostalCode, Account.ShippingCountry,
                    Pricebook2.Id, Pricebook2.Name,CurrencyIsoCode 
             FROM Opportunity
             WHERE Id = :opportunityId
             LIMIT 1
         ];
         return opp;
     } catch (Exception e) {
         throw new AuraHandledException('Error retrieving Opportunity: ' + e.getMessage());
     }
 }
 
    @AuraEnabled(cacheable=false)
 public static Account getAccountDetails(Id accountId) {
     try {
         Account acc = [
             SELECT Id, Name,ShippingStreet,ShippingCity, ShippingState,
                    ShippingPostalCode,ShippingCountry,BillingCity,BillingCountry,
                    BillingState,BillingStreet,BillingPostalCode,Price_Book__c,Price_Book__r.Name
             FROM Account
             WHERE Id = :accountId
             LIMIT 1
         ];
         return acc;
     } catch (Exception e) {
         throw new AuraHandledException('Error retrieving Account details: ' + e.getMessage());
     }
 }
     @AuraEnabled(cacheable=false)
     public static Quote getQuoteById(String quoteId) {
         try {
             return [
                 SELECT Id, Name, ExpirationDate, Status, Review_Requested_for__c, Additional__c,
                        Lump_Sum_Discount__c, ContactId, BillingName, BillingCountry, BillingStreet,
                        BillingCity, BillingState, BillingPostalCode, ShippingName, ShippingCountry,
                        ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, OpportunityId,
                        AccountId,Pricebook2Id,Opportunity.Name, Account.Name,Pricebook2.Name
                 FROM Quote
                 WHERE Id = :quoteId
                 LIMIT 1
             ];
         } catch (Exception e) {
             throw new AuraHandledException('Error retrieving Quote: ' + e.getMessage());
         }
     }
 
     @AuraEnabled
     public static Id createQuote(Map<String, Object> quoteData) {
         try {
             Quote newQuote = new Quote(
                 Name = (String)quoteData.get('Name'),
                 QuoteAccountId= (Id)quoteData.get('AccountId'),
                 End_Customer__c=(Id)quoteData.get('endCustomerId'),
                 ExpirationDate = quoteData.get('ExpirationDate') != null ? Date.valueOf((String)quoteData.get('ExpirationDate')) : null,
                 OpportunityId = (Id)quoteData.get('OpportunityId'),
                 Status = (String)quoteData.get('Status'),
                 Review_Requested_for__c = (String)quoteData.get('Review_Requested_for__c'),
                 Additional__c = (String)quoteData.get('Additional__c'),
                 Lump_Sum_Discount__c = quoteData.get('Lump_Sum_Discount__c') != null ? Boolean.valueOf(quoteData.get('Lump_Sum_Discount__c')) : false,
                 ContactId = (Id)quoteData.get('ContactId'),
                 BillingName = (String)quoteData.get('BillingName'),
                 BillingCountry = (String)quoteData.get('BillingCountry'),
                 BillingStreet = (String)quoteData.get('BillingStreet'),
                 BillingCity = (String)quoteData.get('BillingCity'),
                 BillingState = (String)quoteData.get('BillingState'), // Picklist field
                 BillingPostalCode = (String)quoteData.get('BillingPostalCode'),
                 ShippingName = (String)quoteData.get('ShippingName'),
                 ShippingCountry = (String)quoteData.get('ShippingCountry'),
                 ShippingStreet = (String)quoteData.get('ShippingStreet'),
                 ShippingCity = (String)quoteData.get('ShippingCity'),
                 ShippingState = (String)quoteData.get('ShippingState'), // Picklist field
                 ShippingPostalCode = (String)quoteData.get('ShippingPostalCode'),
                 Pricebook2Id = (String) quoteData.get('Pricebook2Id')
             );
 
             insert newQuote;
             return newQuote.Id;
         } catch (Exception e) {
             throw new AuraHandledException('Error creating Quote: ' + e.getMessage());
         }
     }
 
    @AuraEnabled
 public static Id updateQuote(Map<String, Object> quoteData, Id quoteId) {
     try {
         // Fetch the existing quote to retain the original OpportunityId
         Quote existingQuote = [SELECT Id, OpportunityId FROM Quote WHERE Id = :quoteId LIMIT 1];
 
         // Update only the allowed fields
         existingQuote.Name = (String)quoteData.get('Name');
        existingQuote.QuoteAccountId= (Id)quoteData.get('AccountId');
        if(quoteData.get('endCustomerId') != null){
            existingQuote.End_Customer__c=(Id)quoteData.get('endCustomerId');
        }
         existingQuote.ExpirationDate = quoteData.get('ExpirationDate') != null ? Date.valueOf((String)quoteData.get('ExpirationDate')) : null;
         existingQuote.Status = (String)quoteData.get('Status');
         existingQuote.Review_Requested_for__c = (String)quoteData.get('Review_Requested_for__c');
         existingQuote.Additional__c = (String)quoteData.get('Additional__c');
         existingQuote.Lump_Sum_Discount__c = quoteData.get('Lump_Sum_Discount__c') != null ? Boolean.valueOf(quoteData.get('Lump_Sum_Discount__c')) : false;
         existingQuote.ContactId = (Id)quoteData.get('ContactId');
         existingQuote.BillingName = (String)quoteData.get('BillingName');
         existingQuote.BillingCountry = (String)quoteData.get('BillingCountry');
         existingQuote.BillingStreet = (String)quoteData.get('BillingStreet');
         existingQuote.BillingCity = (String)quoteData.get('BillingCity');
         existingQuote.BillingState = (String)quoteData.get('BillingState');
         existingQuote.BillingPostalCode = (String)quoteData.get('BillingPostalCode');
         existingQuote.ShippingName = (String)quoteData.get('ShippingName');
         existingQuote.ShippingCountry = (String)quoteData.get('ShippingCountry');
         existingQuote.ShippingStreet = (String)quoteData.get('ShippingStreet');
         existingQuote.ShippingCity = (String)quoteData.get('ShippingCity');
         existingQuote.ShippingState = (String)quoteData.get('ShippingState');
         existingQuote.ShippingPostalCode = (String)quoteData.get('ShippingPostalCode');
         existingQuote.Pricebook2Id = (String) quoteData.get('Pricebook2Id');
         update existingQuote;
         return existingQuote.Id;
     } catch (Exception e) {
         system.debug('error' + e.getMessage());
         throw new AuraHandledException('Error updating Quote: ' + e.getMessage());
     }
 }
 
     @AuraEnabled
     public static String saveQuote(Quote quoteRecord) {
         try {
             upsert quoteRecord;
             return quoteRecord.Id;
         } catch (Exception e) {
             throw new AuraHandledException('Error saving Quote: ' + e.getMessage());
         }
     }
      @AuraEnabled
     public static void deleteQuote(Id quoteId) {
         Quote quote = new Quote(Id = quoteId);
         delete quote;
     }
     @AuraEnabled
     public static Quote getEditQuoteById(String quoteId) {
     try {
         return [
             SELECT Id, Name, ExpirationDate, Status, Review_Requested_for__c, Additional__c,
                    Lump_Sum_Discount__c, ContactId, BillingName, BillingCountry, BillingStreet,
                    BillingCity, BillingState, BillingPostalCode, ShippingName, ShippingCountry,
                    ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, OpportunityId,
                    QuoteAccountId,Pricebook2Id,Opportunity.Name, QuoteAccount.Name,CurrencyIsoCode,Pricebook2.Name,
                    End_Customer__c,End_Customer__r.Name
             FROM Quote
             WHERE Id = :quoteId
             LIMIT 1
         ];
     } catch (Exception e) {
         throw new AuraHandledException('Error retrieving Quote: ' + e.getMessage());
     }
 }
 
 @AuraEnabled(cacheable=false)
    public static void syncQuoteLineItems(Id quoteId,List<QuoteLineItemWrapper> itemsToInsert,List<QuoteLineItemWrapper> itemsToUpdate,List<String> itemsToDelete) {
        try {
            // Validate quoteId
            if (quoteId == null) {
                throw new AuraHandledException('Quote ID is required.');
            }
            // Log inputs
            // System.debug('quoteId: ' + quoteId);
            // System.debug('itemsToInsert: ' + JSON.serialize(itemsToInsert));
            // System.debug('itemsToUpdate: ' + JSON.serialize(itemsToUpdate));
            // System.debug('itemsToDelete: ' + JSON.serialize(itemsToDelete));

            // Step 1: Delete Quote Line Items
            if (itemsToDelete != null && !itemsToDelete.isEmpty()) {
                List<QuoteLineItem> itemsToDeleteRecords = [SELECT Id FROM QuoteLineItem WHERE Id IN :itemsToDelete AND QuoteId = :quoteId WITH SECURITY_ENFORCED];
                if (!itemsToDeleteRecords.isEmpty()) {
                    delete itemsToDeleteRecords;
                }
            }

            // Step 2: Update existing Quote Line Items
            List<QuoteLineItem> quoteLineItemsToUpdate = new List<QuoteLineItem>();
            if (itemsToUpdate != null && !itemsToUpdate.isEmpty()) {
                Set<Id> updateIds = new Set<Id>();
                for (Integer i = 0; i < itemsToUpdate.size(); i++) {
                    QuoteLineItemWrapper wrapper = itemsToUpdate[i];
                    // Reject completely empty wrapper
                    if (wrapper.Id == null && wrapper.Product2Id == null && wrapper.PricebookEntryId == null &&
                        wrapper.UnitPrice == null && wrapper.Quantity == null && wrapper.productName == null) {
                        throw new AuraHandledException('Invalid update item at index ' + i + ': All fields are null.');
                    }
                    // Validate Id format
                    Id itemId;
                    try {
                        itemId = (Id)wrapper.Id;
                        if (itemId.getSObjectType() != QuoteLineItem.SObjectType) {
                            throw new AuraHandledException('Id is not a QuoteLineItem ID.');
                        }
                        updateIds.add(itemId);
                    } catch (Exception e) {
                        throw new AuraHandledException('Invalid update item at index ' + i + ': Invalid Id ' + wrapper.Id + ': ' + e.getMessage());
                    }
                }

                // Verify QuoteLineItems exist and are accessible
                List<QuoteLineItem> existingItems = [SELECT Id, QuoteId, Product2Id, PricebookEntryId FROM QuoteLineItem WHERE Id IN :updateIds AND QuoteId = :quoteId WITH SECURITY_ENFORCED];
                Map<Id, QuoteLineItem> existingItemsMap = new Map<Id, QuoteLineItem>(existingItems);
                // Validate Quote's Pricebook2Id
                Quote quote = [SELECT Id, Pricebook2Id FROM Quote WHERE Id = :quoteId WITH SECURITY_ENFORCED LIMIT 1];
                for (Integer i = 0; i < itemsToUpdate.size(); i++) {
                    QuoteLineItemWrapper wrapper = itemsToUpdate[i];
                    // System.debug('Processing wrapper[' + i + ']: ' + JSON.serialize(wrapper));
                    Id itemId = (Id)wrapper.Id;

                    if (!existingItemsMap.containsKey(itemId)) {
                        throw new AuraHandledException('Invalid update item at index ' + i + ': QuoteLineItem with Id ' + wrapper.Id + ' does not exist or is not accessible.');
                    }

                    QuoteLineItem existingItem = existingItemsMap.get(itemId);
                    if (existingItem.QuoteId != quoteId) {
                        throw new AuraHandledException('Invalid update item at index ' + i + ': QuoteLineItem ' + wrapper.Id + ' does not belong to Quote ' + quoteId + '.');
                    }

                    // Verify PricebookEntry
                    // List<PricebookEntry> pbeList = [
                    //     SELECT Id
                    //     FROM PricebookEntry
                    //     WHERE Id = :wrapper.PricebookEntryId
                    //     AND Pricebook2Id = :quote.Pricebook2Id
                    //     WITH SECURITY_ENFORCED
                    //     LIMIT 1
                    // ];
                    // if (pbeList.isEmpty()) {
                    //     throw new AuraHandledException('Invalid update item at index ' + i + ': PricebookEntryId ' + wrapper.PricebookEntryId + ' does not match Quote\'s Pricebook2Id.');
                    // }

                    QuoteLineItem qli = new QuoteLineItem(
                        Id = wrapper.Id,
                        QuoteId = quoteId,
                        Product2Id = wrapper.Product2Id,
                        Product_Name__c = wrapper.productName,
                        PricebookEntryId = wrapper.PricebookEntryId,
                        UnitPrice = wrapper.UnitPrice,
                        Quantity = wrapper.Quantity,
                        Discount = wrapper.Discount,
                        Product_Description__c = wrapper.productDescription,
                        SortOrder = wrapper.orderNumber != null ? Integer.valueOf(wrapper.orderNumber) : null,
                        Is_Cloned__c = wrapper.isCloned != null ? wrapper.isCloned : false
                    );
                    quoteLineItemsToUpdate.add(qli);
                }

                if (!quoteLineItemsToUpdate.isEmpty()) {
                    // System.debug('quoteLineItemsToUpdate: ' + JSON.serialize(quoteLineItemsToUpdate));
                    try {
                        update quoteLineItemsToUpdate;
                    } catch (DmlException e) {
                        String errorMsg = 'Error updating QuoteLineItems: ';
                        for (Integer i = 0; i < e.getNumDml(); i++) {
                            errorMsg += 'Record ' + quoteLineItemsToUpdate[e.getDmlIndex(i)].Id + ': ' + e.getDmlMessage(i) + '; ';
                        }
                        throw new AuraHandledException(errorMsg);
                    }
                }
            }

            // Step 3: Insert new Quote Line Items
            List<QuoteLineItem> quoteLineItemsToInsert = new List<QuoteLineItem>();
            if (itemsToInsert != null && !itemsToInsert.isEmpty()) {
                Quote quote = [SELECT Id, Pricebook2Id FROM Quote WHERE Id = :quoteId WITH SECURITY_ENFORCED LIMIT 1];
                for (Integer i = 0; i < itemsToInsert.size(); i++) {
                    QuoteLineItemWrapper wrapper = itemsToInsert[i];
                    // Verify PricebookEntry
                    // List<PricebookEntry> pbeList = [
                    //     SELECT Id
                    //     FROM PricebookEntry
                    //     WHERE Id = :wrapper.PricebookEntryId
                    //     AND Pricebook2Id = :quote.Pricebook2Id
                    //     WITH SECURITY_ENFORCED
                    //     LIMIT 1
                    // ];
                    // if (pbeList.isEmpty()) {
                    //     throw new AuraHandledException('Invalid insert item at index ' + i + ': PricebookEntryId ' + wrapper.PricebookEntryId + ' does not match Quote\'s Pricebook2Id.');
                    // }

                    QuoteLineItem qli = new QuoteLineItem(
                        QuoteId = quoteId,
                        Product2Id = wrapper.Product2Id,
                        Product_Name__c = wrapper.productName,
                        PricebookEntryId = wrapper.PricebookEntryId,
                        UnitPrice = wrapper.UnitPrice,
                        Quantity = wrapper.Quantity,
                        Discount = wrapper.Discount,
                        Product_Description__c = wrapper.productDescription,
                        SortOrder = wrapper.orderNumber != null ? Integer.valueOf(wrapper.orderNumber) : null,
                        Is_Cloned__c = wrapper.isCloned != null ? wrapper.isCloned : false
                    );
                    quoteLineItemsToInsert.add(qli);
                }

                if (!quoteLineItemsToInsert.isEmpty()) {
                    // System.debug('quoteLineItemsToInsert: ' + JSON.serialize(quoteLineItemsToInsert));
                    insert quoteLineItemsToInsert;
                }
            }

        } catch (Exception e) {
            String errorMsg = 'Error syncing quote line items: ' + e.getMessage() + '\nStack trace: ' + e.getStackTraceString();
            // System.debug(LoggingLevel.ERROR, errorMsg);
            throw new AuraHandledException(errorMsg);
        }
    }
 
public class QuoteLineItemWrapper {
    @AuraEnabled public String Id { get; set; }
    @AuraEnabled public String QuoteId { get; set; }
    @AuraEnabled public String Product2Id { get; set; }
    @AuraEnabled public String PricebookEntryId { get; set; }
    @AuraEnabled public String productName { get; set; }
    @AuraEnabled public Decimal UnitPrice { get; set; }
    @AuraEnabled public Decimal Quantity { get; set; }
    @AuraEnabled public Decimal Discount { get; set; }
    @AuraEnabled public String productDescription { get; set; }
    @AuraEnabled public Integer orderNumber { get; set; }
    @AuraEnabled public Boolean isCloned { get; set; }
}
 
 
     @AuraEnabled
     public static void replaceAllQuoteLineItems(String quoteId, List<Map<String, Object>> itemsToInsert) {
         try {
             // Validate inputs
             if (String.isBlank(quoteId)) {
                 throw new AuraHandledException('Quote ID is required.');
             }
             if (itemsToInsert == null) {
                 throw new AuraHandledException('Items to insert cannot be null.');
             }
 
             // Delete all existing QuoteLineItems
             List<QuoteLineItem> existingItems = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :quoteId];
             if (!existingItems.isEmpty()) {
                 delete existingItems;
             }
 
             // Prepare and insert new QuoteLineItems
             List<QuoteLineItem> newItems = new List<QuoteLineItem>();
             for (Integer i = 0; i < itemsToInsert.size(); i++) {
                 Map<String, Object> item = itemsToInsert[i];
 
                 // Validate required fields
                 if (!item.containsKey('PricebookEntryId') || String.isBlank((String)item.get('PricebookEntryId'))) {
                     throw new AuraHandledException('PricebookEntryId is missing for item at row ' + i);
                 }
                 if (!item.containsKey('UnitPrice') || item.get('UnitPrice') == null) {
                     throw new AuraHandledException('UnitPrice is missing or invalid for item at row ' + i);
                 }
                 if (!item.containsKey('Quantity') || item.get('Quantity') == null) {
                     throw new AuraHandledException('Quantity is missing or invalid for item at row ' + i);
                 }
 
                 QuoteLineItem qli = new QuoteLineItem();
                 qli.QuoteId = quoteId;
                 qli.PricebookEntryId = (String)item.get('PricebookEntryId');
                 qli.Product2Id = item.containsKey('Product2Id') ? (String)item.get('Product2Id') : null;
                 qli.Product_Name__c = item.containsKey('productName') ? (String)item.get('productName') : null;
                 qli.UnitPrice = Decimal.valueOf(String.valueOf(item.get('UnitPrice')));
                 qli.Quantity = Integer.valueOf(item.get('Quantity'));
                 qli.Discount = item.containsKey('Discount') && item.get('Discount') != null ? Decimal.valueOf(String.valueOf(item.get('Discount'))) : null;
                 qli.Product_Description__c = item.containsKey('productDescription') ? (String)item.get('productDescription') : null;
                 qli.Order__c = item.containsKey('orderNumber') ? Integer.valueOf(item.get('orderNumber')) : i + 1;
                 qli.SortOrder=item.containsKey('orderNumber') ? Integer.valueOf(item.get('orderNumber')) : i + 1;
 
                 newItems.add(qli);
             }
 
             // Insert new QuoteLineItems
             if (!newItems.isEmpty()) {
                // System.debug('newItems==>'+JSON.serialize(newItems));
                 insert newItems;
             }
 
         } catch (Exception e) {
            String errorMessage = e.getMessage();
             if (e.getTypeName() == 'System.DmlException') {
                 errorMessage = e.getDmlMessage(0);
                 //if (errorMessage.contains('Proposed Price can not be less than List Price')) {
                    // Integer rowIndex = newItems.size() > 0 ? newItems.size() - 1 : 0;
                     //errorMessage = 'Proposed Price can not be less than List Price at row ' + rowIndex;
                 //}
             }
            throw new AuraHandledException(errorMessage);
         }
     }
 }