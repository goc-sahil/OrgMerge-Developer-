@isTest
public class CaseBusinessHoursTest {
    
    static Case c;
    
    
    public with sharing class UploadFileMock implements HTTPCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/JSON');
            res.setBody('Your body');
            res.setStatusCode(201);
            return res;
        }
    }
  
	@isTest
    static void testCaseBusinessHrs() {
        
        if (test.isRunningTest()) Test.setMock(HttpCalloutMock.class, new UploadFileMock());

        Time StartTime = Time.newInstance(00,00,00,000);
        Time EndTime = Time.newInstance(23,59,59,999);
        BusinessHours bz = new BusinessHours(MondayStartTime = StartTime , MondayEndTime = EndTime,
                                      TuesdayStartTime = StartTime, TuesdayEndTime= EndTime,
                                      WednesdayStartTime = StartTime, WednesdayEndTime= EndTime,
                                      ThursdayStartTime = StartTime, ThursdayEndTime = EndTime,
                                      FridayStartTime = StartTime, FridayEndTime = EndTime,
                                      SaturdayStartTime = StartTime, SaturdayEndTime = EndTime,
                                      SundayStartTime = StartTime, SundayEndTime = EndTime,
                                      TimeZoneSidKey = 'America/Los_Angeles', isActive = true);  
        
        List<BusinessHours> bhs = [select Id from BusinessHours where isActive = true];
        
        Contact ct = new Contact(LastName = 'Test');
        insert ct;
        
        CaseBusinessHoursTest.c = new Case(
                ContactId = ct.Id,
                Subject='Test',
                Status = 'New',
                BusinessHoursId = bhs[0].Id
            );
        insert c;
        
       
        
    }

}