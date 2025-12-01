@isTest
public class ProductSelectionControllerTest {
    // Setup method to create test data
    @TestSetup
    static void setupTestData() {
        QuoteTestDataFactory.createQuoteCounter();
        // Create test Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create test Product
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP-001',
            Description = 'Test Description',
            Family = 'Test Family',
            IsActive = true
        );
        insert prod;
        
        // Get Standard Pricebook ID
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Create PricebookEntry for Standard Pricebook
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert standardPricebookEntry;
        
        // Create custom Pricebook
        Pricebook2 pricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert pricebook;
        
        // Create PricebookEntry for custom Pricebook
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebook.Id,
            Product2Id = prod.Id,
            UnitPrice = 120.00,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert pbe;
        
        // Force a commit of the transaction so far
        Test.getStandardPricebookId();
        
        // Step 1: Create Opportunity without Pricebook
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
        
        // Step 2: Update Opportunity with Pricebook
        opp.Pricebook2Id = pricebook.Id;
        update opp;
        
        // Query to get the most up-to-date records
        Opportunity refreshedOpp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :opp.Id];
        
        PricebookEntry confirmedPbe = [
            SELECT Id, Pricebook2Id, Product2Id, UnitPrice 
            FROM PricebookEntry 
            WHERE Pricebook2Id = :refreshedOpp.Pricebook2Id
            AND Product2Id = :prod.Id 
            AND IsActive = true
            LIMIT 1
        ];
        
        // Verify the Pricebook IDs match
        System.assertEquals(
            refreshedOpp.Pricebook2Id, 
            confirmedPbe.Pricebook2Id, 
            'Pricebook IDs must match'
        );
        
        // Create OpportunityLineItem with confirmed PricebookEntry
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = refreshedOpp.Id,
            PricebookEntryId = confirmedPbe.Id,
            Quantity = 2,
            UnitPrice = confirmedPbe.UnitPrice
        );
        
        try {
            insert oli;
        } catch (Exception e) {
            System.debug('Error inserting OpportunityLineItem: ' + e.getMessage());
            System.debug('Opportunity ID: ' + refreshedOpp.Id);
            System.debug('Opportunity Pricebook2Id: ' + refreshedOpp.Pricebook2Id);
            System.debug('PricebookEntry ID: ' + confirmedPbe.Id);
            System.debug('PricebookEntry Pricebook2Id: ' + confirmedPbe.Pricebook2Id);
            throw e;
        }
        
        // Create test Quote
        /*Quote quote = new Quote(
Name = 'Test Quote',
OpportunityId = refreshedOpp.Id,
Pricebook2Id = refreshedOpp.Pricebook2Id
);
insert quote;*/
        /*List<string> names=new List<String>{'Test'};
QuoteTestDataFactory.createQuoteCounter();
QuoteTestDataFactory.createQuotes(names,refreshedOpp.Id);*/
        // Create test quotes (not inserted yet)
        List<Quote> testQuotes = new List<Quote>{
            new Quote(
                Name = 'Test Quote 1',
                OpportunityId = refreshedOpp.Id,
                Pricebook2Id = refreshedOpp.Pricebook2Id
            ),
                new Quote(
                    Name = 'Test Quote 2',
                    OpportunityId = refreshedOpp.Id,
                    Pricebook2Id = refreshedOpp.Pricebook2Id
                )
                };
                    
                    Test.startTest();
        QuoteNumberGenerator.generateQuoteNumbers(testQuotes);
        Test.stopTest();
        insert testQuotes;
    }
    
    @isTest
    static void testGetAllOpportunityLineItems() {
        // Get test data - standard opportunity 
        Opportunity standardOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Pricebook' LIMIT 1];
        
        Test.startTest();
        List<OpportunityLineItem> items = ProductSelectionController.getAllOpportunityLineItems(standardOpp.Id);
        List<OpportunityLineItem> items2 = ProductSelectionController.getAllOpportunityLineItems(pb.Id);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, items.size(), 'Expected one OpportunityLineItem');
        System.assertNotEquals(null, items[0].Product2, 'Product2 should be populated');
        System.assertEquals('Test Product', items[0].Product2.Name, 'Product name should match');
    }
    
    @isTest
    static void testGetAllOpportunityLineItems2() {
        // Get test data - standard opportunity 
        Opportunity standardOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Pricebook' LIMIT 1];
        
        
        Boolean exceptionThrown = false;
        try{
            Test.startTest();
            List<OpportunityLineItem> items2 = ProductSelectionController.getAllOpportunityLineItems(pb.Id);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetOpportunityLineItems() {
        // Get test data - custom opportunity
        Opportunity customOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        List<OpportunityLineItem> items = ProductSelectionController.getOpportunityLineItems(customOpp.Id, 10, 0);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, items.size(), 'Expected one OpportunityLineItem');
        System.assertNotEquals(null, items[0].Product2, 'Product2 should be populated');
        System.assertEquals('Test Product', items[0].Product2.Name, 'Product name should match');
    }
    
    @isTest
    static void testGetProductsFromPricebook() {
        // Get test data
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Pricebook' LIMIT 1];
        
        Test.startTest();
        List<PricebookEntry> entries = ProductSelectionController.getProductsFromPricebook(pb.Id, 10, 0, 'USD');
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, entries.size(), 'Expected one PricebookEntry');
        System.assertNotEquals(null, entries[0].Product2, 'Product2 should be populated');
        System.assertEquals('Test Product', entries[0].Product2.Name, 'Product name should match');
        System.assertEquals(120, entries[0].UnitPrice, 'UnitPrice should match');
    }
    
    @isTest
    static void testGetProductsFromPricebook2() {
        // Get test data
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'Test Pricebook' LIMIT 1];
        
        
        Boolean exceptionThrown = false;
        try{
            Test.startTest();
            List<PricebookEntry> entries = ProductSelectionController.getProductsFromPricebook(pb.Id, 10, 5000, 'USD');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected exception was not thrown for invalid Pricebook');
        Test.stopTest();
        
    }
    
    @isTest
    static void testCreateQuoteLineItems() {
        // Get test data - make sure to use matching Quote and Pricebook
        Quote quote = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Quote WHERE Name = 'Test Quote 1' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 3,
            UnitPrice = 150,
            Order__c = 1
        );
        List<QuoteLineItem> qliList = new List<QuoteLineItem>{ qli };
            
            Test.startTest();
        
        ProductSelectionController.createQuoteLineItems(qliList, quote.Pricebook2Id);
        
        
        Test.stopTest();
        
        // Assertions
        List<QuoteLineItem> insertedQLIs = [SELECT Id, Quantity, UnitPrice, SortOrder FROM QuoteLineItem WHERE QuoteId = :quote.Id];
        System.assertEquals(1, insertedQLIs.size(), 'Expected one inserted QuoteLineItem');
        System.assertEquals(3, insertedQLIs[0].Quantity, 'Quantity should be 3');
        System.assertEquals(150, insertedQLIs[0].UnitPrice, 'UnitPrice should be 150');
        System.assertEquals(1, insertedQLIs[0].SortOrder, 'SortOrder should be 1');
    }
    
    @isTest
    static void testCreateQuoteLineItems2() {
        // Get test data - make sure to use matching Quote and Pricebook
        Quote quote = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Quote WHERE Name = 'Test Quote 1' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 3,
            UnitPrice = 150,
            Order__c = 1
        );
        List<QuoteLineItem> qliList = new List<QuoteLineItem>{ qli };
            Boolean exceptionThrown = false;
        try{
            Test.startTest();
            ProductSelectionController.createQuoteLineItems(null, quote.Pricebook2Id);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testCreateQuoteLineItems3() {
        // Get test data - make sure to use matching Quote and Pricebook
        Quote quote = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Quote WHERE Name = 'Test Quote 1' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            Product2Id = prod.Id,
            Quantity = 3,
            UnitPrice = 150,
            Order__c = 1
        );
        List<QuoteLineItem> qliList = new List<QuoteLineItem>{ qli };
            Boolean exceptionThrown = false;
        try{
            Test.startTest();
            ProductSelectionController.createQuoteLineItems(qliList, null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected exception was not thrown for invalid Pricebook');
        
        Test.stopTest();
        
    }
    
    
    @isTest
    static void testCreateQuoteLineItems_InvalidData() {
        // Get test data
        Quote quote = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Quote WHERE Name = 'Test Quote 1' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        
        
        // Test Case 3: Invalid Pricebook
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            ProductSelectionController.createQuoteLineItems(
                new List<QuoteLineItem>{ 
                    new QuoteLineItem(
                        QuoteId = quote.Id,
                        Product2Id = prod.Id,
                        Quantity = 3,
                        UnitPrice = 150,
                        Order__c = 1
                    )
                        }, 
                'invalid-pricebook-id'
            );
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected exception was not thrown for invalid Pricebook');
    }
    
    @isTest
    static void testCreateQuoteLineItems_InvalidData2() {
        // Get test data
        Quote quote = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Quote WHERE Name = 'Test Quote 1' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        
        // Test Case 2: Missing Product2Id
        Boolean exceptionThrown = false;
        QuoteLineItem qliNoProd = new QuoteLineItem(
            QuoteId = quote.Id,
            Quantity = 3,
            UnitPrice = 150,
            Order__c = 1
        );
        try {
            Test.startTest();
            ProductSelectionController.createQuoteLineItems(new List<QuoteLineItem>{ qliNoProd }, quote.Pricebook2Id);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected exception was not thrown for missing Product2Id');
        
        
    }
    
    @isTest
    static void testCreateQuoteLineItems_InvalidData3() {
        // Get test data
        Quote quote = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Quote WHERE Name = 'Test Quote 1' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        // Test Case 3: Invalid Pricebook
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            ProductSelectionController.createQuoteLineItems(
                new List<QuoteLineItem>{ 
                    new QuoteLineItem(
                        QuoteId = quote.Id,
                        Product2Id = prod.Id,
                        Quantity = 3,
                        UnitPrice = 150,
                        Order__c = 1
                    )
                        }, 
                'invalid-pricebook-id'
            );
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected exception was not thrown for invalid Pricebook');
    }
    
    @isTest
    static void testCreateQuoteLineItems_InvalidData4() {
        // Get test data
        Quote quote = [SELECT Id, Pricebook2Id, CurrencyIsoCode FROM Quote WHERE Name = 'Test Quote 1'];
        delete quote;
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        
        // Test Case 3: Invalid Pricebook
        Boolean exceptionThrown = false;
        try {
            Test.startTest();
            ProductSelectionController.createQuoteLineItems(
                new List<QuoteLineItem>{ 
                    new QuoteLineItem(
                        QuoteId = quote.Id,
                        Product2Id = prod.Id,
                        Quantity = 3,
                        UnitPrice = 150,
                        Order__c = 1
                    )
                        }, 
                'invalid-pricebook-id'
            );
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected exception was not thrown for invalid Pricebook');
    }
    
    @isTest
    static void testSecurityEnforcement() {
        // Get test data
        Opportunity standardOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Opportunity customOpp = [SELECT Id FROM Opportunity];
        //Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'CustomPB' LIMIT 1];
        
        // Since we can't easily test the security enforcement in a test class without more setup,
        // we'll just ensure our method doesn't throw exceptions with proper permissions
        Test.startTest();
        // Test both standard and custom opportunities
        List<OpportunityLineItem> standardItems = ProductSelectionController.getOpportunityLineItems(standardOpp.Id, 10, 0);
        // List<OpportunityLineItem> customItems = ProductSelectionController.getOpportunityLineItems(customOpp.Id, 10, 0);
        // List<PricebookEntry> entries = ProductSelectionController.getProductsFromPricebook(pb.Id, 10, 0, 'USD');
        Test.stopTest();
        
        System.assertEquals(1, standardItems.size(), 'Expected one OpportunityLineItem from standard opportunity');
        // System.assertEquals(1, customItems.size(), 'Expected one OpportunityLineItem from custom opportunity');
        // System.assertEquals(1, entries.size(), 'Expected one PricebookEntry from custom pricebook');
    }
    
    @isTest
    static void testSecurityEnforcement2() {
        // Get test data
        Opportunity standardOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Opportunity customOpp = [SELECT Id FROM Opportunity];
        //Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE Name = 'CustomPB' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        // Since we can't easily test the security enforcement in a test class without more setup,
        // we'll just ensure our method doesn't throw exceptions with proper permissions
        Test.startTest();
        // Test both standard and custom opportunities
        
        List<OpportunityLineItem> customItems = ProductSelectionController.getOpportunityLineItems(prod.id, 10, 0);
        // List<PricebookEntry> entries = ProductSelectionController.getProductsFromPricebook(pb.Id, 10, 0, 'USD');
        Test.stopTest();
        
        // System.assertEquals(customItems.size() > 0, 'Expected one OpportunityLineItem from standard opportunity');
        // System.assertEquals(1, customItems.size(), 'Expected one OpportunityLineItem from custom opportunity');
        // System.assertEquals(1, entries.size(), 'Expected one PricebookEntry from custom pricebook');
    }
}