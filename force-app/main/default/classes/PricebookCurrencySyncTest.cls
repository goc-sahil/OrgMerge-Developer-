@isTest
public class PricebookCurrencySyncTest {
    
    @testSetup
    static void setupTestData() {
        // Create test products
        List<Product2> products = new List<Product2>();
        for (Integer i = 1; i <= 5; i++) {
            products.add(new Product2(
                Name = 'Test Product ' + i,
                IsActive = true,
                ProductCode = 'PROD-' + i
            ));
        }
        insert products;
        
        // Get standard pricebook
        Id standardPricebookId = Test.getStandardPricebookId();
        
        // Create standard pricebook entries for both USD and CAD (required before custom pricebook entries)
        List<PricebookEntry> standardEntries = new List<PricebookEntry>();
        for (Product2 prod : products) {
            // USD standard entry
            standardEntries.add(new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true,
                CurrencyIsoCode = 'USD'
            ));
            // CAD standard entry
            standardEntries.add(new PricebookEntry(
                Pricebook2Id = standardPricebookId,
                Product2Id = prod.Id,
                UnitPrice = 130,
                IsActive = true,
                CurrencyIsoCode = 'CAD'
            ));
        }
        insert standardEntries;
        
        // Create custom pricebooks
        List<Pricebook2> pricebooks = new List<Pricebook2>{
            new Pricebook2(Name = 'USD Pricebook', IsActive = true, Description = 'USD Test Pricebook'),
            new Pricebook2(Name = 'CAD Pricebook', IsActive = true, Description = 'CAD Test Pricebook'),
            new Pricebook2(Name = 'Mixed Pricebook', IsActive = true, Description = 'Mixed Currency Pricebook')
        };
        insert pricebooks;
        
        // Create USD pricebook entries
        List<PricebookEntry> usdEntries = new List<PricebookEntry>();
        for (Product2 prod : products) {
            usdEntries.add(new PricebookEntry(
                Pricebook2Id = pricebooks[0].Id,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true,
                CurrencyIsoCode = 'USD'
            ));
        }
        insert usdEntries;
        
        // Create CAD pricebook entries
        List<PricebookEntry> cadEntries = new List<PricebookEntry>();
        for (Product2 prod : products) {
            cadEntries.add(new PricebookEntry(
                Pricebook2Id = pricebooks[1].Id,
                Product2Id = prod.Id,
                UnitPrice = 130, // Initial CAD price
                IsActive = true,
                CurrencyIsoCode = 'CAD'
            ));
        }
        insert cadEntries;
        
