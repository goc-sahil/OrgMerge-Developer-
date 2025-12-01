@IsTest
private class CaseRMAApprovalTempltTest {

@TestSetup
static void setupTestData() {
    // Create Case
    Case c = new Case(
        Subject = 'Test Case',
        Origin = 'Phone'
    );
    insert c;

    // Insert RMA record with only required Case__c
    RMA_Device_Detail__c rma1 = new RMA_Device_Detail__c(
        Case__c = c.Id
    );
    insert rma1;
}


    @IsTest
    static void testGetRMAWithRecords() {
        Case c = new Case(
            Subject = 'Test Case',
            Origin = 'Phone'
        );
        insert c;

        // First RMA record with valid picklist values
        RMA_Device_Detail__c rma1 = new RMA_Device_Detail__c(
            Case__c = c.Id,
            of_Devices__c = 2
        );

        // Second RMA record
        RMA_Device_Detail__c rma2 = new RMA_Device_Detail__c(
            Case__c = c.Id,
            of_Devices__c = 1
        );
List<RMA_Device_Detail__c> rmaList = new List<RMA_Device_Detail__c>{rma1, rma2};
insert rmaList;


        CaseRMAApprovalTemplt ctrl = new CaseRMAApprovalTemplt();
        ctrl.caseId = c.Id;

        List<RMA_Device_Detail__c> results = ctrl.getrma();
        System.assertEquals(2, results.size());

        String deviceNumbers = ctrl.getDeviceNumbers();
    }


    @IsTest
    static void testGetDeviceNumbersWithNoRMA() {
        Case c = new Case(
            Subject = 'Empty Case',
            Origin = 'Web'
        );
        insert c;

        CaseRMAApprovalTemplt ctrl = new CaseRMAApprovalTemplt();
        ctrl.caseId = c.Id;

        List<RMA_Device_Detail__c> results = ctrl.getrma();
        System.assertEquals(0, results.size(), 'There should be no RMA records');

        String deviceNumbers = ctrl.getDeviceNumbers();
        System.assertEquals('', deviceNumbers, 'Device numbers should be empty when no RMA exists');
    }
}