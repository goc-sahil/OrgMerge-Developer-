public with sharing class QuotesRelatedListController {
    @AuraEnabled(cacheable=false)
    public static List<Quote> getRelatedQuotes(String opportunityId) {
        return [
            SELECT 
                Id, 
                Name, 
                Expiration_Date__c,
                Opportunity__c, 
                opportunityId,
                Payment_Terms__c, 
                Quote_Number_Constant__c, 
                Review_Requested_for__c, 
                Show_Button__c,
                Quote_Name__c
            FROM Quote
            WHERE Opportunity.id  = :opportunityId 
            ORDER BY CreatedDate DESC 
            LIMIT 6
        ];
    }
}