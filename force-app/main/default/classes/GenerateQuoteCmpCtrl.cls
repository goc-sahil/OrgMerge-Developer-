public with sharing class GenerateQuoteCmpCtrl {
    @auraEnabled
    public static void savePdf(string recordId) {
        PageReference pdfPage = new PageReference('/apex/GenerateQuotePDF');
        pdfPage.getParameters().put('Id',recordId);
        pdfPage.getParameters().put('ObjectName', 'isQuote');

        Quote quotationRecord  = [SELECT Id,Quote_Number_Constant__c, Name, Quote_PDF_Version__c 
                                  FROM Quote 
                                  WHERE Id =: recordId 
                                  WITH SECURITY_ENFORCED];
        // String quotationName  = [SELECT Id, Name,Quote_Number__c FROM Quote WHERE Id =: recordId WITH SECURITY_ENFORCED].Name;
        ContentVersion cont = new ContentVersion();
        // cont.Title = quotationNumber+' - '+quotationName;
        cont.PathOnClient = quotationRecord.Quote_PDF_Version__c+'.pdf';
        cont.Title = quotationRecord.Name +' '+ quotationRecord.Quote_PDF_Version__c;
        blob pdfBody;
        if(Test.isRunningTest()) { 
            pdfBody = blob.valueOf('Unit.Test');
        } else {
            pdfBody = pdfPage.getContentAsPDF();
        }
        cont.VersionData = pdfBody;
        cont.Origin = 'H';
        if (Schema.sObjectType.ContentVersion.isCreateable()) {
            insert cont; 
        }
        
        ContentVersion contentVersionn = [SELECT Id, Title, ContentDocumentId 
                                          FROM ContentVersion 
                                          WHERE Id = :cont.Id 
                                          WITH SECURITY_ENFORCED 
                                          LIMIT 1 ];
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = recordId;
        contentlink.contentdocumentid = contentVersionn.contentdocumentid;
        contentlink.ShareType = 'V';
        //system.debug(contentlink);
        if (Schema.sObjectType.ContentDocumentLink.isCreateable()) {
            insert contentlink;
        }
       
        
    }
    @auraEnabled
    public static Boolean showButton(string recordId){
        Quote quotationRecord  = [SELECT Id, Show_Button__c, Status 
                                  FROM Quote 
                                  WHERE Id =: recordId 
                                  WITH SECURITY_ENFORCED];
        if (quotationRecord != null && quotationRecord.Status != null && quotationRecord.Show_Button__c) {
            Set<String> allowedStatus = new Set<String>{'Approved', 'Presented', 'Accepted', 'Denied'};
            Boolean status = allowedStatus.contains(quotationRecord.Status);
            //System.debug('status'+status);
            return allowedStatus.contains(quotationRecord.Status);
        }
        return false;
        
    }
}