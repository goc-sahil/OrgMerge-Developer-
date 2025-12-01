public with sharing class UpdateCompanyFocusListAction {

    public static void updateFocusList(Set<Id> opportunityIds) {
        if (opportunityIds == null || opportunityIds.isEmpty()) return;

        List<Opportunity> oppList = [
            SELECT Id, CloseDate, Company_Focus_List__c, Focus_List__c, Name, Probability__c, Screening_Submit__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ];

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Opportunity opp : oppList) {
            if (opp.CloseDate == null) continue;

            String quarterValue = getQuarterValue(opp.CloseDate);
            String newValue;

            if (String.isNotBlank(opp.Company_Focus_List__c)) {
                Set<String> values = new Set<String>(opp.Company_Focus_List__c.split(';'));
                if (!values.contains(quarterValue)) {
                values.add(quarterValue);
                newValue = String.join(new List<String>(values), ';');
                }else{ 
                    continue; // Already has that quarter
                    }    
            } else {
                newValue = quarterValue;
            }

            if(newValue != opp.Company_Focus_List__c && opp.Focus_List__c == 'Yes') {
                opp.Company_Focus_List__c = newValue;
                opp.Focus_List_Approved__c = false;
                opp.Screening_Completed__c=true;
                opp.Screening_Submit__c=false; //Added on 13-11-2025
                oppsToUpdate.add(opp);
            }
        }

        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }

    private static String getQuarterValue(Date closeDate) {
        Integer m = closeDate.month();
        Integer y = closeDate.year();
        String q;
        if (m >= 1 && m <= 3) q = 'Q1';
        else if (m <= 6) q = 'Q2';
        else if (m <= 9) q = 'Q3';
        else q = 'Q4';
        return y + ' - ' + q;
    }
}