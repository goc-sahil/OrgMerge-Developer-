/**
 * @description Test Data Factory class to create test data for Quote related test classes
 * @author Sahil Kakadiya
 * @date April 23, 2025
 */
public class QuoteTestDataFactory {
    
    /**
     * Create custom setting for quote counter with default values
     * @return currentQuoteNumber__c The created custom setting instance
     */
    public static currentQuoteNumber__c createQuoteCounter() {
        currentQuoteNumber__c quoteCounter = new currentQuoteNumber__c();
        quoteCounter.currentQuoteNumber__c = 1000;
        quoteCounter.currentQuoteNumberIndia__c = 5000;
        quoteCounter.SetupOwnerId = UserInfo.getOrganizationId();
        upsert quoteCounter;
        return quoteCounter;
    }
    
    /**
     * Create a test account with specified country
     * @param name The account name
     * @param country The billing country
     * @return Account The created test account
     */
    public static Account createAccount(String name, String country) {
        Account testAccount = new Account(
            Name = name,
            BillingCountry = country,
            Type = 'System Integrator'
        );
        insert testAccount;
        return testAccount;
    }
    
    /**
     * Create a test opportunity
     * @param name The opportunity name
     * @param accountId The account ID (optional)
     * @return Opportunity The created test opportunity
     */
    public static Opportunity createOpportunity(String name, Id accountId) {
        Opportunity testOpp = new Opportunity(
            Name = name,
            AccountId = accountId, // Can be null
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert testOpp;
        return testOpp;
    }
    
    /**
     * Create a test quote
     * @param name The quote name
     * @param opportunityId The opportunity ID
     * @return Quote The created test quote
     */
    public static Quote createQuote(String name, Id opportunityId) {
        Quote testQuote = new Quote(
            Name = name,
            OpportunityId = opportunityId,
            ExpirationDate = Date.today().addDays(30)
        );
        insert testQuote;
        return testQuote;
    }
    
    /**
     * Create multiple test quotes
     * @param names List of quote names
     * @param opportunityId The opportunity ID
     * @return List<Quote> The list of created test quotes
     */
    public static List<Quote> createQuotes(List<String> names, Id opportunityId) {
        List<Quote> quotes = new List<Quote>();
        
        for (String name : names) {
            quotes.add(new Quote(
                Name = name,
                OpportunityId = opportunityId
            ));
        }
        
        insert quotes;
        return quotes;
    }
    
    /**
     * Create a standard user with restricted permissions for testing
     * @param username The username for the test user
     * @return User The created test user
     */
    public static User createRestrictedUser(String username) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            Alias = 'tester',
            Email = username,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = username
        );
        
        insert testUser;
        return testUser;
    }
    
    /**
     * Create a complete test setup with accounts, opportunities and quotes
     * @return Map<String, Object> Map containing all created test data
     */
    public static Map<String, Object> createCompleteTestSetup() {
        Map<String, Object> testData = new Map<String, Object>();
        
        // Create custom setting
        testData.put('quoteCounter', createQuoteCounter());
        
        // Create accounts
        Account standardAccount = createAccount('Standard Test Account', 'United States');
        Account indiaAccount = createAccount('India Test Account', 'India');
        testData.put('standardAccount', standardAccount);
        testData.put('indiaAccount', indiaAccount);
        
        // Create opportunities
        Opportunity standardOpp = createOpportunity('Standard Test Opportunity', standardAccount.Id);
        Opportunity indiaOpp = createOpportunity('India Test Opportunity', indiaAccount.Id);
        Opportunity noAccountOpp = createOpportunity('No Account Test Opportunity', null);
        testData.put('standardOpp', standardOpp);
        testData.put('indiaOpp', indiaOpp);
        testData.put('noAccountOpp', noAccountOpp);
        
        // Create quotes
        Quote standardQuote = createQuote('Standard Test Quote', standardOpp.Id);
        Quote indiaQuote = createQuote('India Test Quote', indiaOpp.Id);
        Quote noAccountQuote = createQuote('No Account Test Quote', noAccountOpp.Id);
        testData.put('standardQuote', standardQuote);
        testData.put('indiaQuote', indiaQuote);
        testData.put('noAccountQuote', noAccountQuote);
        
        return testData;
    }
        public static Quote createQuote(String name, Id opportunityId, Id pricebookId) {
        Quote testQuote = new Quote(
            Name = name,
            OpportunityId = opportunityId,
            ExpirationDate = Date.today().addDays(30)
        );

        if (pricebookId != null) {
            testQuote.Pricebook2Id = pricebookId;
        }

        insert testQuote;
        return testQuote;
    }
}