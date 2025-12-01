public with sharing class QuoteTriggerHandler {
    public static Boolean hasRun = false;

    public static void evaluateApproval(Map<Id, Quote> oldMap, List<Quote> quotes) {
        List<Quote> quotesToUpdate = new List<Quote>();
    
        for (Quote q : quotes) {
            Quote oldQuote = oldMap.get(q.Id);
    
            // Check if the Status has changed from Draft
            if (q.Status != oldQuote.Status && oldQuote.Status == 'Draft') {
                Boolean requireApproval = false;
    
                if (q.Total_Margin__c < 0) {
                    Decimal actualDiscount = Math.abs(q.Total_Margin__c);
                    requireApproval = actualDiscount > 0;
                }
    
                quotesToUpdate.add(new Quote(
                    Id = q.Id,
                    Lump_Sum_Discount__c = requireApproval
                ));
            }
        }
    
        if (!quotesToUpdate.isEmpty()) {
            System.debug('Updating Quotes: ' + quotesToUpdate);
            update quotesToUpdate;
        }
    }
    
    
    // public static void evaluateApproval(List<Quote> quotes) {
    //     List<Quote> quotesToUpdate = new List<Quote>();

    //     for (Quote q : quotes) {
    //         if (q.Status == 'Draft') {
    //             Boolean requireApproval = false;

    //             // Only trigger if margin is negative
    //             if (q.Total_Margin__c < 0) {
    //                 Decimal actualDiscount = Math.abs(q.Total_Margin__c);
    //                 requireApproval = actualDiscount > 0;
    //             }

    //             quotesToUpdate.add(new Quote(
    //                 Id = q.Id,
    //                 Lump_Sum_Discount__c = requireApproval
    //             ));
    //         } 
    //     }

    //     if (!quotesToUpdate.isEmpty()) {
    //         update quotesToUpdate;
    //     }
    // }
}