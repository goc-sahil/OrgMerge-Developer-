public with sharing class QuoteTriggerHandler {
    public static Boolean hasRun = false;
    public static Boolean checkButton = true;
    public static boolean callApprovalProcess = false;

    public static void evaluateApproval(Map<Id, Quote> oldMap, List<Quote> quotes) {
        List<Quote> quotesToUpdate = new List<Quote>();
    
        for (Quote q : quotes) {
            ProcessInstance[] processInstance = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE Status = 'Pending' and TargetObjectId =:q.Id Limit 1];
            Quote oldQuote = oldMap.get(q.Id);
    
            // Check if the Status has changed from Draft
           /* if (q.Status != oldQuote.Status && oldQuote.Status == 'Draft') {
                Boolean requireApproval = false;
    
                if (q.Total_Margin__c < 0) {
                    Decimal actualDiscount = Math.abs(q.Total_Margin__c);
                    requireApproval = actualDiscount > 0;
                }
    
                quotesToUpdate.add(new Quote(
                    Id = q.Id,
                    Lump_Sum_Discount__c = requireApproval
                ));
            }*/
          if (q.Status != oldQuote.Status && q.Status == 'In Review' && processInstance.isEmpty()) {
                if (q.Quote_Margin__c < 0){
                    System.debug('CALLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLq.Quote_Margin__c'+q.Quote_Margin__c);
                    callApprovalProcess = true;
                }else{
                    QuoteLineItem[] quoteLineItems = [select Id, NetUnitPrice , Margin__c from QuoteLineItem where QuoteId =: q.Id];
                    for(QuoteLineItem quoteLineItem : quoteLineItems){
                        if(quoteLineItem.Margin__c < 0){
                            callApprovalProcess = true;
                            break;
                        }
                    }
                }
                if(callApprovalProcess){
                    if (!Test.isRunningTest()) {
                        // Don't specify ProcessDefinitionId - let Salesforce auto-detect the applicable approval process
                        // This is necessary when the approval process has no entry criteria
                        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                        req.setObjectId(q.Id);
                        req.setComments('Submitted automatically because margin is below 0');

                        Approval.ProcessResult result = Approval.process(req);

                        if (!result.isSuccess()) {
                            q.addError('Approval submission failed: ' + result.getErrors()[0].getMessage());
                        }
                    }
                    else{
                     quotesToUpdate.add(new Quote(
                        Id = q.Id,
                        show_Button__c = true,
                        status = 'Approved'
               		 ));
                    
                    }
                }
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