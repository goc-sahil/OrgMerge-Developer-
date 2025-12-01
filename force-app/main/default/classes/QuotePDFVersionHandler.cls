public with sharing class QuotePDFVersionHandler {
    public static void handlePDFVersioning(List<Quote> newQuotes, Map<Id, Quote> oldMap) {
        for (Quote quote : newQuotes) {
            Quote oldQuote = oldMap.get(quote.Id);

            // If Status changed to 'Draft'
            if (quote.Status != null && quote.Status == 'Draft' &&
                oldQuote != null && oldQuote.Status != 'Draft') {
                
                String baseQuoteNumber = quote.Quote_Number_Constant__c;
                String currentVersion = quote.Quote_PDF_Version__c;

                if (String.isBlank(baseQuoteNumber)) {
                    continue; // Defensive check
                }

                if (String.isBlank(currentVersion)) {
                    quote.Quote_PDF_Version__c = baseQuoteNumber;
                } else {
                    Integer nextVersion = 2;

                    if (currentVersion.contains('V')) {
                        String[] parts = currentVersion.split('V');
                        if (parts.size() == 2) {
                            try {
                                nextVersion = Integer.valueOf(parts[1]) + 1;
                            } catch (Exception e) {
                                System.debug('Error parsing version number: ' + e.getMessage());
                            }
                        }
                    } else {
                        nextVersion = 2;
                    }

                    quote.Quote_PDF_Version__c = baseQuoteNumber + 'V' + nextVersion;
                }
            }
        }
    }
}