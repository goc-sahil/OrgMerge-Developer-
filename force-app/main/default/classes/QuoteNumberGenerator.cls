public with sharing class QuoteNumberGenerator {
    public static void generateQuoteNumbers(List<Quote> quotes) {
        Set<Id> oppIds = new Set<Id>();
        for (Quote quote : quotes) {
            if (quote.OpportunityId != null) {
                oppIds.add(quote.OpportunityId);
            }
        }

        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(
            [SELECT Id, Account.BillingCountry FROM Opportunity WHERE Id IN :oppIds WITH SECURITY_ENFORCED]
        );

        for (Quote quote : quotes) {
            Opportunity opp = opportunityMap.get(quote.OpportunityId);
            String generatedQuoteNumber;
            
            if (opp != null && opp.Account != null && opp.Account.BillingCountry == 'India') {
                generatedQuoteNumber = generateNextQuoteNumber('EAI', true);
            } else {
                generatedQuoteNumber = generateNextQuoteNumber('EAC', false);
            }
        
            quote.Quote_Number_Constant__c = generatedQuoteNumber;
        
            // Set initial PDF version same as quote number
            if (String.isBlank(quote.Quote_PDF_Version__c)) {
                quote.Quote_PDF_Version__c = generatedQuoteNumber;
            }
        }
    }

    @TestVisible
    private static String generateNextQuoteNumber(String prefix, Boolean isIndia) {
        currentQuoteNumber__c quoteCounter = currentQuoteNumber__c.getOrgDefaults();
        
        Integer currentNumber = isIndia ? 
            quoteCounter.currentQuoteNumberIndia__c.intValue() : 
            quoteCounter.currentQuoteNumber__c.intValue();
    
        String paddedNumber = String.valueOf(currentNumber).leftPad(6, '0');
        String finalQuoteNumber = prefix + paddedNumber;
    
        if (isIndia) {
            quoteCounter.currentQuoteNumberIndia__c = currentNumber + 1;
        } else {
            quoteCounter.currentQuoteNumber__c = currentNumber + 1;
        }
        try {
            // Check CRUD access before update
            //if (Schema.sObjectType.currentQuoteNumber__c.isUpdateable()) {
                update quoteCounter;
            //} 
        } catch (DmlException e) {
            // Handle DML exception if needed
            System.debug('Error updating quote counter: ' + e.getMessage());
        }
    
        return finalQuoteNumber;
    }
}




// public class QuoteNumberGenerator {
//     public static void generateQuoteNumbers(List<Quote> quotes) {
//         Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
//         String quoteNumber;
//         for (Quote quote : quotes) {
//             // Retrieve Opportunity details
//             Opportunity opp = opportunityMap.get(quote.OpportunityId);
//             if (opp == null) {
//                 opp = [SELECT Id, Account.BillingCountry 
//                        FROM Opportunity 
//                        WHERE Id = :quote.OpportunityId
//                        WITH SECURITY_ENFORCED];
//                 opportunityMap.put(opp.Id, opp);
//             }
//             if(opp.Account != null && opp.Account.BillingCountry == 'India'){
//                 String prefix = 'EAI';
//                 quoteNumber = generateQuoteNumberIndia(prefix, opp.Id);
//             }
//             else{
//                 String prefix = 'EAC';
//                 quoteNumber = generateQuoteNumber(prefix, opp.Id);
//             }
//             quote.Quote_Number_Constant__c = quoteNumber;
//         }
//     }
//     @TestVisible
//     private static String generateQuoteNumber(String prefix, Id opportunityId) {
//         Integer versionNumber = 1;
//         String autonumberPart = ''; // Replace with the constant part of the quote number

//         String quoteNumber = prefix + autonumberPart;

//         // Query existing quotes for the same opportunity
//         List<Quote> existingQuotes = [SELECT Id, Quote_Number_Constant__c 
//                                       FROM Quote 
//                                       WHERE OpportunityId = :opportunityId 
//                                       WITH SECURITY_ENFORCED
//                                       ORDER BY Quote_Number_Constant__c ASC
//                                       ];
//         String finalQuoteNumber;
//         // Check if there are existing quotes
//         if (!existingQuotes.isEmpty()) {
//            finalQuoteNumber = existingQuotes[0].Quote_Number_Constant__c + 'V' + String.valueOf(existingQuotes.size()+1);
//         }
        
//         else{
            
//             currentQuoteNumber__c quoteNumberInstance = currentQuoteNumber__c.getInstance();
//             System.debug('1'+quoteNumberInstance);
//             String numberString = String.valueOf(Integer.valueOf(quoteNumberInstance.currentQuoteNumber__c));
//             System.debug('2'+numberString);
//             // Calculate the number of zeros to add
//             Integer zerosToAdd = 6 - numberString.length();
//             // Create a string with zerosToAdd number of zeros
//             String zeroPadding = '';
//             for (Integer i = 0; i < zerosToAdd; i++) {
//                 zeroPadding += '0';
//             }
//              // Concatenate the zero padding with the number string
//             String paddedNumber = zeroPadding + numberString;

//             finalQuoteNumber = prefix + paddedNumber;
     
//             currentQuoteNumber__c quoteNumberToUpdate = currentQuoteNumber__c.getOrgDefaults();
//             quoteNumberToUpdate.currentQuoteNumber__c = quoteNumberInstance.currentQuoteNumber__c+1;
//             update quoteNumberToUpdate;
//         }

//         //system.debug('finalQuoteNumber'+finalQuoteNumber);
//         return finalQuoteNumber;
//     }
//     @TestVisible
//     private static String generateQuoteNumberIndia(String prefix, Id opportunityId) {
//         Integer versionNumber = 1;
//         String autonumberPart = ''; // Replace with the constant part of the quote number

//         String quoteNumber = prefix + autonumberPart;

//         // Query existing quotes for the same opportunity
//         List<Quote> existingQuotes = [SELECT Id, Quote_Number_Constant__c 
//                                       FROM Quote 
//                                       WHERE OpportunityId = :opportunityId 
//                                       WITH SECURITY_ENFORCED
//                                       ORDER BY Quote_Number_Constant__c ASC 
//                                       ];
//         String finalQuoteNumber;
//         // Check if there are existing quotes
//         if (!existingQuotes.isEmpty()) {
//            finalQuoteNumber = existingQuotes[0].Quote_Number_Constant__c + 'V' + String.valueOf(existingQuotes.size()+1);
//         }
        
//         else{
            
//             currentQuoteNumber__c quoteNumberInstance = currentQuoteNumber__c.getInstance();
//             String numberString = String.valueOf(Integer.valueOf(quoteNumberInstance.currentQuoteNumberIndia__c));
//             // Calculate the number of zeros to add
//             Integer zerosToAdd = 6 - numberString.length();
//             // Create a string with zerosToAdd number of zeros
//             String zeroPadding = '';
//             for (Integer i = 0; i < zerosToAdd; i++) {
//                 zeroPadding += '0';
//             }
//              // Concatenate the zero padding with the number string
//             String paddedNumber = zeroPadding + numberString;

//             finalQuoteNumber = prefix + paddedNumber;
     
//             currentQuoteNumber__c quoteNumberToUpdate = currentQuoteNumber__c.getOrgDefaults();
//             quoteNumberToUpdate.currentQuoteNumberIndia__c = quoteNumberInstance.currentQuoteNumberIndia__c+1;
//             update quoteNumberToUpdate;
//         }

//         //system.debug('finalQuoteNumber'+finalQuoteNumber);
//         return finalQuoteNumber;
//     }
// }