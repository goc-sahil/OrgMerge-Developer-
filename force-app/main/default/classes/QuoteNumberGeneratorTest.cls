/**
 * @description Test class for QuoteNumberGenerator
 * @author Sahil Kakadiya
 * @date April 23, 2025
 */
@IsTest
private class QuoteNumberGeneratorTest {
    
    /**
     * Test setup to create organizational default for quote counter
     */
    @TestSetup
    static void setupTestData() {
        // Create custom setting for quote counter using the factory
        QuoteTestDataFactory.createQuoteCounter();
    }
    
    /**
     * Test quote number generation for non-India accounts
     */
    @IsTest
    static void testStandardQuoteNumberGeneration() {
        // Create test account and opportunity using the factory
        Account testAccount = QuoteTestDataFactory.createAccount('Test Account', 'United States');
        Opportunity testOpp = QuoteTestDataFactory.createOpportunity('Test Opportunity', testAccount.Id);
        
        // Create test quotes (not inserted yet)
        List<Quote> testQuotes = new List<Quote>{
            new Quote(
                Name = 'Test Quote 1',
                OpportunityId = testOpp.Id
            ),
            new Quote(
                Name = 'Test Quote 2',
                OpportunityId = testOpp.Id
            )
        };
        
        Test.startTest();
        QuoteNumberGenerator.generateQuoteNumbers(testQuotes);
        Test.stopTest();
        
        // Verify results
        System.assertEquals('EAC001000', testQuotes[0].Quote_Number_Constant__c, 'First quote should have number EAC001000');
        System.assertEquals('EAC001000', testQuotes[0].Quote_PDF_Version__c, 'PDF version should match quote number');
        System.assertEquals('EAC001001', testQuotes[1].Quote_Number_Constant__c, 'Second quote should have number EAC001001');
        
        // Verify custom setting was updated
        currentQuoteNumber__c updatedCounter = currentQuoteNumber__c.getOrgDefaults();
        System.assertEquals(1002, updatedCounter.currentQuoteNumber__c, 'Counter should be incremented to 1002');
    }
    
    /**
     * Test quote number generation for India accounts
     */
    @IsTest
    static void testIndiaQuoteNumberGeneration() {
        // Create test account and opportunity using the factory
        Account testAccount = QuoteTestDataFactory.createAccount('Test India Account', 'India');
        Opportunity testOpp = QuoteTestDataFactory.createOpportunity('Test India Opportunity', testAccount.Id);
        
        // Create test quotes (not inserted yet)
        List<Quote> testQuotes = new List<Quote>{
            new Quote(
                Name = 'Test India Quote 1',
                OpportunityId = testOpp.Id
            ),
            new Quote(
                Name = 'Test India Quote 2',
                OpportunityId = testOpp.Id
            )
        };
        
        Test.startTest();
        QuoteNumberGenerator.generateQuoteNumbers(testQuotes);
        Test.stopTest();
        
        // Verify results
        System.assertEquals('EAI005000', testQuotes[0].Quote_Number_Constant__c, 'First India quote should have number EAI005000');
        System.assertEquals('EAI005000', testQuotes[0].Quote_PDF_Version__c, 'PDF version should match quote number');
        System.assertEquals('EAI005001', testQuotes[1].Quote_Number_Constant__c, 'Second India quote should have number EAI005001');
        
        // Verify custom setting was updated
        currentQuoteNumber__c updatedCounter = currentQuoteNumber__c.getOrgDefaults();
        System.assertEquals(5002, updatedCounter.currentQuoteNumberIndia__c, 'India counter should be incremented to 5002');
    }
    
