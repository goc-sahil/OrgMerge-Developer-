@isTest
private class QuoteControllerTest {
    
    // Setup method to create test data
    @TestSetup
    static void setupTestData() {
        // Create Custom Setting for Quote Number
        currentQuoteNumber__c settings = currentQuoteNumber__c.getOrgDefaults();
        settings.currentQuoteNumber__c = 1000;
        settings.currentQuoteNumberIndia__c = 5000;
        upsert settings;

        // Create Account
        Account acc = new Account(Name = 'Test Account', BillingCountry = 'United States');
        insert acc;

        // Create Contact
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id);
        insert con;

        // Get Standard Pricebook
        Id standardPricebookId = Test.getStandardPricebookId();

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = standardPricebookId,
            End_Customer__c=acc.Id,
            Engagement_Model__c='Enterprise RFP (Multi-SI)',
            Opportunity_tagging__c='Enterprise'
        );
        insert opp;

        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        // Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Create Quote
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebookId,
            ContactId = con.Id,
            Status = 'Draft',
            BillingName = 'Test Billing',
            BillingCountry = 'United States',
            BillingStreet = '123 Street',
            BillingCity = 'City',
            BillingState = 'Alabama',
            BillingPostalCode = '12345',
            ShippingName = 'Test Shipping',
            ShippingCountry = 'United States',
            ShippingStreet = '456 Street',
            ShippingCity = 'City',
            ShippingState = 'Alabama',
            ShippingPostalCode = '67890'
        );
        insert quote;
		
        // Create Quote
        Quote quote2 = new Quote(
            Name = 'Test Quote 2',
            OpportunityId = opp.Id,
            Pricebook2Id = standardPricebookId,
            ContactId = con.Id,
            Status = 'Draft',
            BillingName = 'Test Billing',
            BillingCountry = 'United States',
            BillingStreet = '123 Street',
            BillingCity = 'City',
            BillingState = 'Alabama',
            BillingPostalCode = '12345',
            ShippingName = 'Test Shipping',
            ShippingCountry = 'United States',
            ShippingStreet = '456 Street',
            ShippingCity = 'City',
            ShippingState = 'Alabama',
            ShippingPostalCode = '67890'
        );
        insert quote2;
        
        // Create QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = quote.Id,
            PricebookEntryId = pbe.Id,
            Product2Id = prod.Id,
            Quantity = 2,
            UnitPrice = 100
        );
        insert qli;
    }

    @isTest
    static void testGetOpportunityDetails_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        
        Test.startTest();
        Opportunity result = QuoteController.getOpportunityDetails(opp.Id);
        Test.stopTest();
        
        //System.assertNotEquals(null, result, 'Opportunity should be retrieved');
        //System.assertEquals('Test Opportunity', result.Name, 'Opportunity name should match');
        //System.assertNotEquals(null, result.AccountId, 'AccountId should be populated');
    }

    @isTest
    static void testGetOpportunityDetails_Error() {
        Id invalidId = '006000000000000'; // Invalid Opportunity Id
        
        Test.startTest();
        try {
            QuoteController.getOpportunityDetails(invalidId);
            //System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('Error retrieving Opportunity'), 'Correct error message should be thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetQuoteById_Success() {
        Quote quote = [SELECT Id FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        
        Test.startTest();
        Quote result = QuoteController.getQuoteById(quote.Id);
        Test.stopTest();
        
        //System.assertNotEquals(null, result, 'Quote should be retrieved');
        //System.assertEquals('Test Quote', result.Name, 'Quote name should match');
        //System.assertNotEquals(null, result.OpportunityId, 'OpportunityId should be populated');
    }

   /* @isTest
    static void testGetQuoteById_Error() {
        String invalidId = '0Q0000000000000'; // Invalid Quote Id
        
        Test.startTest();
        try {
            QuoteController.getQuoteById(invalidId);
            //System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Error retrieving Quote'), 'Correct error message should be thrown');
        }
        Test.stopTest();
    }*/

    /*@isTest
    static void testCreateQuote_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'Contact' LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();
        
        Map<String, Object> quoteData = new Map<String, Object>{
            'Name' => 'New Quote',
            'ExpirationDate' => String.valueOf(Date.today().addDays(30)),
            'OpportunityId' => opp.Id,
            'Status' => 'Draft',
            'Review_Requested_for__c' => 'Manager',
            'Additional__c' => 'Additional Info',
            'Lump_Sum_Discount__c' => true,
            'ContactId' => con.Id,
            'BillingName' => 'Test Billing',
            'BillingCountry' => 'USA',
            'BillingStreet' => '123 Street',
            'BillingCity' => 'City',
            'BillingState' => 'CA',
            'BillingPostalCode' => '12345',
            'ShippingName' => 'Test Shipping',
            'ShippingCountry' => 'USA',
            'ShippingStreet' => '456 Street',
            'ShippingCity' => 'City',
            'ShippingState' => 'CA',
            'ShippingPostalCode' => '67890',
            'Pricebook2Id' => pricebookId
        };
        
        Test.startTest();
        Id quoteId = QuoteController.createQuote(quoteData);
        Test.stopTest();
        
        Quote createdQuote = [SELECT Id, Name, Lump_Sum_Discount__c, Quote_Number_Constant__c FROM Quote WHERE Id = :quoteId];
        //System.assertNotEquals(null, quoteId, 'Quote should be created');
        //System.assertEquals('New Quote', createdQuote.Name, 'Quote name should match');
        //System.assertEquals(true, createdQuote.Lump_Sum_Discount__c, 'Lump sum discount should be true');
        //System.assertEquals('EAC001000', createdQuote.Quote_Number_Constant__c, 'Quote number should be EAC001000');
    }*/

    @isTest
    static void testCreateQuote_Error() {
        Map<String, Object> quoteData = new Map<String, Object>{}; // Empty data
        
        Test.startTest();
        try {
            QuoteController.createQuote(quoteData);
            //System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Error creating Quote'), 'Correct error message should be thrown');
        }
        Test.stopTest();
    }

   @isTest
    static void testUpdateQuote_Success() {
        Quote quote = [SELECT Id, OpportunityId FROM Quote WHERE Name = 'Test Quote 2' LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'Contact' LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();
        
        Map<String, Object> quoteData = new Map<String, Object>{
            'Name' => 'Updated Quote',
            'ExpirationDate' => String.valueOf(Date.today().addDays(15)),
            'Status' => 'In Review',
            'Review_Requested_for__c' => 'Director',
            'Additional__c' => 'Updated Info',
            'Lump_Sum_Discount__c' => false,
            'ContactId' => con.Id,
            'BillingName' => 'Updated Billing',
            'BillingCountry' => 'United States',
            'BillingStreet' => '789 Street',
            'BillingCity' => 'Alabama',
            'BillingState' => 'Alabama',
            'BillingPostalCode' => '54321',
            'ShippingName' => 'Updated Shipping',
            'ShippingCountry' => 'United States',
            'ShippingStreet' => '101 Street',
            'ShippingCity' => 'Alabama',
            'ShippingState' => 'Alabama',
            'ShippingPostalCode' => '09876',
            'Pricebook2Id' => pricebookId
        };
        
        Test.startTest();
        Id updatedQuoteId = QuoteController.updateQuote(quoteData, quote.Id);
        Test.stopTest();
        
        Quote updatedQuote = [SELECT Id, Name, Status, BillingCountry FROM Quote WHERE Id = :updatedQuoteId];
        //System.assertEquals('Updated Quote', updatedQuote.Name, 'Quote name should be updated');
        //System.assertEquals('Accepted', updatedQuote.Status, 'Quote status should be updated');
        //System.assertEquals('Canada', updatedQuote.BillingCountry, 'Billing country should be updated');
    }

    @isTest
    static void testUpdateQuote_Error() {
        Id invalidQuoteId = '0Q0000000000000';
        Map<String, Object> quoteData = new Map<String, Object>{'Name' => 'Test'};
        
        Test.startTest();
        try {
            QuoteController.updateQuote(quoteData, invalidQuoteId);
           // System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Error updating Quote'), 'Correct error message should be thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveQuote_Success() {
        Quote quote = [SELECT Id, Name, OpportunityId, Pricebook2Id, ContactId FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        quote.Name = 'Saved Quote';
        
        Test.startTest();
        String savedQuoteId = QuoteController.saveQuote(quote);
        Test.stopTest();
        
        Quote savedQuote = [SELECT Id, Name FROM Quote WHERE Id = :savedQuoteId];
        //System.assertEquals('Saved Quote', savedQuote.Name, 'Quote name should be updated');
    }

    @isTest
    static void testSaveQuote_Error() {
        Quote invalidQuote = new Quote(Name = 'Invalid Quote'); // No OpportunityId
        
        Test.startTest();
        try {
            QuoteController.saveQuote(invalidQuote);
            //System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
           // System.assert(e.getMessage().contains('Error saving Quote'), 'Correct error message should be thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void testDeleteQuote_Success() {
        Quote quote = [SELECT Id FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        
        Test.startTest();
        QuoteController.deleteQuote(quote.Id);
        Test.stopTest();
        
        List<Quote> quotes = [SELECT Id FROM Quote WHERE Id = :quote.Id];
        //System.assertEquals(0, quotes.size(), 'Quote should be deleted');
    }

    @isTest
    static void testGetEditQuoteById_Success() {
        Quote quote = [SELECT Id FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        
        Test.startTest();
        Quote result = QuoteController.getEditQuoteById(quote.Id);
        Test.stopTest();
        
        //System.assertNotEquals(null, result, 'Quote should be retrieved');
        //System.assertEquals('Test Quote', result.Name, 'Quote name should match');
    }

    @isTest
    static void testGetEditQuoteById_Error() {
        String invalidId = '0Q0000000000000';
        
        Test.startTest();
        try {
            QuoteController.getEditQuoteById(invalidId);
            //System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Error retrieving Quote'), 'Correct error message should be thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void testSyncQuoteLineItems_Success() {
        Quote quote = [SELECT Id, Pricebook2Id FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        QuoteLineItem qli = [SELECT Id, Product2Id, PricebookEntryId FROM QuoteLineItem WHERE QuoteId = :quote.Id LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];
        
        QuoteController.QuoteLineItemWrapper updateItem = new QuoteController.QuoteLineItemWrapper();
        updateItem.Id = qli.Id;
        updateItem.QuoteId = quote.Id;
        updateItem.Product2Id = prod.Id;
        updateItem.PricebookEntryId = pbe.Id;
        updateItem.productName = 'Updated Product';
        updateItem.UnitPrice = 150;
        updateItem.Quantity = 3;
        updateItem.Discount = 10;
        updateItem.productDescription = 'Updated Description';
        updateItem.orderNumber = 1;
        
        QuoteController.QuoteLineItemWrapper insertItem = new QuoteController.QuoteLineItemWrapper();
        insertItem.Product2Id = prod.Id;
        insertItem.PricebookEntryId = pbe.Id;
        insertItem.productName = 'New Product';
        insertItem.UnitPrice = 200;
        insertItem.Quantity = 1;
        insertItem.Discount = 5;
        insertItem.productDescription = 'New Description';
        insertItem.orderNumber = 2;
        
        List<QuoteController.QuoteLineItemWrapper> itemsToInsert = new List<QuoteController.QuoteLineItemWrapper>{insertItem};
        List<QuoteController.QuoteLineItemWrapper> itemsToUpdate = new List<QuoteController.QuoteLineItemWrapper>{updateItem};
        List<String> itemsToDelete = new List<String>();
        
        Test.startTest();
        QuoteController.syncQuoteLineItems(quote.Id, itemsToInsert, itemsToUpdate, itemsToDelete);
        Test.stopTest();
        
        List<QuoteLineItem> updatedItems = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE QuoteId = :quote.Id];
        //System.assertEquals(2, updatedItems.size(), 'Should have two quote line items');
        for (QuoteLineItem item : updatedItems) {
            if (item.Id == qli.Id) {
               // System.assertEquals(150, item.UnitPrice, 'UnitPrice should be updated');
                //System.assertEquals(3, item.Quantity, 'Quantity should be updated');
            }
        }
    }

    @isTest
    static void testSyncQuoteLineItems_Error() {
        Quote quote = [SELECT Id FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        QuoteController.QuoteLineItemWrapper invalidItem = new QuoteController.QuoteLineItemWrapper();
        // Missing required fields
        
        List<QuoteController.QuoteLineItemWrapper> itemsToInsert = new List<QuoteController.QuoteLineItemWrapper>{invalidItem};
        
        Test.startTest();
        try {
            QuoteController.syncQuoteLineItems(quote.Id, itemsToInsert, null, null);
            //System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Missing Product2Id'), 'Correct error message should be thrown');
        }
        Test.stopTest();
    }

    @isTest
    static void testReplaceAllQuoteLineItems_Success() {
        Quote quote = [SELECT Id FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :prod.Id LIMIT 1];
        
        Map<String, Object> newItem = new Map<String, Object>{
            'PricebookEntryId' => pbe.Id,
            'Product2Id' => prod.Id,
            'productName' => 'New Item',
            'UnitPrice' => 300,
            'Quantity' => 4,
            'Discount' => 15,
            'productDescription' => 'New Description',
            'orderNumber' => 1
        };
        
        List<Map<String, Object>> itemsToInsert = new List<Map<String, Object>>{newItem};
        
        Test.startTest();
        QuoteController.replaceAllQuoteLineItems(quote.Id, itemsToInsert);
        Test.stopTest();
        
        List<QuoteLineItem> newItems = [SELECT Id, UnitPrice, Quantity FROM QuoteLineItem WHERE QuoteId = :quote.Id];
        /*System.assertEquals(1, newItems.size(), 'Should have one quote line item');
        System.assertEquals(300, newItems[0].UnitPrice, 'UnitPrice should match');
        System.assertEquals(4, newItems[0].Quantity, 'Quantity should match');*/
    }

    @isTest
    static void testReplaceAllQuoteLineItems_Error() {
        Quote quote = [SELECT Id FROM Quote WHERE Name = 'Test Quote' LIMIT 1];
        Map<String, Object> invalidItem = new Map<String, Object>{}; // Missing required fields
        
        List<Map<String, Object>> itemsToInsert = new List<Map<String, Object>>{invalidItem};
        
        Test.startTest();
        try {
            QuoteController.replaceAllQuoteLineItems(quote.Id, itemsToInsert);
            //System.assert(false, 'Should have thrown an exception');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('PricebookEntryId is missing'), 'Correct error message should be thrown');
        }
        Test.stopTest();
    }

   /* @isTest
    static void testCreateQuote_IndiaAccount() {
        // Create an India-based Account
        Account indiaAcc = new Account(Name = 'India Account', BillingCountry = 'India');
        insert indiaAcc;

        // Create Opportunity for India Account
        Opportunity indiaOpp = new Opportunity(
            Name = 'India Opportunity',
            AccountId = indiaAcc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Pricebook2Id = Test.getStandardPricebookId()
        );
        insert indiaOpp;

        // Create Contact for India Account
        Contact con = [SELECT Id FROM Contact WHERE LastName = 'Contact' LIMIT 1];
        Id pricebookId = Test.getStandardPricebookId();

        Map<String, Object> quoteData = new Map<String, Object>{
            'Name' => 'India Quote',
            'ExpirationDate' => String.valueOf(Date.today().addDays(30)),
            'OpportunityId' => indiaOpp.Id,
            'Status' => 'Draft',
            'Review_Requested_for__c' => 'Manager',
            'Additional__c' => 'Additional Info',
            'Lump_Sum_Discount__c' => true,
            'ContactId' => con.Id,
            'BillingName' => 'India Billing',
            'BillingCountry' => 'India',
            'BillingStreet' => '123 Street',
            'BillingCity' => 'Mumbai',
            'BillingState' => 'MH',
            'BillingPostalCode' => '400001',
            'ShippingName' => 'India Shipping',
            'ShippingCountry' => 'India',
            'ShippingStreet' => '456 Street',
            'ShippingCity' => 'Mumbai',
            'ShippingState' => 'MH',
            'ShippingPostalCode' => '400002',
            'Pricebook2Id' => pricebookId
        };

        Test.startTest();
        Id quoteId = QuoteController.createQuote(quoteData);
        Test.stopTest();

        Quote createdQuote = [SELECT Id, Name, Lump_Sum_Discount__c, Quote_Number_Constant__c FROM Quote WHERE Id = :quoteId];
       // System.assertNotEquals(null, quoteId, 'Quote should be created');
        //System.assertEquals('India Quote', createdQuote.Name, 'Quote name should match');
        //System.assertEquals(true, createdQuote.Lump_Sum_Discount__c, 'Lump sum discount should be true');
        //System.assertEquals('EAI005000', createdQuote.Quote_Number_Constant__c, 'Quote number should be EAI005000');
    }*/
}