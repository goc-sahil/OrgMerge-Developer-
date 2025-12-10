/**
 * @description Test class for QuoteLineItem Aggregated_Total_Price__c functionality
 * Tests the calculation of parent line items' aggregated totals based on child line items
 * @author Sahil Kakadiya
 * @date December 9, 2025
 */
@isTest
private class QuoteLineItemAggregatedTotalTest {
    
    @testSetup
    static void setupTestData() {
        // Create test data using factory
        QuoteTestDataFactory.createCompleteTestSetup();
        
        // Get standard pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        // Create a test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        // Create standard pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert pbe;
        
        // Update quote with pricebook
        Quote quote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        quote.Pricebook2Id = standardPricebook.Id;
        update quote;
    }
    
    @isTest
    static void testParentWithChildrenOnInsert() {
        // Arrange
        Quote testQuote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        PricebookEntry pbe = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];
        
        // Act - Create parent line item first
        Test.startTest();
        QuoteLineItem parentQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1000
        );
        insert parentQLI;
        
        // Create child line items
        List<QuoteLineItem> childQLIs = new List<QuoteLineItem>();
        childQLIs.add(new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100,
            ParentQuoteLineItemId = parentQLI.Id
        ));
        childQLIs.add(new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 3,
            UnitPrice = 50,
            ParentQuoteLineItemId = parentQLI.Id
        ));
        insert childQLIs;
        Test.stopTest();
        
        // Assert
        QuoteLineItem updatedParent = [
            SELECT Id, Aggregated_Total_Price__c, NetTotalPrice 
            FROM QuoteLineItem 
            WHERE Id = :parentQLI.Id
        ];
        
        // Expected: (2 * 100) + (3 * 50) = 200 + 150 = 350
        Decimal expectedTotal = 350;
        System.assertEquals(expectedTotal, updatedParent.Aggregated_Total_Price__c, 
            'Parent Aggregated_Total_Price__c should be sum of children NetTotalPrice');
        
        // Verify children have 0
        List<QuoteLineItem> children = [
            SELECT Id, Aggregated_Total_Price__c 
            FROM QuoteLineItem 
            WHERE ParentQuoteLineItemId = :parentQLI.Id
        ];
        
        for (QuoteLineItem child : children) {
            System.assertEquals(0, child.Aggregated_Total_Price__c, 
                'Child Aggregated_Total_Price__c should be 0');
        }
    }
    
    @isTest
    static void testChildUpdate() {
        // Arrange
        Quote testQuote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Create parent and child
        QuoteLineItem parentQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1000
        );
        insert parentQLI;
        
        QuoteLineItem childQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100,
            ParentQuoteLineItemId = parentQLI.Id
        );
        insert childQLI;
        
        // Act - Update child's price
        Test.startTest();
        childQLI.UnitPrice = 200; // Change from 100 to 200
        update childQLI;
        Test.stopTest();
        
        // Assert
        QuoteLineItem updatedParent = [
            SELECT Id, Aggregated_Total_Price__c 
            FROM QuoteLineItem 
            WHERE Id = :parentQLI.Id
        ];
        
        // Expected: 2 * 200 = 400
        Decimal expectedTotal = 400;
        System.assertEquals(expectedTotal, updatedParent.Aggregated_Total_Price__c, 
            'Parent Aggregated_Total_Price__c should reflect updated child price');
    }
    
    @isTest
    static void testChildDelete() {
        // Arrange
        Quote testQuote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Create parent and children
        QuoteLineItem parentQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1000
        );
        insert parentQLI;
        
        List<QuoteLineItem> childQLIs = new List<QuoteLineItem>();
        childQLIs.add(new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100,
            ParentQuoteLineItemId = parentQLI.Id
        ));
        childQLIs.add(new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 3,
            UnitPrice = 50,
            ParentQuoteLineItemId = parentQLI.Id
        ));
        insert childQLIs;
        
        // Verify initial state
        QuoteLineItem initialParent = [
            SELECT Id, Aggregated_Total_Price__c 
            FROM QuoteLineItem 
            WHERE Id = :parentQLI.Id
        ];
        System.assertEquals(350, initialParent.Aggregated_Total_Price__c, 
            'Initial parent total should be 350');
        
        // Act - Delete one child
        Test.startTest();
        delete childQLIs[0]; // Deleting the 200 value item
        Test.stopTest();
        
        // Assert
        QuoteLineItem updatedParent = [
            SELECT Id, Aggregated_Total_Price__c 
            FROM QuoteLineItem 
            WHERE Id = :parentQLI.Id
        ];
        
        // Expected: Only (3 * 50) = 150 remains
        Decimal expectedTotal = 150;
        System.assertEquals(expectedTotal, updatedParent.Aggregated_Total_Price__c, 
            'Parent Aggregated_Total_Price__c should be reduced after child deletion');
    }
    
    @isTest
    static void testChildUndelete() {
        // Arrange
        Quote testQuote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Create parent and child
        QuoteLineItem parentQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1000
        );
        insert parentQLI;
        
        QuoteLineItem childQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 2,
            UnitPrice = 100,
            ParentQuoteLineItemId = parentQLI.Id
        );
        insert childQLI;
        
        // Delete the child
        delete childQLI;
        
        // Verify parent total is 0
        QuoteLineItem parentAfterDelete = [
            SELECT Id, Aggregated_Total_Price__c 
            FROM QuoteLineItem 
            WHERE Id = :parentQLI.Id
        ];
        System.assertEquals(0, parentAfterDelete.Aggregated_Total_Price__c, 
            'Parent total should be 0 after child deletion');
        
        // Act - Undelete the child
        Test.startTest();
        undelete childQLI;
        Test.stopTest();
        
        // Assert
        QuoteLineItem updatedParent = [
            SELECT Id, Aggregated_Total_Price__c 
            FROM QuoteLineItem 
            WHERE Id = :parentQLI.Id
        ];
        
        // Expected: 2 * 100 = 200
        Decimal expectedTotal = 200;
        System.assertEquals(expectedTotal, updatedParent.Aggregated_Total_Price__c, 
            'Parent Aggregated_Total_Price__c should be restored after child undelete');
    }
    
    @isTest
    static void testParentWithNoChildren() {
        // Arrange
        Quote testQuote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Act - Create parent with no children
        Test.startTest();
        QuoteLineItem parentQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1000
        );
        insert parentQLI;
        Test.stopTest();
        
        // Assert
        QuoteLineItem updatedParent = [
            SELECT Id, Aggregated_Total_Price__c 
            FROM QuoteLineItem 
            WHERE Id = :parentQLI.Id
        ];
        
        System.assertEquals(0, updatedParent.Aggregated_Total_Price__c, 
            'Parent with no children should have Aggregated_Total_Price__c = 0');
    }
    
    @isTest
    static void testChildWithoutParent() {
        // Arrange
        Quote testQuote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Act - Create standalone line item (no parent)
        Test.startTest();
        QuoteLineItem standaloneQLI = new QuoteLineItem(
            QuoteId = testQuote.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 5,
            UnitPrice = 500
        );
        insert standaloneQLI;
        Test.stopTest();
        
        // Assert
        QuoteLineItem updatedQLI = [
            SELECT Id, Aggregated_Total_Price__c 
            FROM QuoteLineItem 
            WHERE Id = :standaloneQLI.Id
        ];
        
        System.assertEquals(0, updatedQLI.Aggregated_Total_Price__c, 
            'Standalone item (no parent) should have Aggregated_Total_Price__c = 0');
    }
    
    @isTest
    static void testBulkInsertWithMultipleParents() {
        // Arrange
        Quote testQuote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry LIMIT 1];
        
        // Create multiple parents
        List<QuoteLineItem> parents = new List<QuoteLineItem>();
        for (Integer i = 0; i < 5; i++) {
            parents.add(new QuoteLineItem(
                QuoteId = testQuote.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 1000
            ));
        }
        insert parents;
        
        // Create children for each parent
        List<QuoteLineItem> children = new List<QuoteLineItem>();
        for (QuoteLineItem parent : parents) {
            children.add(new QuoteLineItem(
                QuoteId = testQuote.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 2,
                UnitPrice = 100,
                ParentQuoteLineItemId = parent.Id
            ));
            children.add(new QuoteLineItem(
                QuoteId = testQuote.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 50,
                ParentQuoteLineItemId = parent.Id
            ));
        }
        
        // Act
        Test.startTest();
        insert children;
        Test.stopTest();
        
        // Assert
        List<QuoteLineItem> updatedParents = [
            SELECT Id, Aggregated_Total_Price__c 
            FROM QuoteLineItem 
            WHERE Id IN :parents
        ];
        
        // Expected for each parent: (2 * 100) + (1 * 50) = 250
        Decimal expectedTotal = 250;
        for (QuoteLineItem parent : updatedParents) {
            System.assertEquals(expectedTotal, parent.Aggregated_Total_Price__c, 
                'Each parent should have correct aggregated total');
        }
    }
}
