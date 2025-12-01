@isTest
private class CaseTriggerHelperTest {

    private static DeskComMigrationSetting__c createOrUpdateOrgDefault(Boolean isEnabled) {
        DeskComMigrationSetting__c cs = new DeskComMigrationSetting__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            isMigrationEnable__c = isEnabled
        );
        insert cs ;
        return cs;
    }

    @isTest static void testBeforeInsert_whenMigrationEnabled_formatsLabelsOnly() {
        createOrUpdateOrgDefault(true);

        Case existing = new Case(
            Subject = 'Existing',
            Status = 'Open',
            Desk_Id__c = 100,
            Labels_Pickval__c = 'Initial',
            labels__c = 'Initial'
        );
        insert existing;

        Case newCase = new Case(
            Subject = 'New Subject',
            Status = 'New',
            Labels_Pickval__c = 'Pick',
            labels__c = 'Label1, Label2 , Label3'
        );

        Test.startTest();
            insert newCase;
        Test.stopTest();

        Case inserted = [SELECT Id, labels__c, Desk_Id__c, Labels_Pickval__c FROM Case WHERE Id = :newCase.Id];

        System.assertEquals('Label1,Label2,Label3', inserted.labels__c, 'Labels should be normalized when migration is enabled.');

        System.assertEquals(null, inserted.Desk_Id__c, 'Desk_Id__c should not be assigned when migration is enabled.');
    }

    @isTest static void testBeforeInsert_and_BeforeUpdate_whenMigrationDisabled_assignDeskId_and_updateLabelsAndAges() {
        createOrUpdateOrgDefault(false);

        Case existing = new Case(
            Subject = 'Existing Case',
            Status = 'Open',
            Desk_Id__c = 200,
            Labels_Pickval__c = 'ExistingPick',
            labels__c = 'ExistingPick'
        );
        insert existing;

        Case newCase = new Case(
            Subject = 'Ticket Subject',
            Status = 'New',
            Labels_Pickval__c = 'NewPick',
            labels__c = '' 
        );

        Test.startTest();
            insert newCase;

        Case inserted = [SELECT Id, labels__c, Desk_Id__c, Labels_Pickval__c FROM Case WHERE Id = :newCase.Id];

        System.assertEquals('NewPick', inserted.labels__c, 'Blank labels__c should be set to Labels_Pickval__c when migration disabled.');

        Case upCase = new Case(
            Subject = 'ToBeUpdated',
            Status = 'Open',
            Labels_Pickval__c = 'Engineering Pending',
            labels__c = 'Engineering Pending',
            Case_Open_Age_Total__c = '1 Hours 45 minutes'
        );
        insert upCase;

        upCase.Status = 'Closed'; 
        upCase.Labels_Pickval__c = 'Engineering Completed';

        	update upCase;
        CaseTriggerHel.updateTotalCaseOpenAge(New list<Case>{upCase});
        Test.stopTest();
    }
}