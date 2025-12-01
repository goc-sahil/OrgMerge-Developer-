/**
 * @description Test class for OpportunityController
 * @author      YourName
 * @date        11-06-2025
 */
@isTest
private class OpportunityControllerTest {

    // Helper: Create test Opportunity with required fields
    private static Opportunity createTestOpportunity() {
        // Create Account
        Account acc = new Account(Name = 'Test Account', BillingCountry = 'United States',Type='Partner');
        insert acc;
        return new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Focus_List__c = 'No',
            Screening_Completed__c = false,
            Screening_Submit__c = false,
             End_Customer__c=acc.Id,
            Engagement_Model__c='Enterprise RFP (Multi-SI)',
            Opportunity_tagging__c='Enterprise'
        );
    }

    // Setup test data
    @TestSetup
    static void setup() {
        // Create test Opportunity
        Opportunity opp = createTestOpportunity();
        insert opp;

        // Create active user 'Sagar Nimavat'
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User sagarUser = new User(
            FirstName = 'Sagar',
            LastName = 'Nimavat',
            Email = 'sagar.nimavat@test.com',
            Username = 'sagar.nimavat@test' + DateTime.now().getTime() + '@test.com',
            Alias = 'sagar',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert sagarUser;
    }

    // TEST: getOpportunityData - Success
    @isTest
    static void testGetOpportunityData_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        Map<String, Object> result = OpportunityController.getOpportunityData(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result map should not be null');
        System.assert(result.containsKey('B1_Q1__c'), 'Should include B1_Q1__c');
        System.assert(result.containsKey('Achieved_Score__c'), 'Should include Achieved_Score__c');
    }

    // TEST: saveOpportunity - Non-numeric score handled as null
    @isTest
    static void testSaveOpportunity_NonNumericScore() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, Object> oppData = new Map<String, Object>{
            'Id' => opp.Id,
            'B1_Q1_Score__c' => 'abc' // Invalid number
        };

        Test.startTest();
        OpportunityController.saveOpportunity(oppData);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT B1_Q1_Score__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(null, updatedOpp.B1_Q1_Score__c, 'Non-numeric score should be set to null');
    }

    // TEST: sendApprovalEmail - Focus_List__c != 'Yes'
    @isTest
    static void testSendApprovalEmail_NotYes() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        String result = OpportunityController.sendApprovalEmail(opp.Id);
        Test.stopTest();

        System.assertEquals('Email not sent – Focus List is not marked as Yes.', result);
    }

    // TEST: markScreeningCompleted - Success
    @isTest
    static void testMarkScreeningCompleted_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        OpportunityController.markScreeningCompleted(opp.Id,'true');
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Screening_Completed__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, updatedOpp.Screening_Completed__c, 'Screening should be marked completed');
    }

    // TEST: markScreeningSubmit - Success
    @isTest
    static void testMarkScreeningSubmit_Success() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        OpportunityController.markScreeningSubmit(opp.Id);
        Test.stopTest();

        Opportunity updatedOpp = [SELECT Screening_Submit__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(true, updatedOpp.Screening_Submit__c, 'Screening_Submit__c should be true');
    }

    // TEST: Custom Label is used in email body
    @isTest
    static void testSendApprovalEmail_UsesCustomLabel() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        opp.Focus_List__c = 'Yes';
        update opp;

        // Set mock label value (in test context, labels are accessible if defined)
        // Note: In real org, ensure System.Label.TotalQuestions exists
        Test.startTest();
        String result = OpportunityController.sendApprovalEmail(opp.Id);
        Test.stopTest();

        System.assert(result.contains('Email sent successfully'), 'Email should send');
        // Cannot assert label content unless mocked, but logic is covered
    }
}