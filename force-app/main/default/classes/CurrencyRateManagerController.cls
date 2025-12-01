public with sharing class CurrencyRateManagerController {

    @AuraEnabled(cacheable=true)
    public static Decimal getCurrencyRate(String isoCode) {
        CurrencyType currencyRec = [SELECT IsoCode, ConversionRate FROM CurrencyType WHERE IsoCode = :isoCode LIMIT 1];
        return currencyRec.ConversionRate;
    }

    @AuraEnabled
    public static String updateCurrencyRate(String isoCode, Decimal newRate) {
        return CurrencyRateUpdater.updateCurrencyRate(isoCode, newRate);
    }

    @AuraEnabled
    public static String recalculateCADPricebook() {
        try {
            // Simple example logic to recalc pricebooks with CAD currency
            List<PricebookEntry> entries = [
                SELECT Id, UnitPrice, CurrencyIsoCode 
                FROM PricebookEntry 
                WHERE CurrencyIsoCode = 'CAD'
            ];
            
            for (PricebookEntry pbe : entries) {
                // Example: multiply by current CAD conversion rate (assuming 1.0 for demo)
                pbe.UnitPrice = pbe.UnitPrice; // Replace with actual recalculation logic
            }
            
            update entries;
            return 'CAD Pricebook recalculation completed. Updated ' + entries.size() + ' entries.';
        } catch (Exception e) {
            return 'Error during recalculation: ' + e.getMessage();
        }
    }
}