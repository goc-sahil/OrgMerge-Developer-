/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 11-12-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class OpportunityController {
    @AuraEnabled
public static void saveOpportunity(Map<String, Object> opportunityData) {
        try {
            Opportunity opp = new Opportunity(Id = (Id)opportunityData.get('Id'));
            for (String field : opportunityData.keySet()) {
                Object val = opportunityData.get(field);
                if (field.endsWith('_Score__c') || field == 'Answered__c' ||
                field == 'Not_Answered__c' ||
                field == 'Achieved_Score__c' ||
                field == 'Probability__c' ) {
                    if (val != null && String.valueOf(val).isNumeric()) {
                        opp.put(field, Decimal.valueOf(String.valueOf(val)));
                    } else {
                        opp.put(field, null); // Set to null if the value is not numeric
                    }
                } else {
                    opp.put(field, val != null ? String.valueOf(val) : null);
                }
            }
            opp.Screening_Completed__c =true;
            update opp;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving opportunity: ' + e.getMessage());
        }
    }

    @AuraEnabled
public static Map<String, Object> getOpportunityData(Id opportunityId) {
    try {
        Opportunity opp = [SELECT 
                B1_Q1__c, B1_Q1_Comment__c, B1_Q1_Score__c,
                B1_Q2__c, B1_Q2_Comment__c, B1_Q2_Score__c,
                B1_Q3__c, B1_Q3_Comment__c, B1_Q3_Score__c,
                B1_Q4__c, B1_Q4_Comment__c, B1_Q4_Score__c,
                B1_Q5__c, B1_Q5_Comment__c, B1_Q5_Score__c,
                B1_Q6__c, B1_Q6_Comment__c, B1_Q6_Score__c,
                B1_Q7__c, B1_Q7_Comment__c, B1_Q7_Score__c,
                B1_Q8__c, B1_Q8_Comment__c, B1_Q8_Score__c,
                B1_Q9__c, B1_Q9_Comment__c, B1_Q9_Score__c,
                B1_Q10__c, B1_Q10_Comment__c, B1_Q10_Score__c,
                B2_Q1__c, B2_Q1_Comment__c, B2_Q1_Score__c,
                B2_Q2__c, B2_Q2_Comment__c, B2_Q2_Score__c,
                B2_Q3__c, B2_Q3_Comment__c, B2_Q3_Score__c,
                B2_Q4__c, B2_Q4_Comment__c, B2_Q4_Score__c,
                B2_Q5__c, B2_Q5_Comment__c, B2_Q5_Score__c,
                B2_Q6__c, B2_Q6_Comment__c, B2_Q6_Score__c,
                B2_Q7__c, B2_Q7_Comment__c, B2_Q7_Score__c,
                B2_Q8__c, B2_Q8_Comment__c, B2_Q8_Score__c,
                B2_Q9__c, B2_Q9_Comment__c, B2_Q9_Score__c,
                B2_Q10__c, B2_Q10_Comment__c, B2_Q10_Score__c,
                B2_Q11__c, B2_Q11_Comment__c, B2_Q11_Score__c,
                B3_Q1__c, B3_Q1_Comment__c, B3_Q1_Score__c,
                B3_Q2__c, B3_Q2_Comment__c, B3_Q2_Score__c,
                B3_Q3__c, B3_Q3_Comment__c, B3_Q3_Score__c,
                B3_Q4__c, B3_Q4_Comment__c, B3_Q4_Score__c,
                B3_Q5__c, B3_Q5_Comment__c, B3_Q5_Score__c,
                Answered__c,Not_Answered__c,Achieved_Score__c,
                Probability__c
            FROM Opportunity 
            WHERE Id = :opportunityId
        ];

        Map<String, Object> data = new Map<String, Object>();
        data.put('B1_Q1__c', opp.B1_Q1__c);
        data.put('B1_Q1_Comment__c', opp.B1_Q1_Comment__c);
        data.put('B1_Q1_Score__c', opp.B1_Q1_Score__c);
        data.put('B1_Q2__c', opp.B1_Q2__c);
        data.put('B1_Q2_Comment__c', opp.B1_Q2_Comment__c);
        data.put('B1_Q2_Score__c', opp.B1_Q2_Score__c);
        data.put('B1_Q3__c', opp.B1_Q3__c);
        data.put('B1_Q3_Comment__c', opp.B1_Q3_Comment__c);
        data.put('B1_Q3_Score__c', opp.B1_Q3_Score__c);
        data.put('B1_Q4__c', opp.B1_Q4__c);
        data.put('B1_Q4_Comment__c', opp.B1_Q4_Comment__c);
        data.put('B1_Q4_Score__c', opp.B1_Q4_Score__c);
        data.put('B1_Q5__c', opp.B1_Q5__c);
        data.put('B1_Q5_Comment__c', opp.B1_Q5_Comment__c);
        data.put('B1_Q5_Score__c', opp.B1_Q5_Score__c);
        data.put('B1_Q6__c', opp.B1_Q6__c);
        data.put('B1_Q6_Comment__c', opp.B1_Q6_Comment__c);
        data.put('B1_Q6_Score__c', opp.B1_Q6_Score__c);
        data.put('B1_Q7__c', opp.B1_Q7__c);
        data.put('B1_Q7_Comment__c', opp.B1_Q7_Comment__c);
        data.put('B1_Q7_Score__c', opp.B1_Q7_Score__c);
        data.put('B1_Q8__c', opp.B1_Q8__c);
        data.put('B1_Q8_Comment__c', opp.B1_Q8_Comment__c);
        data.put('B1_Q8_Score__c', opp.B1_Q8_Score__c);
        data.put('B1_Q9__c', opp.B1_Q9__c);
        data.put('B1_Q9_Comment__c', opp.B1_Q9_Comment__c);
        data.put('B1_Q9_Score__c', opp.B1_Q9_Score__c);
        data.put('B1_Q10__c', opp.B1_Q10__c);
        data.put('B1_Q10_Comment__c', opp.B1_Q10_Comment__c);
        data.put('B1_Q10_Score__c', opp.B1_Q10_Score__c);
        data.put('B2_Q1__c', opp.B2_Q1__c);
        data.put('B2_Q1_Comment__c', opp.B2_Q1_Comment__c);
        data.put('B2_Q1_Score__c', opp.B2_Q1_Score__c);
        data.put('B2_Q2__c', opp.B2_Q2__c);
        data.put('B2_Q2_Comment__c', opp.B2_Q2_Comment__c);
        data.put('B2_Q2_Score__c', opp.B2_Q2_Score__c);
        data.put('B2_Q3__c', opp.B2_Q3__c);
        data.put('B2_Q3_Comment__c', opp.B2_Q3_Comment__c);
        data.put('B2_Q3_Score__c', opp.B2_Q3_Score__c);
        data.put('B2_Q4__c', opp.B2_Q4__c);
        data.put('B2_Q4_Comment__c', opp.B2_Q4_Comment__c);
        data.put('B2_Q4_Score__c', opp.B2_Q4_Score__c);
        data.put('B2_Q5__c', opp.B2_Q5__c);
        data.put('B2_Q5_Comment__c', opp.B2_Q5_Comment__c);
        data.put('B2_Q5_Score__c', opp.B2_Q5_Score__c);
        data.put('B2_Q6__c', opp.B2_Q6__c);
        data.put('B2_Q6_Comment__c', opp.B2_Q6_Comment__c);
        data.put('B2_Q6_Score__c', opp.B2_Q6_Score__c);
        data.put('B2_Q7__c', opp.B2_Q7__c);
        data.put('B2_Q7_Comment__c', opp.B2_Q7_Comment__c);
        data.put('B2_Q7_Score__c', opp.B2_Q7_Score__c);
        data.put('B2_Q8__c', opp.B2_Q8__c);
        data.put('B2_Q8_Comment__c', opp.B2_Q8_Comment__c);
        data.put('B2_Q8_Score__c', opp.B2_Q8_Score__c);
        data.put('B2_Q9__c', opp.B2_Q9__c);
        data.put('B2_Q9_Comment__c', opp.B2_Q9_Comment__c);
        data.put('B2_Q9_Score__c', opp.B2_Q9_Score__c);
        data.put('B2_Q10__c', opp.B2_Q10__c);
        data.put('B2_Q10_Comment__c', opp.B2_Q10_Comment__c);
        data.put('B2_Q10_Score__c', opp.B2_Q10_Score__c);
        data.put('B2_Q11__c', opp.B2_Q11__c);
        data.put('B2_Q11_Comment__c', opp.B2_Q11_Comment__c);
        data.put('B2_Q11_Score__c', opp.B2_Q11_Score__c);
        data.put('B3_Q1__c', opp.B3_Q1__c);
        data.put('B3_Q1_Comment__c', opp.B3_Q1_Comment__c);
        data.put('B3_Q1_Score__c', opp.B3_Q1_Score__c);
        data.put('B3_Q2__c', opp.B3_Q2__c);
        data.put('B3_Q2_Comment__c', opp.B3_Q2_Comment__c);
        data.put('B3_Q2_Score__c', opp.B3_Q2_Score__c);
        data.put('B3_Q3__c', opp.B3_Q3__c);
        data.put('B3_Q3_Comment__c', opp.B3_Q3_Comment__c);
        data.put('B3_Q3_Score__c', opp.B3_Q3_Score__c);
        data.put('B3_Q4__c', opp.B3_Q4__c);
        data.put('B3_Q4_Comment__c', opp.B3_Q4_Comment__c);
        data.put('B3_Q4_Score__c', opp.B3_Q4_Score__c);
        data.put('B3_Q5__c', opp.B3_Q5__c);
        data.put('B3_Q5_Comment__c', opp.B3_Q5_Comment__c);
        data.put('B3_Q5_Score__c', opp.B3_Q5_Score__c);
        data.put('Answered__c',       opp.Answered__c);
        data.put('Not_Answered__c',   opp.Not_Answered__c);
        data.put('Achieved_Score__c', opp.Achieved_Score__c);
        data.put('Probability__c',    opp.Probability__c);

        return data;
    } catch (Exception e) {
        throw new AuraHandledException('Error loading opportunity: ' + e.getMessage());
    }
}

/**
 * Sends the “Company Focus List” approval e-mail using Org-Wide Email Address.
 * Sent only when Focus_List__c = 'Yes'.
 * Recipient: Sagar Nimavat (looked up by name).
 *
 * @param oppId  Id of the Opportunity
 * @return       Status message for the LWC
 */
@AuraEnabled
public static String sendApprovalEmail(Id oppId) {
    try {
        Opportunity opp = [
            SELECT Id, Owner.FirstName,Answered__c, Not_Answered__c,Achieved_Score__c, Probability__c,B1_Q8_Comment__c,
                   Focus_List__c FROM Opportunity WHERE Id = :oppId LIMIT 1];

        if (opp.Focus_List__c != 'Yes') {
            return 'Email not sent – Focus List is not marked as Yes.';
        }

        User sagarUser = [SELECT Email FROM User WHERE Name = 'Sagar Nimavat' AND IsActive = true LIMIT 1];

        if (sagarUser == null || String.isBlank(sagarUser.Email)) {
            throw new AuraHandledException('User Sagar Nimavat not found or has no email.');
        }

        OrgWideEmailAddress owea = [ SELECT Id FROM OrgWideEmailAddress WHERE Address = 'order@invixium.com' LIMIT 1];

        if (owea == null) {
            throw new AuraHandledException('Org-Wide Email Address order@invixium.com not found.');
        }
        String body = 'Hi,\n\n' +
            opp.Owner.FirstName + '\'s request has been Approved to add in Company Focus List. ' +
            'Opportunity details are as below.\n\n' +
            'Total Questions: ' + System.Label.TotalQuestions + '\n' +
            'Questions Answered: ' + (opp.Answered__c != null ? String.valueOf(opp.Answered__c) : '0') + '\n' +
            'Questions Not Answered: ' + (opp.Not_Answered__c != null ? String.valueOf(opp.Not_Answered__c) : '0') + '\n' +
            'Achieved Score: ' + (opp.Achieved_Score__c != null ? String.valueOf(opp.Achieved_Score__c) : '0') + '\n' +
            'Probability: ' + (opp.Probability__c != null ? String.valueOf(opp.Probability__c) : '0') + '%\n' +
            'In your opinion, what are your chances of winning in the quarter (%): ' +
            (opp.B1_Q8_Comment__c != null ? opp.B1_Q8_Comment__c : '') + '\n\n' +
            'Please check more details at: ' + System.Label.OrgBaseUrl + opp.Id + '\n\n' +
            'Thank you!';

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ sagarUser.Email });
        mail.setSubject('Opportunity Approved for Company Focus List');
        mail.setPlainTextBody(body);
        mail.setOrgWideEmailAddressId(owea.Id);  
        mail.setSaveAsActivity(false); 

        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ mail });

        if (results[0].isSuccess()) {
            Opportunity op=new Opportunity();
            op.Id=oppId;
            op.Screening_Submit__c=false;
            update op;
            return 'Email sent successfully to Sagar Nimavat (' + sagarUser.Email + ') from order@invixium.com';
        } else {
            String err = '';
            for (Messaging.SendEmailError e : results[0].getErrors()) {
                err += e.getMessage() + ' ';
            }
            throw new AuraHandledException('Email failed: ' + err);
        }

    } catch (Exception ex) {
        throw new AuraHandledException('Error: ' + ex.getMessage());
    }
}

    @AuraEnabled
public static void markScreeningCompleted(Id opportunityId,String fromCancel) {
    try {
        Opportunity opp = new Opportunity(Id = opportunityId,Screening_Completed__c = true);
        if(fromCancel == 'true'){
            //opp.Focus_List__c='No';
        }
        update opp;
    } catch (Exception e) {
        throw new AuraHandledException('Failed to mark screening as completed: ' + e.getMessage());
    }
}
 @AuraEnabled
public static void markScreeningSubmit(Id opportunityId) {
    try {
        Opportunity opp = new Opportunity(Id = opportunityId,Screening_Submit__c = true);
        update opp;
    } catch (Exception e) {
        throw new AuraHandledException('Failed to mark screening as completed: ' + e.getMessage());
    }
}
}