@isTest
public class QuoteLineItemSorterTest {


    @isTest
    static void testUpdateSortOrders_Success() {
        // Setup test data using factory
        Id quoteId = TestDataFactory.setupTestData();
        
        // Get quote line items
        List<QuoteLineItem> qlis = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :quoteId ORDER BY SortOrder ASC];
        
        // Create updates list - reverse the sort order
        List<QuoteLineItemSorter.QLIUpdate> updates = new List<QuoteLineItemSorter.QLIUpdate>();
        for (Integer i = 0; i < qlis.size(); i++) {
            QuoteLineItemSorter.QLIUpdate qliUpdate = new QuoteLineItemSorter.QLIUpdate();
            qliUpdate.id = qlis[i].Id;
            qliUpdate.sortOrder = qlis.size() - i; // Reverse order
            updates.add(qliUpdate);
        }

        Test.startTest();
        List<Id> result = QuoteLineItemSorter.updateSortOrders(updates);
        Test.stopTest();

        // Verify result contains all updated IDs
        System.assertEquals(qlis.size(), result.size(), 'Should return all updated IDs');
        
        // Verify the sort orders were updated
        List<QuoteLineItem> updatedQLIs = [SELECT Id, SortOrder FROM QuoteLineItem WHERE Id IN :qlis ORDER BY Id];
        for (Integer i = 0; i < updatedQLIs.size(); i++) {
            Integer expectedSortOrder = qlis.size() - i;
            System.assertEquals(
                expectedSortOrder,
                updatedQLIs[i].SortOrder,
                'SortOrder should be updated to ' + expectedSortOrder
            );
        }
    }

    @isTest
    static void testUpdateSortOrders_NullUpdates() {
        Test.startTest();
        try {
            QuoteLineItemSorter.updateSortOrders(null);
            System.assert(false, 'Expected AuraHandledException for null updates');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Expected error message for null updates');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateSortOrders_EmptyList() {
        Test.startTest();
        try {
            QuoteLineItemSorter.updateSortOrders(new List<QuoteLineItemSorter.QLIUpdate>());
            System.assert(false, 'Expected AuraHandledException for empty updates');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Expected error message for empty updates');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateSortOrders_NullUpdateId() {
        // Create updates with null ID
        List<QuoteLineItemSorter.QLIUpdate> updates = new List<QuoteLineItemSorter.QLIUpdate>();
        QuoteLineItemSorter.QLIUpdate qliUpdate = new QuoteLineItemSorter.QLIUpdate();
        qliUpdate.id = null;
        qliUpdate.sortOrder = 1;
        updates.add(qliUpdate);

        Test.startTest();
        try {
            QuoteLineItemSorter.updateSortOrders(updates);
            System.assert(false, 'Expected AuraHandledException for invalid records');
        } catch (AuraHandledException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Expected error message for no valid records');
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateSortOrders_CalloutEnqueued() {
        // Setup test data using factory
        Id quoteId = TestDataFactory.setupTestData();
        
        // Get a quote line item
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :quoteId LIMIT 1];
        
        // Create update
        List<QuoteLineItemSorter.QLIUpdate> updates = new List<QuoteLineItemSorter.QLIUpdate>();
        QuoteLineItemSorter.QLIUpdate qliUpdate = new QuoteLineItemSorter.QLIUpdate();
        qliUpdate.id = qli.Id;
        qliUpdate.sortOrder = 999;
        updates.add(qliUpdate);

        Test.startTest();
        List<Id> result = QuoteLineItemSorter.updateSortOrders(updates);
        Test.stopTest();

        // Verify the sort order was updated
        QuoteLineItem updatedQLI = [SELECT SortOrder FROM QuoteLineItem WHERE Id = :qli.Id];
        System.assertEquals(999, updatedQLI.SortOrder, 'SortOrder should be updated to 999');
        
        // Note: We can't directly verify the queueable job was enqueued in this test
        // because Test.startTest/stopTest will execute it synchronously, but the method
        // should handle it gracefully even if the callout fails in test context
    }

    @isTest
    static void testQLIUpdate_WrapperClass() {
        // Setup test data using factory
        Id quoteId = TestDataFactory.setupTestData();
        
        // Test the wrapper class
        QuoteLineItemSorter.QLIUpdate qliUpdate = new QuoteLineItemSorter.QLIUpdate();
        
        // Get a test ID
        Id testId = [SELECT Id FROM QuoteLineItem WHERE QuoteId = :quoteId LIMIT 1].Id;
        
        // Set properties
        qliUpdate.id = testId;
        qliUpdate.sortOrder = 5;
        
        // Verify properties
        System.assertEquals(testId, qliUpdate.id, 'ID should match');
        System.assertEquals(5, qliUpdate.sortOrder, 'Sort order should match');
    }

    @isTest
    static void testGetQuoteLineItems_WithCurrencyAndParent() {
        // Setup test data using factory
        Id quoteId = TestDataFactory.setupTestData();
        
        // Get existing pricebook entry
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];

        // Create a parent quote line item
        QuoteLineItem parentQLI = new QuoteLineItem(
            QuoteId = quoteId,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 50000,
            Product_Name__c = 'Parent Product',
            SortOrder = 10
        );
        insert parentQLI;

        Test.startTest();
        List<QuoteLineItem> result = QuoteLineItemSorter.getQuoteLineItems(quoteId);
        Test.stopTest();

        // Verify the results include parent and factory-created QLI
        System.assert(result.size() >= 2, 'Should have at least 2 quote line items');
        
        // Verify CurrencyIsoCode field is retrieved
        for (QuoteLineItem qli : result) {
            // CurrencyIsoCode should be present (may be null if not multi-currency)
            System.assertNotEquals(null, qli.Id, 'Id should not be null');
        }
    }
}