    /**
     * Test quote number generation with a mix of India and non-India accounts
     */
    @IsTest
    static void testMixedQuoteNumberGeneration() {
        // Create test accounts and opportunities using the factory
        Account standardAccount = QuoteTestDataFactory.createAccount('Standard Account', 'United States');
        Account indiaAccount = QuoteTestDataFactory.createAccount('India Account', 'India');
        
        Opportunity standardOpp = QuoteTestDataFactory.createOpportunity('Standard Opportunity', standardAccount.Id);
        Opportunity indiaOpp = QuoteTestDataFactory.createOpportunity('India Opportunity', indiaAccount.Id);
        
        // Create test quotes (not inserted yet)
        List<Quote> testQuotes = new List<Quote>{
            new Quote(
                Name = 'Standard Quote',
                OpportunityId = standardOpp.Id
            ),
            new Quote(
                Name = 'India Quote',
                OpportunityId = indiaOpp.Id
            )
        };
        
        Test.startTest();
        QuoteNumberGenerator.generateQuoteNumbers(testQuotes);
        Test.stopTest();
        
        // Verify results
        System.assertEquals('EAC001000', testQuotes[0].Quote_Number_Constant__c, 'Standard quote should have number EAC001000');
        System.assertEquals('EAI005000', testQuotes[1].Quote_Number_Constant__c, 'India quote should have number EAI005000');
        
        // Verify custom setting was updated
        currentQuoteNumber__c updatedCounter = currentQuoteNumber__c.getOrgDefaults();
        System.assertEquals(1001, updatedCounter.currentQuoteNumber__c, 'Standard counter should be incremented to 1001');
        System.assertEquals(5001, updatedCounter.currentQuoteNumberIndia__c, 'India counter should be incremented to 5001');
    }
    
    /**
     * Test quote number generation when opportunity has no account
     */
    @IsTest
    static void testQuoteNumberGenerationWithNoAccount() {
        // Create test opportunity with no account using the factory
        Opportunity testOpp = QuoteTestDataFactory.createOpportunity('Test Opportunity No Account', null);
        
        // Create test quote (not inserted yet)
        Quote testQuote = new Quote(
            Name = 'Test Quote No Account',
            OpportunityId = testOpp.Id
        );
        
        List<Quote> testQuotes = new List<Quote>{testQuote};
        
        Test.startTest();
        QuoteNumberGenerator.generateQuoteNumbers(testQuotes);
        Test.stopTest();
        
        // Verify results
        System.assertEquals('EAC001000', testQuote.Quote_Number_Constant__c, 'Quote with no account should default to EAC prefix');
        
        // Verify custom setting was updated
        currentQuoteNumber__c updatedCounter = currentQuoteNumber__c.getOrgDefaults();
        System.assertEquals(1001, updatedCounter.currentQuoteNumber__c, 'Counter should be incremented to 1001');
    }
    
    /**
     * Test direct call to generateNextQuoteNumber method
     */
    @IsTest
    static void testGenerateNextQuoteNumberMethod() {
        Test.startTest();
        String standardQuoteNumber = QuoteNumberGenerator.generateNextQuoteNumber('EAC', false);
        String indiaQuoteNumber = QuoteNumberGenerator.generateNextQuoteNumber('EAI', true);
        Test.stopTest();
        
        // Verify results
        System.assertEquals('EAC001000', standardQuoteNumber, 'Standard quote number should be EAC001000');
        System.assertEquals('EAI005000', indiaQuoteNumber, 'India quote number should be EAI005000');
        
        // Verify custom setting was updated
        currentQuoteNumber__c updatedCounter = currentQuoteNumber__c.getOrgDefaults();
        System.assertEquals(1001, updatedCounter.currentQuoteNumber__c, 'Standard counter should be incremented to 1001');
        System.assertEquals(5001, updatedCounter.currentQuoteNumberIndia__c, 'India counter should be incremented to 5001');
    }
    
    /**
     * Test quote number generation when CRUD permissions are insufficient
     */
    @IsTest
    static void testQuoteNumberGenerationWithInsufficientPermissions() {
        // Create a custom test user with restricted permissions using the factory
        User testUser = QuoteTestDataFactory.createRestrictedUser('tester@example.com.testorg');
        
        System.runAs(testUser) {
            // Call the method directly to test the permissions handling
            Test.startTest();
            String quoteNumber = QuoteNumberGenerator.generateNextQuoteNumber('EAC', false);
            Test.stopTest();
            
            // Verify the quote number was generated even though update might have failed
            System.assertEquals('EAC001000', quoteNumber, 'Quote number should be generated even with insufficient permissions');
        }
    }
    
