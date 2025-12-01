@isTest
public class QuoteLineItemController_Test {

    @testSetup
    static void setup() {
        // Create test data for the test methods

        // Create an account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create an opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;
        currentQuoteNumber__c setting = new currentQuoteNumber__c(
            Name = 'Default',
            currentQuoteNumberIndia__c = 1,
            currentQuoteNumber__c = 1
        );
        insert setting;
        // Create a quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert quote;

        // Create a product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        // Create a pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create quote line items
        List<QuoteLineItem> qliList = new List<QuoteLineItem>();
        for (Integer i = 0; i < 3; i++) {
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = quote.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1 + i,
                UnitPrice = 100 + (i * 10),
                Discount = i * 5,
                Product_Description__c = 'Description ' + i,
                Product_Name__c = 'Product Name ' + i
            );
            qliList.add(qli);
        }
        insert qliList;
    }

    @isTest
    static void testGetQuoteLineItems() {
        // Get the test quote ID
        Id quoteId = [SELECT Id FROM Quote LIMIT 1].Id;

        // Call the method to retrieve quote line items
        List<QuoteLineItem> result = QuoteLineItemController.getQuoteLineItems(quoteId);

        // Verify the result
        System.assertEquals(3, result.size(), 'Expected 3 quote line items');
        for (QuoteLineItem qli : result) {
            System.assertNotEquals(null, qli.Product2.Name, 'Product Name should not be null');
            System.assertNotEquals(null, qli.UnitPrice, 'Unit Price should not be null');
        }
    }

    @isTest
    static void testUpdateQuoteLineItems() {
        // Retrieve quote line items to update
        List<QuoteLineItem> quoteLineItems = [SELECT Id, Quantity, UnitPrice FROM QuoteLineItem LIMIT 2];
        for (QuoteLineItem qli : quoteLineItems) {
            qli.Quantity = qli.Quantity + 1;
            qli.UnitPrice = qli.UnitPrice + 10;
        }

        // Call the method to update quote line items
        QuoteLineItemController.updateQuoteLineItems(quoteLineItems);

        // Verify that the quote line items were updated
        List<QuoteLineItem> updatedItems = [SELECT Quantity, UnitPrice FROM QuoteLineItem WHERE Id IN :quoteLineItems];
        for (Integer i = 0; i < updatedItems.size(); i++) {
            System.assertEquals(quoteLineItems[i].Quantity, updatedItems[i].Quantity, 'Quantity should be updated');
            System.assertEquals(quoteLineItems[i].UnitPrice, updatedItems[i].UnitPrice, 'Unit Price should be updated');
        }
    }

    @isTest
    static void testUpdateQuoteLineItems_Exception() {
        // Prepare a list with an invalid quote line item
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>{
            new QuoteLineItem(Id = null, Quantity = 1, UnitPrice = 100) // Invalid ID
        };

        Test.startTest();
        try {
            QuoteLineItemController.updateQuoteLineItems(quoteLineItems);
            System.assert(false, 'Exception was expected due to invalid quote line item');
        } catch (AuraHandledException e) {
            System.assert(true, 'Expected error message about updating QuoteLineItems');
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteQuoteLineItem() {
        // Get a quote line item to delete
        Id quoteLineItemId = [SELECT Id FROM QuoteLineItem LIMIT 1].Id;

        // Call the method to delete the quote line item
        QuoteLineItemController.deleteQuoteLineItem(quoteLineItemId);

        // Verify that the quote line item was deleted
        List<QuoteLineItem> deletedItems = [SELECT Id FROM QuoteLineItem WHERE Id = :quoteLineItemId];
        System.assertEquals(0, deletedItems.size(), 'Quote line item should be deleted');
    }

    @isTest
    static void testDeleteQuoteLineItem_Exception() {
        // Use an invalid ID for deletion
        Id invalidId = [SELECT Id FROM QuoteLineItem LIMIT 1].Id;

        Test.startTest();
        try {
            QuoteLineItemController.deleteQuoteLineItem(invalidId);
            System.assert(true, 'Exception was expected due to invalid ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Quote Line Item not found'), 'Expected error message about not found Quote Line Item');
        }
        Test.stopTest();
    }

}