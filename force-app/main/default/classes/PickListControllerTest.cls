@IsTest
private class PickListControllerTest {

    @IsTest
    static void testGetPickListValuesIntoList() {
        
        // Define a standard object and picklist field that should exist in any Salesforce org.
        String objectName = 'Case';
        String fieldName = 'Status';
        
        Test.startTest();
        
        // Call the AuraEnabled method.
        List<String> picklistValues = PickListController.getPickListValuesIntoList(objectName, fieldName);
            
        Test.stopTest();
            

        System.assert(picklistValues != null, 'The returned list should not be null.');
        System.assert(!picklistValues.isEmpty(), 'The returned list should not be empty.');
        
    }
}