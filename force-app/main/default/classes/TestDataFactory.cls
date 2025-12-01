@isTest
public class TestDataFactory {

    public static Id setupTestData() {
        // Create Account
        Account acc = new Account(
            Name = 'Test Account',
            Customer_Number__c = 'CUST001',
            Tax_ID_Number__c = 'TAX123',
			BillingCountry = 'India'
        );
        insert acc;

        // Create Contact
        Contact con = new Contact(
            LastName = 'Doe',
            Email = 'test@example.com',
            Phone = '9999999999',
            AccountId = acc.Id
        );
        insert con;

        // Create Current Quote Number Setup
        currentQuoteNumber__c cs = new currentQuoteNumber__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            currentQuoteNumber__c = 3570,
            currentQuoteNumberIndia__c = 1095
        );
        insert cs;

        // Get Standard Pricebook
        Id pricebookId = Test.getStandardPricebookId();

        // Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospect',
            CloseDate = System.today().addDays(10),
            CurrencyIsoCode = 'USD',
            AccountId = acc.Id,
            Engagement_Model__c = 'Direct',
            Opportunity_tagging__c = 'Enterprise',
            End_Customer__c = acc.Id,
            Pricebook2Id = pricebookId
        );
        insert opp;

        // Create Quote
        Quote qt = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            ContactId = con.Id,
            QuoteAccountId = acc.Id,
            BillingName = 'Test Billing',
            ShippingName = 'Test Shipping',
            BillingStreet = '123 Street',
            BillingCity = 'Ahmedabad',
            BillingState = 'Gujarat',
            BillingPostalCode = '380059',
            BillingCountry = 'India',
            ShippingStreet = '456 Street',
            ShippingCity = 'Ahmedabad',
            ShippingState = 'Gujarat',
            ShippingPostalCode = '380059',
            ShippingCountry = 'India',
            Payment_Terms__c = 'Net 30',
            IncoTerms__c = 'FOB',
            Quote_PDF_Version__c = 'Q-001',
            CurrencyIsoCode = 'USD',
            Show_Button__c = true,
            Status = 'Draft',
            Additional__c = 'Test comments',
            Pricebook2Id = pricebookId
        );
        insert qt;

        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'TP001', IsActive = true);
        insert prod;

        // Create Product Selling Model
        ProductSellingModel prodSelling = new ProductSellingModel(
            Name = 'Test Selling Model',
            SellingModelType = 'Evergreen',
            PricingTerm = 1,
            PricingTermUnit = 'Months',
            Status = 'Active'
        );
        insert prodSelling;

        // Create Product Selling Model Option
        ProductSellingModelOption prdSellingOption = new ProductSellingModelOption(
            Product2Id = prod.Id,
            ProductSellingModelId = prodSelling.Id
        );
        insert prdSellingOption;

        // Create Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = prod.Id,
            UnitPrice = 1000,
            Pricebook2Id = pricebookId,
            IsActive = true,
            ProductSellingModelId = prodSelling.Id,
            CurrencyIsoCode = 'USD'
        );
        insert pbe;

        // Create Quote Line Item
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = qt.Id,
            Quantity = 2,
            UnitPrice = 5000,
            Discount = 10,
            Product_Name__c = 'Test Product',
            Product_Description__c = 'Sample description',
            PricebookEntryId = pbe.Id
        );
        insert qli;

        // Return the Quote Id for reuse in tests
        return qt.Id;
    }
}