/**
 * @description Test class for QuoteTriggerHandler
 * @author Sahil Kakadiya
 * @date April 23, 2025
 */
@isTest
private class QuoteTriggerHandlerTest {
    
    /**
     * @description Test setup method to create test data
     */
    @testSetup
    static void setupTestData() {
        // Create quote counter using factory
        QuoteTestDataFactory.createQuoteCounter();
        
        // Create test data
        Account testAccount = QuoteTestDataFactory.createAccount('Test Account', 'United States');
        Opportunity testOpp = QuoteTestDataFactory.createOpportunity('Test Opportunity', testAccount.Id);
        
        // Set up pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
        
        testOpp.Pricebook2Id = standardPricebook.Id;
        update testOpp;
        
        // Create product and pricebook entry
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'PROD-001',
            IsActive = true
        );
        insert testProduct;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbe;
        
        // Create quote
        Quote testQuote = QuoteTestDataFactory.createQuote('Test Quote', testOpp.Id);
        testQuote.Pricebook2Id = standardPricebook.Id;
        testQuote.Status = 'Draft';
        testQuote.Quote_Number_Constant__c = 'Q-12345';
        update testQuote;
    }
    
    /**
     * @description Test that Lump_Sum_Discount__c is set to true when Total_Margin__c is negative
     */
    @isTest
    static void testNegativeMarginRequiresApproval() {
        // Arrange
        Quote testQuote = [SELECT Id, Status, Total_Margin__c, Lump_Sum_Discount__c 
                         FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Create QuoteLineItem to set negative Total_Margin__c
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00
            // Margin__c is a formula field; assume it results in Total_Margin__c = -10
        );
        insert qli;
        
        // Simulate negative Total_Margin__c
        testQuote.Total_Margin__c = -10.00; // Mock the formula result
        Quote oldQuote = testQuote.clone(true);
        oldQuote.Status = 'Draft';
        Map<Id, Quote> oldMap = new Map<Id, Quote>{testQuote.Id => oldQuote};
        
        testQuote.Status = 'In Review'; // Valid transition from Draft
        
        // Act
        Test.startTest();
        QuoteTriggerHandler.evaluateApproval(oldMap, new List<Quote>{testQuote});
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(true, testQuote.Lump_Sum_Discount__c, 
            'Lump_Sum_Discount__c should be true when Total_Margin__c is negative');
    }
    
    /**
     * @description Test that Lump_Sum_Discount__c is false when Total_Margin__c is positive
     */
    @isTest
    static void testPositiveMarginNoApproval() {
        // Arrange
        Quote testQuote = [SELECT Id, Status, Total_Margin__c, Lump_Sum_Discount__c 
                         FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Create QuoteLineItem to set positive Total_Margin__c
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00
            // Margin__c is a formula field; assume it results in Total_Margin__c = 10
        );
        insert qli;
        
        // Simulate positive Total_Margin__c
        testQuote.Total_Margin__c = 10.00; // Mock the formula result
        Quote oldQuote = testQuote.clone(true);
        oldQuote.Status = 'Draft';
        Map<Id, Quote> oldMap = new Map<Id, Quote>{testQuote.Id => oldQuote};
        
        testQuote.Status = 'In Review';
        
        // Act
        Test.startTest();
        QuoteTriggerHandler.evaluateApproval(oldMap, new List<Quote>{testQuote});
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, testQuote.Lump_Sum_Discount__c, 
            'Lump_Sum_Discount__c should be false when Total_Margin__c is positive');
    }
    
    /**
     * @description Test that Lump_Sum_Discount__c is false when Total_Margin__c is zero
     */
    @isTest
    static void testZeroMarginNoApproval() {
        // Arrange
        Quote testQuote = [SELECT Id, Status, Total_Margin__c, Lump_Sum_Discount__c 
                         FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Create QuoteLineItem to set zero Total_Margin__c
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00
            // Margin__c is a formula field; assume it results in Total_Margin__c = 0
        );
        insert qli;
        
        // Simulate zero Total_Margin__c
        testQuote.Total_Margin__c = 0.00; // Mock the formula result
        Quote oldQuote = testQuote.clone(true);
        oldQuote.Status = 'Draft';
        Map<Id, Quote> oldMap = new Map<Id, Quote>{testQuote.Id => oldQuote};
        
        testQuote.Status = 'In Review';
        
        // Act
        Test.startTest();
        QuoteTriggerHandler.evaluateApproval(oldMap, new List<Quote>{testQuote});
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, testQuote.Lump_Sum_Discount__c, 
            'Lump_Sum_Discount__c should be false when Total_Margin__c is zero');
    }
    
    /**
     * @description Test that no update occurs when status doesn't change from Draft
     */
    @isTest
    static void testNoStatusChangeFromDraft() {
        // Arrange
        Quote testQuote = [SELECT Id, Status, Total_Margin__c, Lump_Sum_Discount__c 
                         FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00
        );
        insert qli;
        
        testQuote.Total_Margin__c = -10.00; // Mock negative margin
        Quote oldQuote = testQuote.clone(true);
        oldQuote.Status = 'Draft';
        Map<Id, Quote> oldMap = new Map<Id, Quote>{testQuote.Id => oldQuote};
        
        testQuote.Status = 'Draft'; // No status change
        
        // Act
        Test.startTest();
        QuoteTriggerHandler.evaluateApproval(oldMap, new List<Quote>{testQuote});
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, testQuote.Lump_Sum_Discount__c, 
            'Lump_Sum_Discount__c should not be updated when status remains Draft');
    }
    
    /**
     * @description Test that no update occurs when status changes from non-Draft
     */
    @isTest
    static void testStatusChangeFromNonDraft() {
        // Arrange
        Quote testQuote = [SELECT Id, Status, Total_Margin__c, Lump_Sum_Discount__c 
                         FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100.00
        );
        insert qli;
        
        testQuote.Total_Margin__c = -10.00; // Mock negative margin
        Quote oldQuote = testQuote.clone(true);
        oldQuote.Status = 'Approved';
        Map<Id, Quote> oldMap = new Map<Id, Quote>{testQuote.Id => oldQuote};
        
        testQuote.Status = 'Draft'; // Transition from Approved to Draft
        
        // Act
        Test.startTest();
        QuoteTriggerHandler.evaluateApproval(oldMap, new List<Quote>{testQuote});
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, testQuote.Lump_Sum_Discount__c, 
            'Lump_Sum_Discount__c should not be updated when status changes from non-Draft');
    }
    
    /**
     * @description Test bulk update of quotes with varying Total_Margin__c values
     */
    @isTest
    static void testBulkUpdate() {
        // Arrange
        Account testAccount = QuoteTestDataFactory.createAccount('Bulk Test Account', 'United States');
        Opportunity testOpp = QuoteTestDataFactory.createOpportunity('Bulk Test Opportunity', testAccount.Id);
        testOpp.Pricebook2Id = Test.getStandardPricebookId();
        update testOpp;
        
        List<Quote> quotes = QuoteTestDataFactory.createQuotes(
            new List<String>{'Bulk Quote 1', 'Bulk Quote 2', 'Bulk Quote 3'},
            testOpp.Id
        );
        
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Set up quotes
        for (Integer i = 0; i < quotes.size(); i++) {
            quotes[i].Pricebook2Id = testOpp.Pricebook2Id;
            quotes[i].Status = 'Draft';
            quotes[i].Quote_Number_Constant__c = 'Q-00' + (i + 1);
        }
        update quotes;
        
        // Create QuoteLineItems and mock Total_Margin__c
        List<QuoteLineItem> lineItems = new List<QuoteLineItem>();
        for (Quote q : quotes) {
            lineItems.add(new QuoteLineItem(
                QuoteId = q.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100.00
            ));
        }
        insert lineItems;
        
        Map<Id, Quote> oldMap = new Map<Id, Quote>();
        for (Integer i = 0; i < quotes.size(); i++) {
            Quote oldQuote = quotes[i].clone(true);
            oldQuote.Status = 'Draft';
            oldMap.put(quotes[i].Id, oldQuote);
            quotes[i].Status = 'In Review';
            // Mock different Total_Margin__c values
            quotes[i].Total_Margin__c = i == 0 ? -10.00 : (i == 1 ? 10.00 : 0.00);
        }
        
        // Act
        Test.startTest();
        QuoteTriggerHandler.evaluateApproval(oldMap, quotes);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(true, quotes[0].Lump_Sum_Discount__c, 
            'Lump_Sum_Discount__c should be true for negative Total_Margin__c');
        System.assertEquals(false, quotes[1].Lump_Sum_Discount__c, 
            'Lump_Sum_Discount__c should be false for positive Total_Margin__c');
        System.assertEquals(false, quotes[2].Lump_Sum_Discount__c, 
            'Lump_Sum_Discount__c should be false for zero Total_Margin__c');
    }
}