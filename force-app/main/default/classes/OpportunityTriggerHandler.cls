/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-03-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class OpportunityTriggerHandler {

    // Prevent recursion
    private static Boolean hasAlreadyRun = false;
    private static Boolean hasRunBefore = false;
    
    // BEFORE UPDATE: Reset Screening_Completed__c
    public static void handleBeforeUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        if (hasRunBefore) return;
        hasRunBefore = true;

        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);

            // CONDITION: Company_Focus_List__c changed TO 'Yes' AND Screening_Completed__c is true
            Boolean focusListChangedToYes = (
                (oldOpp.Focus_List__c == null || oldOpp.Focus_List__c != 'Yes') &&
                opp.Focus_List__c == 'Yes'
            );
            

            Boolean screeningWasTrue = (opp.Screening_Completed__c == true);
			//Boolean approvalApprovedfalse = (opp.Approval_Approved__c == false);
            if (focusListChangedToYes  && screeningWasTrue ) {
                opp.Screening_Completed__c = false;
				//opp.Approval_Approved__c=false;
            }
          
            Boolean focusListChangedToNo = (opp.Focus_List__c == 'No');
            if(focusListChangedToNo){
                opp.Company_Focus_List__c = '';
            }
        }

    }

    public static void handleAfterUpdate(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        if (hasAlreadyRun) return;
        hasAlreadyRun = true;

        Set<Id> oppIdsToProcess = new Set<Id>();
		//List<UnlockPendingOpportunity.OpportunityRecordId> inputList = new List<UnlockPendingOpportunity.OpportunityRecordId>();
       
		//List<Opportunity> OppList = New List<Opportunity>();
        
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);
            
			Boolean focusListChangedToNo = (opp.Focus_List__c == 'No');
            // Skip null CloseDate
            if (opp.CloseDate == null) continue;

            // ✅ CASE 2 & CASE 3 only — Approval (Case 1) handled separately by Flow
            Boolean meetsCase2or3 = (
                opp.Focus_List__c == 'Yes' &&
                opp.B1_Q8__c == 'Yes' &&
                (opp.B1_Q8_Comment__c == '75%' || opp.B1_Q8_Comment__c == '100%') &&
                opp.Probability__c >= 70
            );
			
            Boolean meetsCase1 = (
                opp.Focus_List__c == 'Yes' && 
                opp.Focus_List_Approved__c == True &&
                opp.B1_Q8__c == 'Yes' &&
                (opp.B1_Q8_Comment__c == '25%' || opp.B1_Q8_Comment__c == '50%') &&
                opp.Probability__c >= 70
            );

            
            Boolean closeDateChanged = (opp.Focus_List__c == 'Yes' 
                                        && opp.CloseDate != oldOpp.CloseDate 
                                        && opp.Probability__c >= 70 
                                       	&& (opp.B1_Q8_Comment__c == '75%' || opp.B1_Q8_Comment__c == '100%'));
			
            // Proceed only for Case 2 or 3
            if (meetsCase2or3 || closeDateChanged || focusListChangedToNo || meetsCase1) {
                oppIdsToProcess.add(opp.Id);
            }


            
            /*
			// ✅ Ulock Recor only — Approval (Case 1) handled separately by Flow
            Boolean ulockRecord = (
                opp.Focus_List__c == 'No' && oldOpp.Focus_List__c == 'Yes' &&
                opp.B1_Q8__c == 'Yes' &&
                (opp.B1_Q8_Comment__c == '75%' || opp.B1_Q8_Comment__c == '100%') &&
                opp.Probability__c >= 70
            );
            if (ulockRecord) {
               // oppIdsToProcess.add(opp.Id);
                UnlockPendingOpportunity.OpportunityRecordId rec = new UnlockPendingOpportunity.OpportunityRecordId();
				rec.recordId = opp.Id;
				inputList.add(rec);

            }
            */
        }
        /*				
        if(!inputList.isEmpty()){
        UnlockPendingOpportunity.unlockOpportunities(inputList);
		}
        */
        
        
        if (!oppIdsToProcess.isEmpty()) {
            UpdateCompanyFocusListAction.updateFocusList(oppIdsToProcess);
            //System.enqueueJob(new UpdateCompanyFocusListJob(oppIdsToProcess));
        }
        /*
        if(!OppList.isEmpty()){
            update OppList;
        }
		*/
    }
}