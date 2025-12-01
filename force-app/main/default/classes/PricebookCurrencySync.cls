public with sharing class PricebookCurrencySync {

    // Method for static pricebook (backward compatibility)
    @AuraEnabled
    public static String syncUSDtoCADStatic(String staticPricebookId) {
        try {
            // Validate pricebook ID
            if (String.isBlank(staticPricebookId)) {
                throw new AuraHandledException('Pricebook ID is required');
            }

            // Fetch the CAD conversion rate
            Decimal cadRate = getCADConversionRate();

            // Sync the specific pricebook
            Integer updatedCount = syncSinglePricebook(staticPricebookId, cadRate);

            return 'Successfully updated ' + updatedCount + ' CAD pricebook entries using rate: ' + cadRate;
        } catch (Exception e) {
            throw new AuraHandledException('Error in syncUSDtoCADStatic: ' + e.getMessage());
        }
    }

    // Main method to update ALL pricebooks containing CAD prices
    @AuraEnabled
    public static String syncAllPricebooksWithCAD() {
        try {
            // Fetch the CAD conversion rate
            Decimal cadRate = getCADConversionRate();

            // Get all pricebooks that have CAD entries
            Set<Id> pricebooksWithCAD = getPricebooksWithCADEntries();

            if (pricebooksWithCAD.isEmpty()) {
                return 'No pricebooks found with CAD entries.';
            }

            // Process each pricebook
            Integer totalUpdated = 0;
            Integer pricebooksProcessed = 0;
            List<String> errorMessages = new List<String>();

            for (Id pricebookId : pricebooksWithCAD) {
                try {
                    Integer updated = syncSinglePricebook(pricebookId, cadRate);
                    totalUpdated += updated;
                    pricebooksProcessed++;
                } catch (Exception e) {
                    errorMessages.add('Pricebook ' + pricebookId + ': ' + e.getMessage());
                }
            }

            String result = 'Successfully processed ' + pricebooksProcessed + ' pricebook(s). ';
            result += 'Updated ' + totalUpdated + ' CAD entries using rate: ' + cadRate;

            if (!errorMessages.isEmpty()) {
                result += '\nWarnings: ' + String.join(errorMessages, '; ');
            }

            return result;

        } catch (Exception e) {
            throw new AuraHandledException('Error in syncAllPricebooksWithCAD: ' + e.getMessage());
        }
    }

    // Helper method to sync a single pricebook
    private static Integer syncSinglePricebook(String pricebookId, Decimal cadRate) {
        
        // Fetch all entries for this pricebook (both USD and CAD)
        List<PricebookEntry> allEntries = [
            SELECT Id, Product2Id, UnitPrice, CurrencyIsoCode, Pricebook2Id
            FROM PricebookEntry 
            WHERE Pricebook2Id = :pricebookId
            AND IsActive = true
            AND CurrencyIsoCode IN ('USD', 'CAD')
        ];

        // Separate USD and CAD entries by Product
        Map<Id, PricebookEntry> usdEntriesByProduct = new Map<Id, PricebookEntry>();
        Map<Id, PricebookEntry> cadEntriesByProduct = new Map<Id, PricebookEntry>();

        for (PricebookEntry entry : allEntries) {
            if (entry.CurrencyIsoCode == 'USD') {
                usdEntriesByProduct.put(entry.Product2Id, entry);
            } else if (entry.CurrencyIsoCode == 'CAD') {
                cadEntriesByProduct.put(entry.Product2Id, entry);
            }
        }

        // Update CAD prices based on corresponding USD prices
        List<PricebookEntry> entriesToUpdate = new List<PricebookEntry>();

        for (Id productId : cadEntriesByProduct.keySet()) {
            if (usdEntriesByProduct.containsKey(productId)) {
                PricebookEntry cadEntry = cadEntriesByProduct.get(productId);
                PricebookEntry usdEntry = usdEntriesByProduct.get(productId);
                
                // Calculate new CAD price
                cadEntry.UnitPrice = usdEntry.UnitPrice * cadRate;
                entriesToUpdate.add(cadEntry);
            }
        }

        // Bulk update
        if (!entriesToUpdate.isEmpty()) {
            update entriesToUpdate;
            System.debug('✅ Updated ' + entriesToUpdate.size() + ' entries in pricebook: ' + pricebookId);
        }

        return entriesToUpdate.size();
    }

    // Helper method to get all pricebooks with CAD entries
    private static Set<Id> getPricebooksWithCADEntries() {
        Set<Id> pricebookIds = new Set<Id>();

        List<PricebookEntry> cadEntries = [
            SELECT Pricebook2Id
            FROM PricebookEntry
            WHERE CurrencyIsoCode = 'CAD'
            AND IsActive = true
        ];

        for (PricebookEntry entry : cadEntries) {
            pricebookIds.add(entry.Pricebook2Id);
        }

        return pricebookIds;
    }

    // Helper method to get CAD conversion rate
    private static Decimal getCADConversionRate() {
        try {
            CurrencyType cadCurrency = [
                SELECT IsoCode, ConversionRate 
                FROM CurrencyType 
                WHERE IsoCode = 'CAD' 
                AND IsActive = true
                LIMIT 1
            ];
            return cadCurrency.ConversionRate;
        } catch (Exception e) {
            throw new AuraHandledException('CAD currency not found or not active in org: ' + e.getMessage());
        }
    }

    // Backward compatibility method (uses old signature)
    @AuraEnabled
    public static String syncUSDtoCAD(String usdPricebookName, String cadPricebookName) {
        try {
            // Fetch the CAD conversion rate
            Decimal cadRate = getCADConversionRate();

            // Fetch USD and CAD pricebooks
            Pricebook2 usdBook;
            Pricebook2 cadBook;
            
            try {
                usdBook = [SELECT Id FROM Pricebook2 WHERE Name = :usdPricebookName LIMIT 1];
                cadBook = [SELECT Id FROM Pricebook2 WHERE Name = :cadPricebookName LIMIT 1];
            } catch (Exception e) {
                throw new AuraHandledException('Pricebook not found: ' + e.getMessage());
            }

            // Fetch USD PricebookEntries
            Map<Id, PricebookEntry> usdEntriesMap = new Map<Id, PricebookEntry>();
            for (PricebookEntry pbe : [
                SELECT Id, Product2Id, UnitPrice 
                FROM PricebookEntry 
                WHERE Pricebook2Id = :usdBook.Id
                AND IsActive = true
            ]) {
                usdEntriesMap.put(pbe.Product2Id, pbe);
            }

            // Fetch CAD PricebookEntries
            List<PricebookEntry> cadEntries = [
                SELECT Id, Product2Id, UnitPrice 
                FROM PricebookEntry 
                WHERE Pricebook2Id = :cadBook.Id
                AND IsActive = true
            ];

            // Update CAD prices based on USD * CAD rate
            Integer updatedCount = 0;
            for (PricebookEntry cadEntry : cadEntries) {
                if (usdEntriesMap.containsKey(cadEntry.Product2Id)) {
                    PricebookEntry usdEntry = usdEntriesMap.get(cadEntry.Product2Id);
                    cadEntry.UnitPrice = usdEntry.UnitPrice * cadRate;
                    updatedCount++;
                }
            }

            // Bulk update
            if (!cadEntries.isEmpty()) {
                update cadEntries;
                System.debug('✅ CAD Pricebook updated successfully using rate: ' + cadRate);
                return 'Successfully updated ' + updatedCount + ' CAD pricebook entries using rate: ' + cadRate;
            } else {
                return 'No CAD entries found to update.';
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error in syncUSDtoCAD: ' + e.getMessage());
        }
    }

    // Utility method to get pricebook details with CAD entries
    @AuraEnabled(cacheable=true)
    public static List<PricebookInfo> getPricebooksWithCADInfo() {
        List<PricebookInfo> pricebookList = new List<PricebookInfo>();

        // Get all pricebooks with CAD entries
        Map<Id, Integer> cadCountByPricebook = new Map<Id, Integer>();
        Map<Id, Integer> usdCountByPricebook = new Map<Id, Integer>();

        for (AggregateResult ar : [
            SELECT Pricebook2Id, CurrencyIsoCode, COUNT(Id) entryCount
            FROM PricebookEntry
            WHERE CurrencyIsoCode IN ('USD', 'CAD')
            AND IsActive = true
            GROUP BY Pricebook2Id, CurrencyIsoCode
        ]) {
            Id pricebookId = (Id)ar.get('Pricebook2Id');
            String currencyC = (String)ar.get('CurrencyIsoCode');
            Integer count = (Integer)ar.get('entryCount');

            if (currencyC == 'CAD') {
                cadCountByPricebook.put(pricebookId, count);
            } else if (currencyC == 'USD') {
                usdCountByPricebook.put(pricebookId, count);
            }
        }

        // Get pricebook details
        List<Pricebook2> pricebooks = [
            SELECT Id, Name, IsActive, Description
            FROM Pricebook2
            WHERE Id IN :cadCountByPricebook.keySet()
            ORDER BY Name
        ];

        for (Pricebook2 pb : pricebooks) {
            PricebookInfo info = new PricebookInfo();
            info.pricebookId = pb.Id;
            info.pricebookName = pb.Name;
            info.isActive = pb.IsActive;
            info.description = pb.Description;
            info.cadEntryCount = cadCountByPricebook.get(pb.Id);
            info.usdEntryCount = usdCountByPricebook.containsKey(pb.Id) ? 
                                 usdCountByPricebook.get(pb.Id) : 0;
            pricebookList.add(info);
        }

        return pricebookList;
    }

    // Wrapper class for pricebook information
    public class PricebookInfo {
        @AuraEnabled public String pricebookId;
        @AuraEnabled public String pricebookName;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String description;
        @AuraEnabled public Integer cadEntryCount;
        @AuraEnabled public Integer usdEntryCount;
    }
}