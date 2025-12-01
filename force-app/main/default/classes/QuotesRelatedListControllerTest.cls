@isTest
private class QuotesRelatedListControllerTest {
    @isTest
    static void testGetRelatedQuotes() {
        // Create the 'currentQuoteNumber__c' record if it doesn't exist
        if ([SELECT COUNT() FROM currentQuoteNumber__c] == 0) {
            currentQuoteNumber__c quoteCounter = new currentQuoteNumber__c(
                currentQuoteNumber__c = 1,
                currentQuoteNumberIndia__c = 1
            );
            insert quoteCounter;
        }

        // Create test Account and Opportunity
        Account testAccount = new Account(Name = 'Test Account', BillingCountry = 'India');
        insert testAccount;
        
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', AccountId = testAccount.Id, StageName = 'Prospecting', CloseDate = Date.today());
        insert testOpportunity;

        // Create several Quote records for the Opportunity
        List<Quote> testQuotes = new List<Quote>();
        for (Integer i = 0; i < 6; i++) {
            Quote testQuote = new Quote(OpportunityId = testOpportunity.Id, Name = 'Test Quote ' + i);
            testQuotes.add(testQuote);
        }
        insert testQuotes;

        // Now, test your controller method
        Test.startTest();
        List<Quote> relatedQuotes = QuotesRelatedListController.getRelatedQuotes(testOpportunity.Id);
        Test.stopTest();

        // Debugging the retrieved Quote records
        System.debug('Related Quotes: ' + relatedQuotes);
        
        // Assertions to verify the expected behavior
        System.assertNotEquals(relatedQuotes.size(), 0, 'No quotes were returned');
        
        // Check if the first quote is correctly related to the test opportunity
        System.assertEquals(relatedQuotes[0].OpportunityId, testOpportunity.Id, 'The first related quote is not linked to the correct Opportunity');
    }
}