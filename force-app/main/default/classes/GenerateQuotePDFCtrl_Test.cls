@isTest
public class GenerateQuotePDFCtrl_Test {
    
    @testSetup
    static void setup() {
        // Create test data
        Account acc = new Account(Name = 'Test Account', BillingCountry = 'United States');
        insert acc;

        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(30),End_Customer__c=acc.Id,
            Engagement_Model__c='Enterprise RFP (Multi-SI)',
            Opportunity_tagging__c='Enterprise');
        insert opp;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        // Create a pricebook entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Initialize custom settings for quote numbers
        currentQuoteNumber__c setting = new currentQuoteNumber__c(
            Name = 'Default',
            currentQuoteNumberIndia__c = 1,
            currentQuoteNumber__c = 1
        );
        insert setting;
        

        // Set up the user context
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(testUser) {
            // Ensure the quote has the same currency as the pricebook entry
            Quote quote = new Quote(
                Name = 'Test Quote', 
                OpportunityId = opp.Id, 
                Status = 'Draft', 
                Pricebook2Id = Test.getStandardPricebookId(), 
                CurrencyIsoCode = 'USD',  // Ensure the quote has a valid currency
               
                LumpsumDiscount__c = 10.00
            );
            insert quote;

            // Create the quote line item
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = quote.Id, 
                PricebookEntryId = pbe.Id, 
                Quantity = 2, 
                UnitPrice = 100
            );
            insert qli;

            Contact cont = new Contact(LastName = 'Test Contact', AccountId = acc.Id);
            insert cont;
        }
    }

    @isTest
    static void testGenerateQuotePDFCtrl() {
        // Retrieve the test quote
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        PageReference myVfPage = Page.GenerateQuotePDF;
        Test.setCurrentPage(myVfPage);
        ApexPages.currentPage().getParameters().put('Id', quote.Id);
        ApexPages.currentPage().getParameters().put('ObjectName', 'isQuote');
        
        // Instantiate the controller
        GenerateQuotePDFCtrl ctrl = new GenerateQuotePDFCtrl();
        
        // Assertions
        System.assertEquals(quote.Id, ctrl.id, 'Quote Id should match the page parameter Id');
        System.assertEquals('isQuote', ctrl.objectName, 'ObjectName should be isQuote');
        System.assertEquals(quote.Id, ctrl.quote.Id, 'Quote Id should match the retrieved QuoteWrapper Id');
        
        // Testing discount visibility
        Boolean discountPresent = ctrl.hasDiscount(ctrl.quote.QuoteLineItems);
        System.assertEquals(ctrl.showDiscountColumn, discountPresent, 'Discount column visibility should match the presence of discounts');
    }
    
}