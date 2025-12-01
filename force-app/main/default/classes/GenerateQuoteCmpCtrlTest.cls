@isTest
private class GenerateQuoteCmpCtrlTest {
    
    @TestSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account', BillingCountry = 'India');
        insert acc;
        
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', AccountId = acc.Id, StageName = 'Prospecting', CloseDate = Date.today().addDays(30));
        insert opp;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // Set up the custom setting for generating quote numbers
        currentQuoteNumber__c setting = new currentQuoteNumber__c(
            Name = 'Default',
            currentQuoteNumberIndia__c = 1,
            currentQuoteNumber__c = 1
        );
        insert setting;
    }

    @isTest
    static void testSavePdf() {
        // Create a test Quote record
        Quote quote = new Quote(
            Name = 'Test Quote',
            OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id,
            Status = 'Draft',
            Pricebook2Id = Test.getStandardPricebookId()
        );
            Id systemAdminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        System.runAs(new User(Id = UserInfo.getUserId(), ProfileId = systemAdminProfileId)) {
            insert quote;
        

        Test.startTest();
        GenerateQuoteCmpCtrl.savePdf(quote.Id);
        Test.stopTest();
        }
        // Verify that a ContentVersion record was created
        List<ContentVersion> contentVersions = [SELECT Id, Title, PathOnClient, ContentDocumentId FROM ContentVersion];
        System.assertEquals(1, contentVersions.size(), 'A ContentVersion record should be created.');
        System.assertEquals('Test Quote EAI000001', contentVersions[0].Title, 'The Title of the ContentVersion should match the Quote_Number_Constant__c.');
        System.assertEquals('EAI000001.pdf', contentVersions[0].PathOnClient, 'The PathOnClient should be set correctly.');

        // Verify that a ContentDocumentLink record was created
        Id contentDocumentId = contentVersions[0].ContentDocumentId;
        List<ContentDocumentLink> contentLinks = [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :quote.Id];
        System.assertEquals(1, contentLinks.size(), 'A ContentDocumentLink record should be created.');
        System.assertEquals(quote.Id, contentLinks[0].LinkedEntityId, 'The ContentDocumentLink should be linked to the Quote record.');
        System.assertEquals(contentDocumentId, contentLinks[0].ContentDocumentId, 'The ContentDocumentLink should be linked to the correct ContentDocument.');
    }

    @isTest
    static void testShowButton() {
        // Create a list of test Quote records with different statuses
        List<Quote> testQuotes = new List<Quote>{
            new Quote(Name = 'Quote 1',OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id, Status = 'Approved', Show_Button__c = true),
            new Quote(Name = 'Quote 2',OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id, Status = 'Presented', Show_Button__c = true),
            new Quote(Name = 'Quote 3',OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id, Status = 'Accepted', Show_Button__c = true),
            new Quote(Name = 'Quote 4',OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id, Status = 'Denied', Show_Button__c = true),
            new Quote(Name = 'Quote 5',OpportunityId = [SELECT Id FROM Opportunity LIMIT 1].Id, Status = 'Draft', Show_Button__c = true)
        };
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testQuotes;
        }

        Test.startTest();
        for (Quote quote : testQuotes) {
            Boolean showButton = GenerateQuoteCmpCtrl.showButton(quote.Id);
            System.debug('Quote Status: ' + quote.Status + ', Show Button: ' + showButton);

            // Verify the expected behavior of the showButton method
            if (quote.Status == 'Approved' || quote.Status == 'Presented' || quote.Status == 'Accepted' || quote.Status == 'Denied') {
                System.assertEquals(quote.Show_Button__c, showButton, 'Incorrect show button value for Quote ' + quote.Name);
            } else {
                System.assertEquals(false, showButton, 'Incorrect show button value for Quote ' + quote.Name);
            }
        }
        Test.stopTest();
    }
}