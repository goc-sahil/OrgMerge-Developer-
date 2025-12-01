@IsTest
public class CasePresenceControllerTest {
    
    @isTest
    static void mainTest(){
        CasePresenceController.getSessionId();
        Boolean status = CasePresenceController.publishNotification('caseId','userId', 'username', true, true, 'smallPhotoURL');
    }

}