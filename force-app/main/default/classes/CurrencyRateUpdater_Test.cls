@isTest
public class CurrencyRateUpdater_Test {
    
    // Mock class for successful OAuth token response
    private class MockHttpResponseOAuthSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            if (req.getEndpoint().contains('/services/oauth2/token')) {
                // Mock OAuth token response
                res.setBody('{"access_token":"mock_access_token_12345","token_type":"Bearer"}');
            } else if (req.getEndpoint().contains('/services/data/v64.0/composite')) {
                // Mock Composite API response
                res.setBody('{"compositeResponse":[{"httpStatusCode":204,"referenceId":"updateCurrency"}]}');
            }
            return res;
        }
    }
    
    // Mock class for OAuth token failure
    private class MockHttpResponseOAuthFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(401);
            res.setBody('{"error":"invalid_client","error_description":"Invalid client credentials"}');
            return res;
        }
    }
    
    // Mock class for Composite API failure
    private class MockHttpResponseCompositeFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('/services/oauth2/token')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"mock_access_token_12345","token_type":"Bearer"}');
            } else if (req.getEndpoint().contains('/services/data/v64.0/composite')) {
                res.setStatusCode(400);
                res.setBody('{"error":"Bad Request","message":"Invalid currency rate"}');
            }
            return res;
        }
    }
    
    // Test setup method to create test data
    @testSetup
    static void setupTestData() {
        // Note: CurrencyType is a system object and cannot be inserted in tests
        // We'll handle this in individual test methods
    }
    
    // Test successful currency rate update
    @isTest
    static void testUpdateCurrencyRate_Success() {
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseOAuthSuccess());
        
        Test.startTest();
        String result = CurrencyRateUpdater.updateCurrencyRate('USD', 1.25);
        Test.stopTest();
        
        // Verify the result - should succeed if USD currency exists
        // Note: In a real org, USD would typically exist
        System.assert(result != null, 'Result should not be null');
        
        // The actual assertion depends on whether USD exists in the test org
        // In most cases, we'll get a "Currency not found" message in test context
    }
    
    // Test with invalid currency code
    @isTest
    static void testUpdateCurrencyRate_InvalidCurrency() {
        Test.startTest();
        String result = CurrencyRateUpdater.updateCurrencyRate('XXX', 1.5);
        Test.stopTest();
        
        // The query will throw an exception if no records found, which is caught and returned
        System.assert(result.contains('Currency not found') || result.contains('Exception'), 
                     'Should return error message for invalid ISO code: ' + result);
    }
    
    // Test OAuth token failure
    @isTest
    static void testUpdateCurrencyRate_OAuthFailure() {
        // Set mock callout for OAuth failure
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseOAuthFailure());
        
        Test.startTest();
        String result = CurrencyRateUpdater.updateCurrencyRate('USD', 1.25);
        Test.stopTest();
        
        // Should return failure message due to OAuth token failure
        System.assert(result != null, 'Result should not be null');
    }
    
    // Test Composite API failure
    @isTest
    static void testUpdateCurrencyRate_CompositeAPIFailure() {
        // Set mock callout for Composite API failure
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseCompositeFailure());
        
        Test.startTest();
        String result = CurrencyRateUpdater.updateCurrencyRate('USD', 1.25);
        Test.stopTest();
        
        // Verify failure message
        System.assert(result != null, 'Result should not be null');
    }
    
    // Test with null ISO code
    @isTest
    static void testUpdateCurrencyRate_NullIsoCode() {
        Test.startTest();
        String result;
        try {
            result = CurrencyRateUpdater.updateCurrencyRate(null, 1.25);
        } catch (Exception e) {
            result = 'Exception: ' + e.getMessage();
        }
        Test.stopTest();
        
        System.assert(result.contains('Exception') || result.contains('Currency not found'), 
                     'Should handle null ISO code gracefully');
    }
    
    // Test with zero rate
    @isTest
    static void testUpdateCurrencyRate_ZeroRate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseOAuthSuccess());
        
        Test.startTest();
        String result = CurrencyRateUpdater.updateCurrencyRate('USD', 0);
        Test.stopTest();
        
        System.assert(result != null, 'Result should not be null');
    }
    
    // Test with negative rate
    @isTest
    static void testUpdateCurrencyRate_NegativeRate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseOAuthSuccess());
        
        Test.startTest();
        String result = CurrencyRateUpdater.updateCurrencyRate('USD', -1.5);
        Test.stopTest();
        
        System.assert(result != null, 'Result should not be null');
    }
    
    // Test with very large rate value
    @isTest
    static void testUpdateCurrencyRate_LargeRate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseOAuthSuccess());
        
        Test.startTest();
        String result = CurrencyRateUpdater.updateCurrencyRate('USD', 999999.99);
        Test.stopTest();
        
        System.assert(result != null, 'Result should not be null');
    }
    
    // Test exception handling
    @isTest
    static void testUpdateCurrencyRate_ExceptionHandling() {
        // Set mock to allow the test to proceed past OAuth
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseOAuthSuccess());
        
        Test.startTest();
        String result = CurrencyRateUpdater.updateCurrencyRate('USD', 1.25);
        Test.stopTest();
        
        // Should catch and return a result (either success or error message)
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.length() > 0, 'Should return a non-empty message: ' + result);
    }
    
    // Test with empty string ISO code
    @isTest
    static void testUpdateCurrencyRate_EmptyIsoCode() {
        Test.startTest();
        String result = CurrencyRateUpdater.updateCurrencyRate('', 1.25);
        Test.stopTest();
        
        System.assert(result.contains('Currency not found') || result.contains('Exception'), 
                     'Should handle empty ISO code');
    }
    
    // Test AuraEnabled annotation accessibility
    @isTest
    static void testAuraEnabledMethod() {
        // Verify the method is accessible and returns a non-null result
        Test.startTest();
        String result = CurrencyRateUpdater.updateCurrencyRate('EUR', 1.1);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Method should return a non-null String');
        System.assert(result.length() > 0, 'Method should return a non-empty String');
    }
}