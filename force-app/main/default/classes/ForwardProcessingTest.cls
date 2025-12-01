@isTest
global class ForwardProcessingTest {    
    
    global with sharing class UploadFileMock implements HTTPCalloutMock{
        global HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/JSON');
            res.setBody('Your body');
            res.setStatusCode(201);
            return res;
        }
    }
    
    @isTest
    static void testForwardProcessing() {
        if (test.isRunningTest()) Test.setMock(HttpCalloutMock.class, new UploadFileMock());
        String userEmail = [select email from user where isactive=true and usertype='Standard'][0].email;
        Case c = new Case(
                Subject='Fwd: Hello world',
                description = 'From: Test, User <naveen.%-_123name@salesforce.com> Date: Sun, Oct 29, 2017 at 3:35 PM Subject: Test Forward Processing',
                SuppliedEmail = userEmail,
                Status = 'New'
            );
        insert c;
        
        ID[] test1 = new ID[1];
        test1[0] = c.id;
        ForwardProcessing.forwarProcessing(test1);
        
        c = new Case(
                Subject='Fwd: Hello world 2',
                description = 'From: Test, User <naveen.%-_123name@salesforce.com> Date: Sun, Oct 29, 2017 at 3:35 PM Subject: Test Forward Processing',
                SuppliedEmail = userEmail,
                Status = 'New'
            );
        insert c;
        
        ID[] test2 = new ID[1];
        test2[0] = c.id;
        ForwardProcessing.forwarProcessing(test2);
        
        c = new Case(
                Subject='Fwd: Hello world 2',
                description = 'From: Test <naveen.%-_1234name@salesforce.com> Date: Sun, Oct 29, 2017 at 3:35 PM Subject: Test Forward Processing',
                SuppliedEmail = userEmail,
                Status = 'New'       
            );
        insert c;
        
        ID[] test3 = new ID[1];
        test3[0] = c.id;
        ForwardProcessing.forwarProcessing(test3);
    }
}