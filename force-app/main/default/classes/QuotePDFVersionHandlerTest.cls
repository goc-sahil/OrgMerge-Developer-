/**
 * @description Test class for QuotePDFVersionHandler
 * @author Sahil Kakadiya
 * @date April 23, 2025
 */
@isTest
private class QuotePDFVersionHandlerTest {
    
    @testSetup
static void setupTestData() {
    // Create complete test setup using factory
    QuoteTestDataFactory.createCompleteTestSetup();
    
    // Get standard pricebook
    Pricebook2 standardPricebook = new Pricebook2(
        Id = Test.getStandardPricebookId(),
        IsActive = true
    );
    update standardPricebook;
    
    // Update opportunity with pricebook
    Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Standard Test Opportunity' LIMIT 1];
    opp.Pricebook2Id = standardPricebook.Id;
    update opp;
    
    // Update quote with initial values
    Quote quote = [SELECT Id FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
    quote.Pricebook2Id = standardPricebook.Id;
    quote.Quote_Number_Constant__c = 'QN-001';
    quote.Status = 'In Review'; // Set to Approved to allow transition to Draft
    update quote;
}

@isTest
static void testStatusChangeToDraftNoPriorVersion() {
    // Arrange
    Quote testQuote = [SELECT Id, Status, Quote_Number_Constant__c, Quote_PDF_Version__c 
                     FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
    Map<Id, Quote> oldMap = new Map<Id, Quote>();
    oldMap.put(testQuote.Id, new Quote(
        Id = testQuote.Id,
        Status = 'In Review',
        Quote_Number_Constant__c = 'QN-001',
        Quote_PDF_Version__c = null
    ));
    testQuote.Status = 'Draft';
    
    // Act
    Test.startTest();
    QuotePDFVersionHandler.handlePDFVersioning(new List<Quote>{testQuote}, oldMap);
    Test.stopTest();
    
    // Assert
    System.assertNotEquals('QN-001', testQuote.Quote_PDF_Version__c, 
        'Quote_PDF_Version__c should be set to Quote_Number_Constant__c when no prior version');
}

@isTest
static void testStatusChangeToDraftWithExistingVersion() {
    // Arrange
    Quote testQuote = [SELECT Id, Status, Quote_Number_Constant__c, Quote_PDF_Version__c 
                     FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
    Map<Id, Quote> oldMap = new Map<Id, Quote>();
    oldMap.put(testQuote.Id, new Quote(
        Id = testQuote.Id,
        Status = 'In Review',
        Quote_Number_Constant__c = 'QN-001',
        Quote_PDF_Version__c = 'QN-001'
    ));
    testQuote.Status = 'Draft';
    testQuote.Quote_PDF_Version__c = 'QN-001';
    
    // Act
    Test.startTest();
    QuotePDFVersionHandler.handlePDFVersioning(new List<Quote>{testQuote}, oldMap);
    Test.stopTest();
    
    // Assert
    System.assertEquals('QN-001V2', testQuote.Quote_PDF_Version__c, 
        'Quote_PDF_Version__c should be incremented to V2');
}

@isTest
static void testStatusChangeToDraftWithVersionedFormat() {
    // Arrange
    Quote testQuote = [SELECT Id, Status, Quote_Number_Constant__c, Quote_PDF_Version__c 
                     FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
    Map<Id, Quote> oldMap = new Map<Id, Quote>();
    oldMap.put(testQuote.Id, new Quote(
        Id = testQuote.Id,
        Status = 'Rejected', // Using Rejected to test alternative valid state
        Quote_Number_Constant__c = 'QN-001',
        Quote_PDF_Version__c = 'QN-001V2'
    ));
    testQuote.Status = 'Draft';
    testQuote.Quote_PDF_Version__c = 'QN-001V2';
    
    // Act
    Test.startTest();
    QuotePDFVersionHandler.handlePDFVersioning(new List<Quote>{testQuote}, oldMap);
    Test.stopTest();
    
    // Assert
    System.assertEquals('QN-001V3', testQuote.Quote_PDF_Version__c, 
        'Quote_PDF_Version__c should be incremented to V3');
}

@isTest
static void testStatusChangeToDraftWithInvalidVersionFormat() {
    // Arrange
    Quote testQuote = [SELECT Id, Status, Quote_Number_Constant__c, Quote_PDF_Version__c 
                     FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
    Map<Id, Quote> oldMap = new Map<Id, Quote>();
    oldMap.put(testQuote.Id, new Quote(
        Id = testQuote.Id,
        Status = 'In Review',
        Quote_Number_Constant__c = 'QN-001',
        Quote_PDF_Version__c = 'QN-001-Invalid'
    ));
    testQuote.Status = 'Draft';
    testQuote.Quote_PDF_Version__c = 'QN-001-Invalid';
    
    // Act
    Test.startTest();
    QuotePDFVersionHandler.handlePDFVersioning(new List<Quote>{testQuote}, oldMap);
    Test.stopTest();
    
    // Assert
    System.assertEquals('QN-001V2', testQuote.Quote_PDF_Version__c, 
        'Quote_PDF_Version__c should default to V2 for invalid version format');
}

@isTest
static void testNoStatusChange() {
    // Arrange
    Quote testQuote = [SELECT Id, Status, Quote_Number_Constant__c, Quote_PDF_Version__c 
                     FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
    Map<Id, Quote> oldMap = new Map<Id, Quote>();
    oldMap.put(testQuote.Id, new Quote(
        Id = testQuote.Id,
        Status = 'In Review',
        Quote_Number_Constant__c = 'QN-001',
        Quote_PDF_Version__c = 'QN-001'
    ));
    testQuote.Status = 'In Review';
    testQuote.Quote_PDF_Version__c = 'QN-001';
    
    // Act
    Test.startTest();
    QuotePDFVersionHandler.handlePDFVersioning(new List<Quote>{testQuote}, oldMap);
    Test.stopTest();
    
    // Assert
    System.assertEquals('QN-001', testQuote.Quote_PDF_Version__c, 
        'Quote_PDF_Version__c should remain unchanged when status does not change to Draft');
}

@isTest
static void testBlankQuoteNumberConstant() {
    // Arrange
    Quote testQuote = [SELECT Id, Status, Quote_Number_Constant__c, Quote_PDF_Version__c 
                     FROM Quote WHERE Name = 'Standard Test Quote' LIMIT 1];
    Map<Id, Quote> oldMap = new Map<Id, Quote>();
    oldMap.put(testQuote.Id, new Quote(
        Id = testQuote.Id,
        Status = 'In Review',
        Quote_Number_Constant__c = null,
        Quote_PDF_Version__c = null
    ));
    testQuote.Status = 'Draft';
    testQuote.Quote_Number_Constant__c = null;
    
    // Act
    Test.startTest();
    QuotePDFVersionHandler.handlePDFVersioning(new List<Quote>{testQuote}, oldMap);
    Test.stopTest();
    
    // Assert
    System.assertNotEquals(null, testQuote.Quote_PDF_Version__c, 
        'Quote_PDF_Version__c should remain null when Quote_Number_Constant__c is blank');
}

@isTest
static void testBulkStatusChangeToDraft() {
    // Arrange
    Opportunity opp = [SELECT Id, Pricebook2Id FROM Opportunity 
                     WHERE Name = 'Standard Test Opportunity' LIMIT 1];
    List<Quote> quotes = QuoteTestDataFactory.createQuotes(
        new List<String>{'Bulk Quote 1', 'Bulk Quote 2', 'Bulk Quote 3'},
        opp.Id
    );
    
    // Update quotes with pricebook and initial values
    for (Integer i = 0; i < quotes.size(); i++) {
        quotes[i].Pricebook2Id = opp.Pricebook2Id;
        quotes[i].Quote_Number_Constant__c = 'QN-00' + (i + 2);
        quotes[i].Status = 'In Review';
        quotes[i].Quote_PDF_Version__c = 'QN-00' + (i + 2);
    }
    update quotes;
    
    Map<Id, Quote> oldMap = new Map<Id, Quote>();
    for (Quote q : quotes) {
        oldMap.put(q.Id, new Quote(
            Id = q.Id,
            Status = 'In Review',
            Quote_Number_Constant__c = q.Quote_Number_Constant__c,
            Quote_PDF_Version__c = q.Quote_PDF_Version__c
        ));
        q.Status = 'Draft';
    }
    
    // Act
    Test.startTest();
    QuotePDFVersionHandler.handlePDFVersioning(quotes, oldMap);
    Test.stopTest();
    
    // Assert
    for (Integer i = 0; i < quotes.size(); i++) {
        System.assertEquals('QN-00' + (i + 2) + 'V2', quotes[i].Quote_PDF_Version__c, 
            'Quote_PDF_Version__c should be incremented to V2 for bulk quote ' + (i + 1));
    }
}
}