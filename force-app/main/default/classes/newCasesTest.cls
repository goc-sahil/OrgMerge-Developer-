@IsTest
private class newCasesTest {

    @TestSetup
    static void setupTestData() {
        // Create a test Case
        Case testCase1 = new Case(
            Subject = 'Test Case 1',
            Status = 'New',
            Origin = 'Phone',
            Type = 'Problem'
        );
        Case testCase2 = new Case(
            Subject = 'Test Case 2',
            Status = 'Working',
            Origin = 'Email',
            Type = 'Feature'
        );
        insert new List<Case>{testCase1, testCase2};
    }

    @IsTest
    static void testGetCases() {
        // Call the getCases method
        Test.startTest();
        List<Case> cases = newCases.getCases();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(0, cases.size(), 'Case list should not be empty');
        System.assertEquals('Test Case 1', cases[0].Subject, 'First case subject should match');
    }

    @IsTest
    static void testSaveCase_Insert() {
        // Prepare a new case to insert
        Case newCase = new Case(
            Subject = 'Inserted Case',
            Status = 'New',
            Origin = 'Web',
            Type = 'Problem'
        );

        Test.startTest();
        Case savedCase = newCases.saveCase(newCase);
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, savedCase.Id, 'Saved Case should have an Id');
        System.assertEquals('Inserted Case', savedCase.Subject, 'Subject should match');
    }

    @IsTest
    static void testSaveCase_Update() {
        // Get an existing case
        Case existingCase = [SELECT Id, Subject FROM Case LIMIT 1];
        existingCase.Subject = 'Updated Case';

        Test.startTest();
        Case updatedCase = newCases.saveCase(existingCase);
        Test.stopTest();

        // Assertions
        System.assertEquals('Updated Case', updatedCase.Subject, 'Subject should be updated');
    }
}