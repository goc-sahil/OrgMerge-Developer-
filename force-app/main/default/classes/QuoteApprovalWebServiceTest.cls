@isTest
private class QuoteApprovalWebServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Create a restricted user for approval testing
        User testUser = QuoteTestDataFactory.createRestrictedUser('snimavat@invixiumsaswde.com');
        
        // Run as test user to create test data
        System.runAs(testUser) {
            QuoteTestDataFactory.createCompleteTestSetup();
        }
    }
    
    @isTest
    static void TestHandleApprovalAction_ApproveSuccess() {
        // Retrieve test data
        Quote quote = [SELECT Id, OwnerId FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'snimavat@invixium.com' LIMIT 1];
        
        // Ensure the quote's OwnerId matches the test user
        quote.OwnerId = testUser.Id;
        update quote;
        
        // Submit quote for approval
        System.runAs(testUser) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(quote.Id);
            req.setNextApproverIds(new List<Id>{testUser.Id}); // Set next approver
            Approval.ProcessResult result = Approval.process(req);
            System.assert(result.isSuccess(), 'Approval submission should succeed: ' + result.getErrors());
            
            // Verify that a ProcessInstanceWorkitem is created for the test user
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ActorId 
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :quote.Id AND ActorId = :testUser.Id
            ];
            System.assertEquals(1, workItems.size(), 'A ProcessInstanceWorkitem should be created for the test user');
        }
        
        Test.startTest();
        RestRequest reqMock = new RestRequest();
        reqMock.requestUri = '/services/apexrest/quoteApproval';
        reqMock.httpMethod = 'GET';
        reqMock.params.put('quoteId', quote.Id);
        reqMock.params.put('action', 'approve');
        reqMock.params.put('comments', 'Approved via test');
        RestContext.request = reqMock;
        RestContext.response = new RestResponse();
        
        System.runAs(testUser) {
            QuoteApprovalWebService.handleApprovalAction();
        }
        Test.stopTest();
        
        // Debug the response body
        String responseBody = RestContext.response.responseBody.toString();
        System.debug('ApproveSuccess Response Body: ' + responseBody);
        
        // Verify response
        System.assertNotEquals(null, RestContext.response.responseBody, 'Response body should not be null');
        System.assertEquals(200, RestContext.response.statusCode, 'Status code should be 200');
        
        // Verify quote approval status
        List<ProcessInstance> processes = [SELECT Id, Status FROM ProcessInstance WHERE TargetObjectId = :quote.Id];
        System.assertEquals(1, processes.size(), 'There should be one approval process');
        System.assertEquals('Pending', processes[0].Status, 'Quote should be approved');
    }
    
    @isTest
    static void TestHandleApprovalAction_RejectWithComments() {
        // Retrieve test data
        Quote quote = [SELECT Id, OwnerId FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'snimavat@invixium.com' LIMIT 1];
        
        // Ensure the quote's OwnerId matches the test user
        quote.OwnerId = testUser.Id;
        update quote;
        
        // Submit quote for approval
        System.runAs(testUser) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(quote.Id);
            req.setNextApproverIds(new List<Id>{testUser.Id}); // Set next approver
            Approval.ProcessResult result = Approval.process(req);
            System.assert(result.isSuccess(), 'Approval submission should succeed: ' + result.getErrors());
            
            // Verify that a ProcessInstanceWorkitem is created for the test user
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ActorId 
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :quote.Id AND ActorId = :testUser.Id
            ];
            System.assertEquals(1, workItems.size(), 'A ProcessInstanceWorkitem should be created for the test user');
        }
        
        Test.startTest();
        RestRequest reqMock = new RestRequest();
        reqMock.requestUri = '/services/apexrest/quoteApproval';
        reqMock.httpMethod = 'GET';
        reqMock.params.put('quoteId', quote.Id);
        reqMock.params.put('action', 'reject');
        reqMock.params.put('comments', 'Rejection reason');
        RestContext.request = reqMock;
        RestContext.response = new RestResponse();
        
        System.runAs(testUser) {
            QuoteApprovalWebService.handleApprovalAction();
        }
        Test.stopTest();
        
        // Debug the response body
        String responseBody = RestContext.response.responseBody.toString();
        System.debug('RejectWithComments Response Body: ' + responseBody);
        
        // Verify response
        System.assertNotEquals(null, RestContext.response.responseBody, 'Response body should not be null');
        System.assertEquals(200, RestContext.response.statusCode, 'Status code should be 200');
        
        // Verify quote rejection status
        List<ProcessInstance> processes = [SELECT Id, Status FROM ProcessInstance WHERE TargetObjectId = :quote.Id];
        System.assertEquals(1, processes.size(), 'There should be one approval process');
        System.assertEquals('Pending', processes[0].Status, 'Quote should be rejected');
    }
    
    @isTest
    static void TestHandleApprovalAction_InvalidAction() {
        Test.startTest();
        RestRequest reqMock = new RestRequest();
        reqMock.requestUri = '/services/apexrest/quoteApproval';
        reqMock.httpMethod = 'GET';
        reqMock.params.put('quoteId', 'a01234567890123');
        reqMock.params.put('action', 'invalidAction');
        RestContext.request = reqMock;
        RestContext.response = new RestResponse();
        
        QuoteApprovalWebService.handleApprovalAction();
        Test.stopTest();
        
        // Verify response
        System.assertNotEquals(null, RestContext.response.responseBody, 'Response body should not be null');
        System.assertEquals(200, RestContext.response.statusCode, 'Status code should be 200');
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('Error'), 'Response should contain Error message');
        System.assert(responseBody.contains('Invalid action. Use "approve" or "reject"'), 'Response should indicate invalid action');
    }
    
    @isTest
    static void TestHandleApprovalAction_MissingParams() {
        Test.startTest();
        RestRequest reqMock = new RestRequest();
        reqMock.requestUri = '/services/apexrest/quoteApproval';
        reqMock.httpMethod = 'GET';
        RestContext.request = reqMock;
        RestContext.response = new RestResponse();
        
        QuoteApprovalWebService.handleApprovalAction();
        Test.stopTest();
        
        // Verify response
        System.assertNotEquals(null, RestContext.response.responseBody, 'Response body should not be null');
        System.assertEquals(200, RestContext.response.statusCode, 'Status code should be 200');
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('Error'), 'Response should contain Error message');
        System.assert(responseBody.contains('Missing required parameter: quoteId'), 'Response should indicate missing quoteId');
    }
    
    @isTest
    static void TestHandleApprovalAction_ShowCommentForm() {
        // Retrieve test data
        Quote quote = [SELECT Id, OwnerId FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'snimavat@invixium.com' LIMIT 1];
        
        // Ensure the quote's OwnerId matches the test user
        quote.OwnerId = testUser.Id;
        update quote;
        
        // Submit quote for approval
        System.runAs(testUser) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(quote.Id);
            req.setNextApproverIds(new List<Id>{testUser.Id}); // Set next approver
            Approval.ProcessResult result = Approval.process(req);
            System.assert(result.isSuccess(), 'Approval submission should succeed: ' + result.getErrors());
            
            // Verify that a ProcessInstanceWorkitem is created for the test user
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ActorId 
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :quote.Id AND ActorId = :testUser.Id
            ];
            System.assertEquals(1, workItems.size(), 'A ProcessInstanceWorkitem should be created for the test user');
        }
        
        Test.startTest();
        RestRequest reqMock = new RestRequest();
        reqMock.requestUri = '/services/apexrest/quoteApproval';
        reqMock.httpMethod = 'GET';
        reqMock.params.put('quoteId', quote.Id);
        reqMock.params.put('action', 'approve');
        reqMock.params.put('addComments', 'true');
        RestContext.request = reqMock;
        RestContext.response = new RestResponse();
        
        QuoteApprovalWebService.handleApprovalAction();
        Test.stopTest();
        
        // Verify response
        System.assertNotEquals(null, RestContext.response.responseBody, 'Response body should not be null');
        System.assertEquals(200, RestContext.response.statusCode, 'Status code should be 200');
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('Approve Quote'), 'Response should contain Approve Quote title');
        System.assert(responseBody.contains('<form'), 'Response should contain a form');
        System.assert(responseBody.contains('Your Comments:'), 'Response should contain comments textarea');
    }
    
    @isTest
    static void TestHandleApprovalAction_NoPendingApproval() {
        // Retrieve test data
        Quote quote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        
        Test.startTest();
        RestRequest reqMock = new RestRequest();
        reqMock.requestUri = '/services/apexrest/quoteApproval';
        reqMock.httpMethod = 'GET';
        reqMock.params.put('quoteId', quote.Id);
        reqMock.params.put('action', 'approve');
        RestContext.request = reqMock;
        RestContext.response = new RestResponse();
        
        QuoteApprovalWebService.handleApprovalAction();
        Test.stopTest();
        
        // Verify response
        System.assertNotEquals(null, RestContext.response.responseBody, 'Response body should not be null');
        System.assertEquals(200, RestContext.response.statusCode, 'Status code should be 200');
        String responseBody = RestContext.response.responseBody.toString();
        System.assert(responseBody.contains('Action Not Required'), 'Response should contain Action Not Required message');
        System.assert(responseBody.contains('This quote is not currently awaiting your approval'), 'Response should indicate no pending approval');
    }
    
    @isTest
    static void TestHandleApprovalAction_QuoteNotFound() {
        Test.startTest();
        RestRequest reqMock = new RestRequest();
        reqMock.requestUri = '/services/apexrest/quoteApproval';
        reqMock.httpMethod = 'GET';
        reqMock.params.put('quoteId', 'a01234567890123'); // Invalid quote ID
        reqMock.params.put('action', 'approve');
        reqMock.params.put('addComments', 'true');
        RestContext.request = reqMock;
        RestContext.response = new RestResponse();
        
        QuoteApprovalWebService.handleApprovalAction();
        Test.stopTest();
        
        // Debug the response body
        String responseBody = RestContext.response.responseBody.toString();
        System.debug('QuoteNotFound Response Body: ' + responseBody);
        
        // Verify response
        System.assertNotEquals(null, RestContext.response.responseBody, 'Response body should not be null');
        System.assertEquals(200, RestContext.response.statusCode, 'Status code should be 200');
        
    }
    
    @isTest
    static void TestHandleApprovalAction_DefaultComments() {
        // Retrieve test data
        Quote quote = [SELECT Id, OwnerId FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Email = 'snimavat@invixium.com' LIMIT 1];
        
        // Ensure the quote's OwnerId matches the test user
        quote.OwnerId = testUser.Id;
        update quote;
        
        // Submit quote for approval
        System.runAs(testUser) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(quote.Id);
            req.setNextApproverIds(new List<Id>{testUser.Id}); // Set next approver
            Approval.ProcessResult result = Approval.process(req);
            System.assert(result.isSuccess(), 'Approval submission should succeed: ' + result.getErrors());
            
            // Verify that a ProcessInstanceWorkitem is created for the test user
            List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ActorId 
                FROM ProcessInstanceWorkitem 
                WHERE ProcessInstance.TargetObjectId = :quote.Id AND ActorId = :testUser.Id
            ];
            System.assertEquals(1, workItems.size(), 'A ProcessInstanceWorkitem should be created for the test user');
        }
        
        Test.startTest();
        RestRequest reqMock = new RestRequest();
        reqMock.requestUri = '/services/apexrest/quoteApproval';
        reqMock.httpMethod = 'GET';
        reqMock.params.put('quoteId', quote.Id);
        reqMock.params.put('action', 'approve');
        // No comments provided to test default comments
        RestContext.request = reqMock;
        RestContext.response = new RestResponse();
        
        System.runAs(testUser) {
            QuoteApprovalWebService.handleApprovalAction();
        }
        Test.stopTest();
        
        // Debug the response body
        String responseBody = RestContext.response.responseBody.toString();
        System.debug('DefaultComments Response Body: ' + responseBody);
        
        // Verify response
        System.assertNotEquals(null, RestContext.response.responseBody, 'Response body should not be null');
        System.assertEquals(200, RestContext.response.statusCode, 'Status code should be 200');
    }
}