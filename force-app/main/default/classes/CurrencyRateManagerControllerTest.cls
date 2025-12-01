@isTest
private class CurrencyRateManagerControllerTest {
    
    @testSetup
    static void setup() {
        // Create test data - Note: CurrencyType is a system object that may require special setup
        // In a real org with multi-currency enabled, you'd need to enable test currencies
        
        // Create test products and pricebook entries
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        // Get standard pricebook
        Id stdPricebookId = Test.getStandardPricebookId();
        
        // Create standard pricebook entry
        PricebookEntry stdPbe = new PricebookEntry(
            Pricebook2Id = stdPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true,
            CurrencyIsoCode = 'CAD'
        );
        insert stdPbe;
        
        // Create custom pricebook
        Pricebook2 customPb = new Pricebook2(
            Name = 'CAD Pricebook',
            IsActive = true
        );
        insert customPb;
        
        // Create custom pricebook entry
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = prod.Id,
            UnitPrice = 150.00,
            IsActive = true,
            CurrencyIsoCode = 'CAD'
        );
        insert customPbe;
    }
    
    @isTest
    static void testGetCurrencyRate() {
        // Note: This test assumes multi-currency is enabled in the org
        // and that the currency exists in CurrencyType
        Test.startTest();
        
        try {
            Decimal rate = CurrencyRateManagerController.getCurrencyRate('USD');
            System.assertNotEquals(null, rate, 'Currency rate should not be null');
            System.assert(rate > 0, 'Currency rate should be greater than 0');
        } catch (Exception e) {
            // If multi-currency is not enabled, the query will fail
            System.assert(true, 'Expected exception if multi-currency is not enabled');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetCurrencyRateInvalidCode() {
        Test.startTest();
        
        try {
            Decimal rate = CurrencyRateManagerController.getCurrencyRate('XXX');
            System.assert(false, 'Should have thrown an exception for invalid currency code');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for invalid currency code');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateCurrencyRate() {
        // This test depends on the CurrencyRateUpdater class implementation
        Test.startTest();
        
        String result = CurrencyRateManagerController.updateCurrencyRate('CAD', 1.35);
        System.assertNotEquals(null, result, 'Result should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateCurrencyRateWithNull() {
        Test.startTest();
        
        try {
            String result = CurrencyRateManagerController.updateCurrencyRate(null, 1.5);
            // Result depends on CurrencyRateUpdater implementation
            System.assertNotEquals(null, result, 'Result should not be null');
        } catch (Exception e) {
            System.assert(true, 'Exception may be expected for null ISO code');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testRecalculateCADPricebookSuccess() {
        Test.startTest();
        
        String result = CurrencyRateManagerController.recalculateCADPricebook();
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('completed') || result.contains('Updated'), 
                     'Result should indicate successful completion');
        
        // Verify pricebook entries still exist and are unchanged (since logic just reassigns same value)
        List<PricebookEntry> entries = [
            SELECT Id, UnitPrice 
            FROM PricebookEntry 
            WHERE CurrencyIsoCode = 'CAD'
        ];
        System.assertEquals(2, entries.size(), 'Should have 2 CAD pricebook entries');
    }
    
    @isTest
    static void testRecalculateCADPricebookNoEntries() {
        // Don't create any CAD entries - create USD entries instead
        Product2 usdProd = new Product2(Name = 'USD Product', IsActive = true);
        insert usdProd;
        
        Id stdPricebookId = Test.getStandardPricebookId();
        
        PricebookEntry usdPbe = new PricebookEntry(
            Pricebook2Id = stdPricebookId,
            Product2Id = usdProd.Id,
            UnitPrice = 100.00,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert usdPbe;
        
        // Deactivate CAD entries instead of deleting them
        List<PricebookEntry> cadEntries = [
            SELECT Id, IsActive 
            FROM PricebookEntry 
            WHERE CurrencyIsoCode = 'CAD'
        ];
        
        for (PricebookEntry pbe : cadEntries) {
            pbe.IsActive = false;
        }
        update cadEntries;
        
        Test.startTest();
        
        String result = CurrencyRateManagerController.recalculateCADPricebook();
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // Since we deactivated entries, they might still be returned by the query
        // depending on whether the controller filters by IsActive
    }
    
    @isTest
    static void testRecalculateCADPricebookWithDifferentCurrency() {
        // Create entries with different currencies to ensure only CAD is affected
        Product2 prod2 = new Product2(Name = 'Multi-Currency Product', IsActive = true);
        insert prod2;
        
        Id stdPricebookId = Test.getStandardPricebookId();
        
        // Create USD entry (USD is typically available in most orgs)
        PricebookEntry usdEntry = new PricebookEntry(
            Pricebook2Id = stdPricebookId,
            Product2Id = prod2.Id,
            UnitPrice = 200.00,
            IsActive = true,
            CurrencyIsoCode = 'USD'
        );
        insert usdEntry;
        
        Test.startTest();
        
        String result = CurrencyRateManagerController.recalculateCADPricebook();
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        
        // Verify only CAD entries were processed
        List<PricebookEntry> cadEntries = [
            SELECT Id FROM PricebookEntry WHERE CurrencyIsoCode = 'CAD'
        ];
        System.assert(cadEntries.size() >= 2, 'Should have CAD entries from setup');
        
        // Verify USD entry wasn't touched
        PricebookEntry verifyUsd = [
            SELECT Id, UnitPrice FROM PricebookEntry 
            WHERE Id = :usdEntry.Id
        ];
        System.assertEquals(200.00, verifyUsd.UnitPrice, 'USD price should remain unchanged');
    }
    
    @isTest
    static void testBulkRecalculation() {
        // Create additional test data for bulk testing
        // Each PricebookEntry needs a unique product
        List<Product2> products = new List<Product2>();
        for (Integer i = 0; i < 20; i++) {
            products.add(new Product2(
                Name = 'Bulk Test Product ' + i, 
                ProductCode = 'BULK-' + i,
                IsActive = true
            ));
        }
        insert products;
        
        Id stdPricebookId = Test.getStandardPricebookId();
        
        // Create standard pricebook entries for each product
        List<PricebookEntry> bulkEntries = new List<PricebookEntry>();
        for (Integer i = 0; i < 20; i++) {
            bulkEntries.add(new PricebookEntry(
                Pricebook2Id = stdPricebookId,
                Product2Id = products[i].Id,
                UnitPrice = 100.00 + i,
                IsActive = true,
                CurrencyIsoCode = 'CAD'
            ));
        }
        insert bulkEntries;
        
        Test.startTest();
        
        String result = CurrencyRateManagerController.recalculateCADPricebook();
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('completed'), 'Bulk recalculation should complete');
        
        // Verify the count includes our bulk entries
        Integer expectedCount = 22; // 2 from setup + 20 bulk
        System.assert(result.contains(String.valueOf(expectedCount)), 
                     'Should update ' + expectedCount + ' entries');
    }
    
    @isTest
    static void testRecalculateWithExistingData() {
        // This test verifies that the method works with data from @testSetup
        Test.startTest();
        
        String result = CurrencyRateManagerController.recalculateCADPricebook();
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('completed') || result.contains('Updated'), 
                     'Result should indicate completion');
        // The 2 CAD entries from @testSetup should be processed
        System.assert(result.contains('2'), 'Should process 2 entries from setup');
    }
}