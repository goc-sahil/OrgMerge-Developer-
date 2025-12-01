public class GenerateQuoteProformaCmpCtrl {
    @AuraEnabled
public static void savePdf(
    String recordId,
    String tDate,
    String dueDate,
    String paid,
    String paying,
    String remaining,
    String taxAmount,
    String totalGrandAmount,
    String selectedTaxType,
    String shipVia,
    String index,
    String paymentTerm,
    String totalpaidPercentage,
    String totalUnpaidPercentage
) {
    try {

        // Prepare VF page reference with all params
        PageReference pdfPage = new PageReference('/apex/GenerateProformaInvoicePDF');
        pdfPage.getParameters().put('Id', recordId);
        pdfPage.getParameters().put('ObjectName', 'isQuote');
        pdfPage.getParameters().put('tDate', tDate);
        pdfPage.getParameters().put('dueDate', dueDate);
        pdfPage.getParameters().put('paid', paid);
        pdfPage.getParameters().put('paying', paying);
        pdfPage.getParameters().put('remaining', remaining);
        pdfPage.getParameters().put('taxAmount', taxAmount);
        pdfPage.getParameters().put('totalGrandAmount', totalGrandAmount);
        pdfPage.getParameters().put('selectedTaxType', selectedTaxType);
        pdfPage.getParameters().put('shipVia', shipVia);
        pdfPage.getParameters().put('index', index);
        pdfPage.getParameters().put('paymentTerm',paymentTerm);
        pdfPage.getParameters().put('totalpaidPercentage', totalpaidPercentage);
        pdfPage.getParameters().put('totalUnpaidPercentage', totalUnpaidPercentage);


        //Query Quote for file naming
        Quote quotationRecord = [
            SELECT Id, Name, Quote_Number_Constant__c, Quote_PDF_Version__c
            FROM Quote
            WHERE Id = :recordId
            WITH SECURITY_ENFORCED
        ];

        //Generate PDF content
        Blob pdfBody;
        if (Test.isRunningTest()) {
            pdfBody = Blob.valueOf('Unit.Test');
        } else {
            pdfBody = pdfPage.getContentAsPDF(); // may throw if page errors
        }

        // Create ContentVersion record
        ContentVersion cont = new ContentVersion();
        cont.Title = quotationRecord.Name + ' ' + quotationRecord.Quote_PDF_Version__c;
        cont.PathOnClient = quotationRecord.Quote_PDF_Version__c + '.pdf';
        cont.VersionData = pdfBody;
        cont.Origin = 'H';

        if (Schema.sObjectType.ContentVersion.isCreateable()) {
            insert cont;
        } else {
            throw new AuraHandledException('Insufficient permissions to create ContentVersion.');
        }

        //Link file to Quote record
        ContentVersion insertedVersion = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cont.Id
            LIMIT 1
        ];

        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = insertedVersion.ContentDocumentId;
        link.LinkedEntityId = recordId;
        link.ShareType = 'V';
        link.Visibility = 'AllUsers';

        if (Schema.sObjectType.ContentDocumentLink.isCreateable()) {
            insert link;
        } else {
            throw new AuraHandledException('Insufficient permissions to create ContentDocumentLink.');
        }

    } catch (Exception e) {
        throw new AuraHandledException('Error saving PDF: ' + e.getMessage());
    }
}

    
    
    @auraEnabled
    public static Decimal getTotalQuoteAmount(String recordId) {
        // Query the Quote object for the GrandTotal field.
        // GrandTotal is a standard roll-up summary field that sums up all line item totals.
        Quote quotationRecord  = [SELECT Id, GrandTotal
                                  FROM Quote  
                                  WHERE Id =: recordId
                                  WITH SECURITY_ENFORCED
                                  LIMIT 1];
        
        // Return the GrandTotal. If the record is found, it will be the total amount.
        return quotationRecord.GrandTotal;
    }
}