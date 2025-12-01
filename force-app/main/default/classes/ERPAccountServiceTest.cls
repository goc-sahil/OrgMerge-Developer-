@IsTest
private class ERPAccountServiceTest {
    
    @IsTest
    static void testCreateAccount_withValidPayload() {
        // Prepare mock REST request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestUri = '/services/apexrest/erp/account';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"name":"Test Account","type":"Customer"}');
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the service method
        ERPAccountService.ResponseWrapper resp = ERPAccountService.createAccount();
        
        // Assertions
        System.assertEquals(201, RestContext.response.statusCode, 'Status code should be 201');
        System.assertEquals('SUCCESS', resp.status, 'Response status should be SUCCESS');
        System.assertEquals('ERP Account received', resp.message, 'Response message mismatch');
        System.assertNotEquals(null, resp.timestamp, 'Timestamp should not be null');
    }
    
    @IsTest
    static void testCreateAccount_withEmptyPayload() {
        // Prepare mock REST request with empty body
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestUri = '/services/apexrest/erp/account';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        
        RestContext.request = req;
        RestContext.response = res;
        
        // Call the service method
        ERPAccountService.ResponseWrapper resp = ERPAccountService.createAccount();
        
        // Assertions
        System.assertEquals(201, RestContext.response.statusCode, 'Status code should be 201');
        System.assertEquals('SUCCESS', resp.status, 'Response status should be SUCCESS');
        System.assertEquals('ERP Account received', resp.message, 'Response message mismatch');
        System.assertNotEquals(null, resp.timestamp, 'Timestamp should not be null');
    }
}