    /**
     * Test using the complete test setup from the factory
     */
    // @IsTest
    // static void testUsingCompleteTestSetup() {
    //     // First reset the test data
    //     delete [SELECT Id FROM currentQuoteNumber__c];
        
    //     // Use the factory's complete test setup method
    //     Map<String, Object> testData = QuoteTestDataFactory.createCompleteTestSetup();
        
    //     // Get the quotes that were created
    //     Quote standardQuote = (Quote)testData.get('standardQuote');
    //     Quote indiaQuote = (Quote)testData.get('indiaQuote');
    //     Quote noAccountQuote = (Quote)testData.get('noAccountQuote');
        
    //     // Create new quotes for testing number generation
    //     List<Quote> testQuotes = new List<Quote>{
    //         new Quote(
    //             Name = 'New Standard Quote',
    //             OpportunityId = standardQuote.OpportunityId
    //         ),
    //         new Quote(
    //             Name = 'New India Quote',
    //             OpportunityId = indiaQuote.OpportunityId
    //         )
    //     };
        
    //     Test.startTest();
    //     QuoteNumberGenerator.generateQuoteNumbers(testQuotes);
    //     Test.stopTest();
        
    //     // Verify results
    //     System.assertEquals('EAC001000', testQuotes[0].Quote_Number_Constant__c, 'Standard quote should have number EAC001000');
    //     System.assertEquals('EAI005000', testQuotes[1].Quote_Number_Constant__c, 'India quote should have number EAI005000');
    // }
}
// @isTest
// private class QuoteNumberGeneratorTest {
//     @testSetup
//     static void setup() {
//         // Create custom setting data
//         currentQuoteNumber__c setting = new currentQuoteNumber__c(
//             Name = 'Default',
//             currentQuoteNumberIndia__c = 1,
//             currentQuoteNumber__c = 1
//         );
//         insert setting;
//     }

//     @isTest
//     static void testGenerateQuoteNumbers() {
//         // Create test data
//         Account testAccount = new Account(Name = 'Test Account', BillingCountry = 'India');
//         insert testAccount;

//         Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', AccountId = testAccount.Id, StageName = 'Closed Won', CloseDate = System.today().addMonths(1));
//         insert testOpportunity;

//         Quote testQuote = new Quote(Name = 'Test Quote', OpportunityId = testOpportunity.Id);
//         insert testQuote;

//         // Call the method to be tested
//         Test.startTest();
//         QuoteNumberGenerator.generateQuoteNumbers(new List<Quote>{testQuote});
//         Test.stopTest();

//         // Verify the generated quote number
//         testQuote = [SELECT Quote_Number_Constant__c FROM Quote WHERE Id = :testQuote.Id];
//         System.assertEquals('EAI000001', testQuote.Quote_Number_Constant__c, 'Generated quote number is incorrect');
//     }

//     @isTest
//     static void testGenerateQuoteNumbersForNonIndianAccount() {
//         // Create test data
//         Account testAccount = new Account(Name = 'Test Account', BillingCountry = 'Canada');
//         insert testAccount;

//         Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', AccountId = testAccount.Id, StageName = 'Closed Won', CloseDate = System.today().addMonths(1));
//         insert testOpportunity;

//         Quote testQuote = new Quote(Name = 'Test Quote', OpportunityId = testOpportunity.Id);
//         insert testQuote;

//         // Call the method to be tested
//         Test.startTest();
//         QuoteNumberGenerator.generateQuoteNumbers(new List<Quote>{testQuote});
//         Test.stopTest();

//         // Verify the generated quote number
//         testQuote = [SELECT Quote_Number_Constant__c FROM Quote WHERE Id = :testQuote.Id];
//         System.assertEquals('EAC000001', testQuote.Quote_Number_Constant__c, 'Generated quote number is incorrect');
//     }
// }