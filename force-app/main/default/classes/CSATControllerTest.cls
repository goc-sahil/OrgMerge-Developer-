@IsTest
public class CSATControllerTest {
    
    public with sharing class UploadFileMock implements HTTPCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/JSON');
            res.setBody('Your body');
            res.setStatusCode(201);
            return res;
        }
    }
    
    @IsTest
    Static void mainTest(){
        
      if (test.isRunningTest()) Test.setMock(HttpCalloutMock.class, new UploadFileMock());
        
      Case c = new Case (Subject = 'Test', Description = 'Test');
      insert c;
        
      CSATController fb = new CSATController();        
    	ApexPages.currentPage().getParameters().put('caseid', c.id);

        
        PageReference pageRef =  fb.saveFeedback();
		
    }
    

}