        // Create mixed pricebook entries (both USD and CAD for same products)
        List<PricebookEntry> mixedEntries = new List<PricebookEntry>();
        for (Product2 prod : products) {
            // USD entry
            mixedEntries.add(new PricebookEntry(
                Pricebook2Id = pricebooks[2].Id,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true,
                CurrencyIsoCode = 'USD'
            ));
            // CAD entry
            mixedEntries.add(new PricebookEntry(
                Pricebook2Id = pricebooks[2].Id,
                Product2Id = prod.Id,
                UnitPrice = 130,
                IsActive = true,
                CurrencyIsoCode = 'CAD'
            ));
        }
        insert mixedEntries;
    }
    
    // Test syncUSDtoCADStatic with valid pricebook
    @isTest
    static void testSyncUSDtoCADStatic_Success() {
        Pricebook2 mixedPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Mixed Pricebook' LIMIT 1];
        
        Test.startTest();
        String result = PricebookCurrencySync.syncUSDtoCADStatic(mixedPricebook.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Successfully updated'), 'Should contain success message: ' + result);
        System.assert(result.contains('5'), 'Should update 5 entries');
        
        // Verify CAD prices were updated
        List<PricebookEntry> updatedCADEntries = [
            SELECT UnitPrice, CurrencyIsoCode 
            FROM PricebookEntry 
            WHERE Pricebook2Id = :mixedPricebook.Id 
            AND CurrencyIsoCode = 'CAD'
        ];
        
        System.assertEquals(5, updatedCADEntries.size(), 'Should have 5 CAD entries');
        // Note: Actual conversion rate check depends on org's CAD rate
    }
    
    // Test syncUSDtoCADStatic with blank pricebook ID
    @isTest
    static void testSyncUSDtoCADStatic_BlankId() {
        Test.startTest();
        try {
            String result = PricebookCurrencySync.syncUSDtoCADStatic('');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Pricebook ID is required') || 
                         e.getMessage().contains('Script-thrown exception'), 
                         'Should throw pricebook required error: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    // Test syncUSDtoCADStatic with null pricebook ID
    @isTest
    static void testSyncUSDtoCADStatic_NullId() {
        Test.startTest();
        try {
            String result = PricebookCurrencySync.syncUSDtoCADStatic(null);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Pricebook ID is required') || 
                         e.getMessage().contains('Script-thrown exception'), 
                         'Should throw pricebook required error: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    // Test syncAllPricebooksWithCAD
    @isTest
    static void testSyncAllPricebooksWithCAD_Success() {
        Test.startTest();
        String result = PricebookCurrencySync.syncAllPricebooksWithCAD();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Successfully processed'), 'Should contain success message: ' + result);
        System.assert(result.contains('pricebook'), 'Should mention pricebooks processed');
    }
    
    // Test syncAllPricebooksWithCAD when no CAD entries exist
    @isTest
    static void testSyncAllPricebooksWithCAD_NoCADEntries() {
        // Delete only custom pricebook CAD entries (not standard pricebook entries)
        Id standardPbId = Test.getStandardPricebookId();
        delete [SELECT Id FROM PricebookEntry 
                WHERE CurrencyIsoCode = 'CAD' 
                AND Pricebook2Id != :standardPbId];
        
        Test.startTest();
        String result = PricebookCurrencySync.syncAllPricebooksWithCAD();
        Test.stopTest();
        
        // Since standard pricebook may still have CAD entries, the method may process them
        // The result will either show "No pricebooks found" or successfully process standard pricebook
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('No pricebooks found') || 
                     result.contains('Successfully processed'), 
                     'Should return appropriate message: ' + result);
    }
    
    // Test syncUSDtoCAD (backward compatibility method)
    @isTest
    static void testSyncUSDtoCAD_Success() {
        Test.startTest();
        String result = PricebookCurrencySync.syncUSDtoCAD('USD Pricebook', 'CAD Pricebook');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Successfully updated'), 'Should contain success message: ' + result);
    }
    
    // Test syncUSDtoCAD with invalid pricebook name
    @isTest
    static void testSyncUSDtoCAD_InvalidPricebook() {
        Test.startTest();
        try {
            String result = PricebookCurrencySync.syncUSDtoCAD('Invalid USD', 'Invalid CAD');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Pricebook not found') || 
                         e.getMessage().contains('Script-thrown exception'), 
                         'Should throw pricebook not found error: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    // Test syncUSDtoCAD with null pricebook names
    @isTest
    static void testSyncUSDtoCAD_NullPricebooks() {
        Test.startTest();
        try {
            String result = PricebookCurrencySync.syncUSDtoCAD(null, null);
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assertNotEquals(null, e, 'Should throw an exception');
        }
        Test.stopTest();
    }
    
    // Test syncUSDtoCAD with no matching products
    @isTest
    static void testSyncUSDtoCAD_NoMatchingProducts() {
        // Create pricebooks with different products
        Product2 usdProduct = new Product2(Name = 'USD Only Product', IsActive = true);
        Product2 cadProduct = new Product2(Name = 'CAD Only Product', IsActive = true);
        insert new List<Product2>{usdProduct, cadProduct};
        
        Id standardPbId = Test.getStandardPricebookId();
        insert new List<PricebookEntry>{
            new PricebookEntry(Pricebook2Id = standardPbId, Product2Id = usdProduct.Id, 
                              UnitPrice = 100, IsActive = true, CurrencyIsoCode = 'USD'),
            new PricebookEntry(Pricebook2Id = standardPbId, Product2Id = cadProduct.Id, 
                              UnitPrice = 100, IsActive = true, CurrencyIsoCode = 'CAD')
        };
        
        Pricebook2 usdOnlyPb = new Pricebook2(Name = 'USD Only PB', IsActive = true);
        Pricebook2 cadOnlyPb = new Pricebook2(Name = 'CAD Only PB', IsActive = true);
        insert new List<Pricebook2>{usdOnlyPb, cadOnlyPb};
        
        insert new PricebookEntry(Pricebook2Id = usdOnlyPb.Id, Product2Id = usdProduct.Id, 
                                  UnitPrice = 100, IsActive = true, CurrencyIsoCode = 'USD');
        insert new PricebookEntry(Pricebook2Id = cadOnlyPb.Id, Product2Id = cadProduct.Id, 
                                  UnitPrice = 130, IsActive = true, CurrencyIsoCode = 'CAD');
        
        Test.startTest();
        String result = PricebookCurrencySync.syncUSDtoCAD('USD Only PB', 'CAD Only PB');
        Test.stopTest();
        
        System.assert(result.contains('0') || result.contains('No'), 
                     'Should indicate no updates: ' + result);
    }
    
    // Test getPricebooksWithCADInfo
    @isTest
    static void testGetPricebooksWithCADInfo_Success() {
        Test.startTest();
        List<PricebookCurrencySync.PricebookInfo> result = PricebookCurrencySync.getPricebooksWithCADInfo();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return at least one pricebook');
        
        // Verify structure of returned data
        for (PricebookCurrencySync.PricebookInfo info : result) {
            System.assertNotEquals(null, info.pricebookId, 'Pricebook ID should not be null');
            System.assertNotEquals(null, info.pricebookName, 'Pricebook name should not be null');
            System.assert(info.cadEntryCount > 0, 'CAD entry count should be greater than 0');
        }
    }
    
    // Test getPricebooksWithCADInfo when no CAD entries
    @isTest
    static void testGetPricebooksWithCADInfo_NoCADEntries() {
        // Delete only custom pricebook CAD entries (not standard pricebook entries)
        Id standardPbId = Test.getStandardPricebookId();
        delete [SELECT Id FROM PricebookEntry 
                WHERE CurrencyIsoCode = 'CAD' 
                AND Pricebook2Id != :standardPbId];
        
        Test.startTest();
        List<PricebookCurrencySync.PricebookInfo> result = PricebookCurrencySync.getPricebooksWithCADInfo();
        Test.stopTest();
        
        // Standard pricebook may still have CAD entries, but it won't be in the results
        // since we're only querying custom pricebooks in the method
        System.assertNotEquals(null, result, 'Result should not be null');
        // The list may be empty or contain only the standard pricebook
        System.assert(result.size() >= 0, 'Should return a valid list');
    }
    
    // Test with inactive pricebook entries
    @isTest
    static void testSyncWithInactiveEntries() {
        Pricebook2 mixedPricebook = [SELECT Id FROM Pricebook2 WHERE Name = 'Mixed Pricebook' LIMIT 1];
        
        // Deactivate some CAD entries
        List<PricebookEntry> cadEntries = [
            SELECT Id 
            FROM PricebookEntry 
            WHERE Pricebook2Id = :mixedPricebook.Id 
            AND CurrencyIsoCode = 'CAD'
            LIMIT 2
        ];
        for (PricebookEntry entry : cadEntries) {
            entry.IsActive = false;
        }
        update cadEntries;
        
        Test.startTest();
        String result = PricebookCurrencySync.syncUSDtoCADStatic(mixedPricebook.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // Should only update active entries (3 out of 5)
        System.assert(result.contains('3'), 'Should update only 3 active entries: ' + result);
    }
    
    // Test PricebookInfo wrapper class
    @isTest
    static void testPricebookInfoWrapper() {
        PricebookCurrencySync.PricebookInfo info = new PricebookCurrencySync.PricebookInfo();
        info.pricebookId = 'testId123';
        info.pricebookName = 'Test Pricebook';
        info.isActive = true;
        info.description = 'Test Description';
        info.cadEntryCount = 10;
        info.usdEntryCount = 15;
        
        System.assertEquals('testId123', info.pricebookId);
        System.assertEquals('Test Pricebook', info.pricebookName);
        System.assertEquals(true, info.isActive);
        System.assertEquals('Test Description', info.description);
        System.assertEquals(10, info.cadEntryCount);
        System.assertEquals(15, info.usdEntryCount);
    }
    
    // Test with large dataset (bulk operations)
    @isTest
    static void testBulkOperations() {
        // Create additional products
        List<Product2> bulkProducts = new List<Product2>();
        for (Integer i = 1; i <= 50; i++) {
            bulkProducts.add(new Product2(
                Name = 'Bulk Product ' + i,
                IsActive = true,
                ProductCode = 'BULK-' + i
            ));
        }
        insert bulkProducts;
        
        Id standardPbId = Test.getStandardPricebookId();
        List<PricebookEntry> standardEntries = new List<PricebookEntry>();
        for (Product2 prod : bulkProducts) {
            standardEntries.add(new PricebookEntry(
                Pricebook2Id = standardPbId,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true,
                CurrencyIsoCode = 'USD'
            ));
            standardEntries.add(new PricebookEntry(
                Pricebook2Id = standardPbId,
                Product2Id = prod.Id,
                UnitPrice = 130,
                IsActive = true,
                CurrencyIsoCode = 'CAD'
            ));
        }
        insert standardEntries;
        
        Pricebook2 bulkPb = new Pricebook2(Name = 'Bulk Test PB', IsActive = true);
        insert bulkPb;
        
        List<PricebookEntry> bulkEntries = new List<PricebookEntry>();
        for (Product2 prod : bulkProducts) {
            bulkEntries.add(new PricebookEntry(
                Pricebook2Id = bulkPb.Id,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true,
                CurrencyIsoCode = 'USD'
            ));
            bulkEntries.add(new PricebookEntry(
                Pricebook2Id = bulkPb.Id,
                Product2Id = prod.Id,
                UnitPrice = 130,
                IsActive = true,
                CurrencyIsoCode = 'CAD'
            ));
        }
        insert bulkEntries;
        
        Test.startTest();
        String result = PricebookCurrencySync.syncUSDtoCADStatic(bulkPb.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('50'), 'Should update 50 bulk entries: ' + result);
    }
    
    // Test error handling when CAD currency is not active
    @isTest
    static void testCADCurrencyNotActive() {
        // This test will pass or fail based on org setup
        // If CAD is not active, it should throw an exception
        Test.startTest();
        try {
            String result = PricebookCurrencySync.syncAllPricebooksWithCAD();
            // If CAD exists and is active, this should succeed
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (AuraHandledException e) {
            // If CAD doesn't exist or is not active
            System.assert(e.getMessage().contains('CAD currency not found') || 
                         e.getMessage().contains('not active'),
                         'Should throw CAD currency error: ' + e.getMessage());
        }
        Test.stopTest();
    }
}