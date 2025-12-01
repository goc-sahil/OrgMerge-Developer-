@isTest
public class TestCaseTriggerHelper {

    @isTest
    public static void testMigrationEnable(){
        
        DeskComMigrationSetting__c defaultCustomSetting = DeskComMigrationSetting__c.getOrgDefaults();
        defaultCustomSetting.isMigrationEnable__c = true;
        insert defaultCustomSetting;
        
        Account a = new Account(name='test');
        insert a;
        
        Contact con = new Contact();
        con.lastname = 'test';
        con.AccountId = a.id;
        
        insert con;
        
        Case ca = new Case();
        ca.ContactId = con.id;
        ca.Subject = 'test';
        ca.labels__c = 'test';
        
        insert ca;
    }
    
    @isTest
    public static void testMigrationDisable(){
        
        DeskComMigrationSetting__c defaultCustomSetting = DeskComMigrationSetting__c.getOrgDefaults();
        defaultCustomSetting.isMigrationEnable__c = false;
        insert defaultCustomSetting;
        
        Account a = new Account(name='test');
        insert a;
        
        Contact con = new Contact();
        con.lastname = 'test';
        con.AccountId = a.id;
        
        insert con;
        
        Case ca = new Case();
        ca.ContactId = con.id;
        ca.Subject = 'test';
        ca.labels__c = 'test,Other Department Dependency,Engineering Pending,XYZ';
        insert ca;
        
        Case udpatedCase = new Case();
        udpatedCase.status = 'Open';
        udpatedCase.id = ca.id;
        udpatedCase.Case_Open_Age_Total__c = '0 Hours 0 minutes';
        udpatedCase.Labels_Pickval__c = 'Other Department Dependency Completed';
        udpatedCase.custom_category__c = 'Control4 Driver Issue';
        upsert udpatedCase;
        
        udpatedCase = new Case();
        udpatedCase.status = 'Pending';
        udpatedCase.id = ca.id;
        upsert udpatedCase;
        
        Case udpatedCase1 = new Case();
        udpatedCase1.id = ca.id;
        udpatedCase1.Labels_Pickval__c = 'Engineering Pending';
        upsert udpatedCase1;
        
        Case udpatedCase2 = new Case();
        udpatedCase2.id = ca.id;
        udpatedCase2.Labels_Pickval__c = 'Engineering Completed';
        upsert udpatedCase2;
        
    }
}