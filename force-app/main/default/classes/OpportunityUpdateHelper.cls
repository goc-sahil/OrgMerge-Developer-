public with sharing class OpportunityUpdateHelper {
    @AuraEnabled(cacheable=true)
    public static Opportunity getOppRecord(Id recordId) {
        return [SELECT Id, Name, StageName FROM Opportunity WHERE Id = :recordId];
    }

    @AuraEnabled
    public static void updateStage(Id recordId, String stage) {
        Opportunity opp = new Opportunity(Id = recordId, StageName = stage);
        update opp;
    }
}
