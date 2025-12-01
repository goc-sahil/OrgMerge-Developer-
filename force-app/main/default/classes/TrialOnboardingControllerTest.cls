@IsTest
private class TrialOnboardingControllerTest {

    @IsTest
    static void testGetTrialDaysLeft() {
        // Call the method
        Test.startTest();
        TrialOnboardingController.ReturnData result = TrialOnboardingController.getTrialDaysLeft();
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Return data should not be null');
        System.assertNotEquals(null, result.orgId, 'Org Id should be returned');
        System.assertNotEquals(null, result.createdDate, 'CreatedDate should be returned');
        System.assertNotEquals(null, result.mydomain, 'MyDomain should be returned');
        
        // Check that days is calculated correctly if TrialExpirationDate exists
        Organization org = [SELECT TrialExpirationDate, CreatedDate FROM Organization LIMIT 1];
        if (org.TrialExpirationDate != null) {
            Long expectedDays = (org.TrialExpirationDate.getTime() - System.now().getTime()) / 1000 / 60 / 60 / 24;
            System.assertEquals(expectedDays, result.days, 'Days should match the difference between TrialExpirationDate and now');
        } else {
            System.assertEquals(null, result.days, 'Days should be null if no TrialExpirationDate');
        }
    }
}