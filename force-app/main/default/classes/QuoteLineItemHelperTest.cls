@isTest
private class QuoteLineItemHelperTest {
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
        }
        
        @isTest
        static void testUpdateQuoteTotals_SingleQuoteWithMultipleLineItems() {
            // Arrange
            Quote testQuote = [SELECT Id, OpportunityId FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
            Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :testQuote.OpportunityId LIMIT 1];
            PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :opp.Pricebook2Id LIMIT 1];
            
            // Create test quote line items
            List<QuoteLineItem> lineItems = new List<QuoteLineItem>();
            lineItems.add(new QuoteLineItem(
                QuoteId = testQuote.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100.00
            ));
            lineItems.add(new QuoteLineItem(
                QuoteId = testQuote.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100.00
            ));
            insert lineItems;
            
            // Act
            Test.startTest();
            QuoteLineItemHelper.updateQuoteTotals(new Set<Id>{testQuote.Id});
            Test.stopTest();
            
            // Assert
            Quote updatedQuote = [SELECT Total_Discounts__c, Quote_Margin__c 
                                FROM Quote 
                                WHERE Id = :testQuote.Id];
            // Replace with expected values based on your Discount__c and Margin__c formula logic
            Decimal expectedDiscount = 0.00; // Update with sum of formula-based Discount__c values
            Decimal expectedMargin = 0.00;  // Update with sum of formula-based Margin__c values
            System.assertEquals(expectedDiscount, updatedQuote.Total_Discounts__c, 
                'Total Discounts should match formula-based sum');
            System.assertEquals(expectedMargin, updatedQuote.Quote_Margin__c, 
                'Total Margin should match formula-based sum');
        }
        
        @isTest
        static void testUpdateQuoteTotals_QuoteWithNoLineItems() {
            // Arrange
            Quote testQuote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
            
            // Act
            Test.startTest();
            QuoteLineItemHelper.updateQuoteTotals(new Set<Id>{testQuote.Id});
            Test.stopTest();
            
            // Assert
            Quote updatedQuote = [SELECT Total_Discounts__c, Quote_Margin__c 
                                FROM Quote 
                                WHERE Id = :testQuote.Id];
            System.assertEquals(null, updatedQuote.Total_Discounts__c, 
                'Total Discounts should be null for quote with no line items');
            System.assertEquals(null, updatedQuote.Quote_Margin__c, 
                'Total Margin should be null for quote with no line items');
        }
        
        @isTest
        static void testUpdateQuoteTotals_BulkQuotes() {
            // Arrange
            Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity 
                            WHERE Name = 'Standard Test Opportunity' LIMIT 1];
            PricebookEntry pbe = [SELECT Id FROM PricebookEntry 
                                WHERE Pricebook2Id = :opp.Pricebook2Id LIMIT 1];
            
            // Create multiple quotes
            List<Quote> quotes = QuoteTestDataFactory.createQuotes(
                new List<String>{'Bulk Quote 1', 'Bulk Quote 2', 'Bulk Quote 3'},
                opp.Id
            );
            
            // Update quotes with pricebook
            for (Quote q : quotes) {
                q.Pricebook2Id = opp.Pricebook2Id;
            }
            update quotes;
            
            // Create quote line items for each quote
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
            
            // Act
            Test.startTest();
            QuoteLineItemHelper.updateQuoteTotals(new Set<Id>{quotes[0].Id, quotes[1].Id, quotes[2].Id});
            Test.stopTest();
            
            // Assert
            // Replace with expected values based on your Discount__c and Margin__c formula logic
            Decimal expectedDiscount = 0.00; // Update with formula-based Discount__c value
            Decimal expectedMargin = 0.00;  // Update with formula-based Margin__c value
            for (Quote q : [SELECT Total_Discounts__c, Quote_Margin__c 
                        FROM Quote 
                        WHERE Id IN :quotes]) {
                System.assertEquals(expectedDiscount, q.Total_Discounts__c, 
                    'Total Discounts should match formula-based value');
                System.assertEquals(expectedMargin, q.Quote_Margin__c, 
                    'Total Margin should match formula-based value');
            }
        }
        
        @isTest
        static void testUpdateQuoteTotals_NullValues() {
            // Arrange
            Quote testQuote = [SELECT Id, OpportunityId FROM Quote 
                            WHERE Name = 'Standard Test Quote' LIMIT 1];
            Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity 
                            WHERE Id = :testQuote.OpportunityId LIMIT 1];
            PricebookEntry pbe = [SELECT Id FROM PricebookEntry 
                                WHERE Pricebook2Id = :opp.Pricebook2Id LIMIT 1];
            
            // Create quote line item
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = testQuote.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100.00
            );
            insert qli;
            
            // Act
            Test.startTest();
            QuoteLineItemHelper.updateQuoteTotals(new Set<Id>{testQuote.Id});
            Test.stopTest();
            
            // Assert
            Quote updatedQuote = [SELECT Total_Discounts__c, Quote_Margin__c 
                                FROM Quote 
                                WHERE Id = :testQuote.Id];
            // Replace with expected values based on your Discount__c and Margin__c formula logic
            Decimal expectedDiscount = 0.00; // Update with formula-based Discount__c value
            Decimal expectedMargin = 0.00;  // Update with formula-based Margin__c value
            System.assertEquals(expectedDiscount, updatedQuote.Total_Discounts__c, 
                'Total Discounts should match formula-based value');
            System.assertEquals(expectedMargin, updatedQuote.Quote_Margin__c, 
                'Total Margin should match formula-based value');
        }
        
        @isTest
        static void testTriggerAfterDelete() {
            // Arrange
            Quote testQuote = [SELECT Id, OpportunityId FROM Quote 
                            WHERE Name = 'Standard Test Quote' LIMIT 1];
            Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity 
                            WHERE Id = :testQuote.OpportunityId LIMIT 1];
            PricebookEntry pbe = [SELECT Id FROM PricebookEntry 
                                WHERE Pricebook2Id = :opp.Pricebook2Id LIMIT 1];
            
            // Create quote line item
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = testQuote.Id,
                PricebookEntryId = pbe.Id,
                Quantity = 1,
                UnitPrice = 100.00
            );
            insert qli;
            
            // Act
            Test.startTest();
            delete qli;
            Test.stopTest();
            
            // Assert
            Quote updatedQuote = [SELECT Total_Discounts__c, Quote_Margin__c 
                                FROM Quote 
                                WHERE Id = :testQuote.Id];
            // Since the only line item was deleted, expect totals to be 0
            // Replace with expected values based on your Discount__c and Margin__c formula logic
            Decimal expectedDiscount = 0.00; // Update based on formula logic after deletion
            Decimal expectedMargin = 0.00;  // Update based on formula logic after deletion
            System.assertEquals(expectedDiscount, updatedQuote.Total_Discounts__c, 
                'Total Discounts should be 0 after line item deletion');
            System.assertEquals(expectedMargin, updatedQuote.Quote_Margin__c, 
                'Total Margin should be 0 after line item deletion');
        }
    

}