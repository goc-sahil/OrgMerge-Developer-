@isTest
private with sharing class QuoteLineItemsControllerTest {
    @testSetup
    static void setupTestData() {
        // Create complete test setup using factory
        QuoteTestDataFactory.createCompleteTestSetup();
        
        // Get standard pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        // Update opportunity with pricebook
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Standard Test Opportunity' LIMIT 1];
        opp.Pricebook2Id = standardPricebook.Id;
        update opp;
        
        // Create product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'PROD-001',
            IsActive = true
        );
        insert testProduct;
        
        // Create pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe;
        
        // Update quote with pricebook
        Quote quote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        quote.Pricebook2Id = standardPricebook.Id;
        update quote;
        
        // Create quote line items with different SortOrder values
        List<QuoteLineItem> lineItems = new List<QuoteLineItem>();
        lineItems.add(new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00,
            SortOrder = 1,
            Product_Name__c = 'Product A'
        ));
        lineItems.add(new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 150.00,
            SortOrder = 2,
            Product_Name__c = 'Product B'
        ));
        insert lineItems;
    }

    @isTest
    static void testControllerInitializationAndQuoteIdSetting() {
        // Arrange
        Quote testQuote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        QuoteLineItemsController controller = new QuoteLineItemsController();
        
        // Act
        Test.startTest();
        controller.internalQuoteId = testQuote.Id;
        Test.stopTest();
        
        // Assert
        System.assertEquals(testQuote.Id, controller.internalQuoteId, 'Quote ID should be set correctly');
        System.assertNotEquals(null, controller.sortedLineItems, 'Sorted line items should be initialized');
        System.assertEquals(2, controller.sortedLineItems.size(), 'Should load two quote line items');
        // System.assertEquals('Product A', controller.sortedLineItems[0].Product_Name__c, 
        //     'First item should be Product A based on SortOrder');
        // System.assertEquals('Product B', controller.sortedLineItems[1].Product_Name__c, 
        //     'Second item should be Product B based on SortOrder');
    }

    @isTest
    static void testLoadSortedLineItemsWithNullQuoteId() {
        // Arrange
        QuoteLineItemsController controller = new QuoteLineItemsController();
        
        // Act
        Test.startTest();
        controller.internalQuoteId = null;
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, controller.sortedLineItems.size(), 
            'Sorted line items should be empty when quote ID is null');
    }

    @isTest
    static void testLoadSortedLineItemsWithEmptyQuote() {
        // Arrange
        Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity 
                        WHERE Name = 'Standard Test Opportunity' LIMIT 1];
        Quote emptyQuote = QuoteTestDataFactory.createQuote('Empty Test Quote', opp.Id, opp.Pricebook2Id);
        QuoteLineItemsController controller = new QuoteLineItemsController();
        
        // Act
        Test.startTest();
        controller.internalQuoteId = emptyQuote.Id;
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, controller.sortedLineItems.size(), 
            'Sorted line items should be empty for quote with no line items');
    }


    @isTest
    static void testQuoteRecordProperty() {
        // Arrange
        Quote testQuote = [SELECT Id, Name FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        QuoteLineItemsController controller = new QuoteLineItemsController();
        
        // Act
        Test.startTest();
        controller.internalQuoteId = testQuote.Id;
        controller.quoteRecord = new Quote(Id = testQuote.Id, Name = 'Standard Test Quote');
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, controller.quoteRecord, 'Quote record should be set');
        System.assertEquals('Standard Test Quote', controller.quoteRecord.Name, 
            'Quote record name should match');
    }
}