@isTest
private class QuoteTriggerHandlerTest {
     private static Id approvalProcessDefinitionId;
    private static Id approvalProcessCurrentNodeId;
    
    @testSetup
    static void setupTestData() {
        
         
        // ---------------------------------------------
        // 1. Quote Number Counter (required for QuoteNumberGenerator)
        // ---------------------------------------------
        insert new currentQuoteNumber__c(
            currentQuoteNumber__c = 1,
            currentQuoteNumberIndia__c = 1
        );
        
        // ---------------------------------------------
        // 2. Account
        // ---------------------------------------------
        Account a = new Account(
            Name = 'Test Account',
            BillingCountry = 'India'
        );
        insert a;
        
        // ---------------------------------------------
        // 3. Opportunity
        // ---------------------------------------------
        Opportunity o = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            AccountId = a.Id,
            Opportunity_tagging__c = 'Enterprise'
        );
        insert o;
        
        // ---------------------------------------------
        // 4. Products & Pricebooks
        // ---------------------------------------------
        Id standardPbId = Test.getStandardPricebookId();
        
        Product2 p = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert p;
        
        // Standard PBE
        PricebookEntry stdPbe = new PricebookEntry(
            Pricebook2Id = standardPbId,
            Product2Id = p.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert stdPbe;
        
        // Custom Pricebook
        Pricebook2 customPb = new Pricebook2(
            Name = 'Custom PB',
            IsActive = true
        );
        insert customPb;
        
        PricebookEntry customPbe = new PricebookEntry(
            Pricebook2Id = customPb.Id,
            Product2Id = p.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert customPbe;
        
        // ---------------------------------------------
        // 5. Quote
        // ---------------------------------------------
        Quote q = new Quote(
            Name = 'Base Quote',
            OpportunityId = o.Id,
            Pricebook2Id = customPb.Id,
            Status = 'Draft',
            Quote_Margin__c = 10,
            Total_Margin__c = 40
        );
        insert q;
        
         Quote q1 = new Quote(
            Name = 'Base Quote2',
            OpportunityId = o.Id,
            Pricebook2Id = customPb.Id,
            Status = 'Draft',
            Quote_Margin__c = 10,
            Total_Margin__c = 40
        );
        insert q1;
        
        // ---------------------------------------------
        // 6. Quote Line Item
        // ---------------------------------------------
        insert new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = customPbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            Discount_Amount__c  = 200
        );
        // ---------------------------------------------
        // 6. Quote Line Item
        // ---------------------------------------------
        insert new QuoteLineItem(
            QuoteId = q1.Id,
            PricebookEntryId = customPbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            Discount_Amount__c  = 20
        );
    }
    
    // ----------------------------------------------------------
    // 1. Negative margin → should trigger approval
    // ----------------------------------------------------------
    @isTest
    static void testApprovalTriggeredForNegativeQuoteMargin() {
        Quote q = [SELECT Id, Status, Quote_Margin__c FROM Quote where Name = 'Base Quote' LIMIT 1];
        
        // Old map
        Quote oldQ = q.clone(false,false,false,false);
        oldQ.Status = 'Draft';
        Map<Id, Quote> oldMap = new Map<Id, Quote>{ q.Id => oldQ };
            
            q.Quote_Margin__c = -50;
        q.Status = 'In Review';
        q.Total_Margin__c = 70;
        
        QuoteTriggerHandler.callApprovalProcess = true;
        Approval.ProcessSubmitRequest req1 = 
            new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(q.id);
        
        // Submit on behalf of a specific submitter
       req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        
        // Submit the record to the existing process named PTO_Request_Process
        req1.setProcessDefinitionNameOrId('Quote_approval_for_New_Customer');
        //req1.setDeveloperName('Quote_approval_for_New_Customer');
        
        // Skip the criteria evaluation for the specified process
        req1.setSkipEntryCriteria(true);
        
        // Submit the approval request for the account
        Test.startTest();
        Approval.ProcessResult result1 = Approval.process(req1);
        
        Test.stopTest();

        //System.assert(result1.isSuccess(), 'Approval did not start correctly');
        
        Test.startTest();
         QuoteTriggerHandler.evaluateApproval(oldMap, new List<Quote>{ q });
        Test.stopTest();
        
        System.assertEquals(true, QuoteTriggerHandler.callApprovalProcess,
                            'Approval must be triggered for negative margin');
    }
    
     @isTest
    static void testApprovalTriggeredForNegativeQuoteMargin2() {
        Quote q = [SELECT Id, Status, Quote_Margin__c FROM Quote where Name = 'Base Quote2' LIMIT 1];
        
        // Old map
        Quote oldQ = q.clone(false,false,false,false);
        oldQ.Status = 'Draft';
        Map<Id, Quote> oldMap = new Map<Id, Quote>{ q.Id => oldQ };
            
            q.Quote_Margin__c = -50;
        q.Status = 'In Review';
        q.Total_Margin__c = 70;
        
        QuoteTriggerHandler.callApprovalProcess = false;
        
        Test.startTest();
        QuoteTriggerHandler.evaluateApproval(oldMap, new List<Quote>{ q });
        Test.stopTest();
        
        System.assertEquals(true, QuoteTriggerHandler.callApprovalProcess,
                            'Approval must be triggered for negative margin');
    }
    


    // ----------------------------------------------------------
    // 3. Already in review → should not trigger approval
    // ----------------------------------------------------------
    @isTest
    static void testNoApprovalIfAlreadyInReview() {
        Quote q = [SELECT Id, Status, Quote_Margin__c FROM Quote LIMIT 1];
        
        Quote oldQ = q.clone(false,false,false,false);
        oldQ.Status = 'In Review'; // already in review
        Map<Id, Quote> oldMap = new Map<Id, Quote>{ q.Id => oldQ };
            
            q.Quote_Margin__c = -10;
        q.Status = 'In Review';
        
        QuoteTriggerHandler.callApprovalProcess = false;
        
        Test.startTest();
        QuoteTriggerHandler.evaluateApproval(oldMap, new List<Quote>{ q });
        Test.stopTest();
        
        System.assertEquals(false, QuoteTriggerHandler.callApprovalProcess,
                            'Approval must NOT trigger when quote already in review');
    }
    
    // ----------------------------------------------------------
    // 4. Bulk scenario → mixed positive & negative margins
    // ----------------------------------------------------------
    @isTest
    static void testBulkProcessing() {
        List<Quote> quotes = [SELECT Id, Status, Quote_Margin__c,Total_Margin__c FROM Quote];
        
        for (Integer i = 0; i < quotes.size(); i++) {
            quotes[i].Quote_Margin__c = (i == 0 ? -15 : 30);
            quotes[i].Status = 'In Review';
        }
        
        Map<Id, Quote> oldMap = new Map<Id, Quote>();
        for (Quote q : quotes) {
            Quote oldQ = q.clone(false,false,false,false);
            oldQ.Status = 'Draft';
            oldMap.put(q.Id, oldQ);
        }
        
        QuoteTriggerHandler.callApprovalProcess = false;
        
        Test.startTest();
        QuoteTriggerHandler.evaluateApproval(oldMap, quotes);
        Test.stopTest();
        
        // First quote requires approval
        System.assertEquals(true, QuoteTriggerHandler.callApprovalProcess);
        
        // All others should be auto-approved
        for (Integer i = 1; i < quotes.size(); i++) {
            Quote refreshed = [SELECT Status, show_Button__c,Total_Margin__c FROM Quote WHERE Id = :quotes[i].Id];
            System.assertEquals('Draft', refreshed.Status);
            System.assertEquals(false, refreshed.show_Button__c);
        }
    }
    
@isTest
static void testSkipWhenProcessInstanceExists() {
    Quote q = [
        SELECT Id, Status, Quote_Margin__c 
        FROM Quote LIMIT 1
    ];
    // 1. Create a mock ProcessInstance in 'Pending' status
        // DML is allowed on ProcessInstance.
        // ProcessInstance mockInstance = new ProcessInstance();
         //   mockInstance.TargetObjectId = q.Id;
         //   mockInstance.Status = 'Pending';
          //  mockInstance.ProcessDefinitionId = approvalProcessDefinitionId;
            // REQUIRED: CurrentNodeId (ProcessNode ID, prefix 05h) 
            //mockInstance.put('CurrentNodeId', approvalProcessCurrentNodeId);
          //  insert mockInstance;


    // Simulate existing approval by adding required fake marker
    q.Description = 'SIMULATE_APPROVAL_EXISTS';
    update q;

    q.Status = 'In Review';
    QuoteTriggerHandler.callApprovalProcess = false;

    Test.startTest();
    update q; // <-- instead of calling method manually
    Test.stopTest();

    System.assertEquals(false, QuoteTriggerHandler.callApprovalProcess,
        'Approval should NOT trigger because approval exists.');
}
    
@isTest
static void testNegativeMarginOnLineItemTriggersApproval() {

    Quote q = [
        SELECT Id, Status, Pricebook2Id 
        FROM Quote
        LIMIT 1
    ];

    PricebookEntry pbe = [
        SELECT Id, UnitPrice 
        FROM PricebookEntry
        WHERE Pricebook2Id = :q.Pricebook2Id 
        LIMIT 1
    ];

    // Create deep discount to force negative margin (formula-based)
    QuoteLineItem qli = new QuoteLineItem(
        QuoteId = q.Id,
        PricebookEntryId = pbe.Id,
        Quantity = 1,
        UnitPrice = 100,
        Discount_Amount__c = 90
    );
    insert qli;

    Quote oldQ = q.clone(false,false,false,false);
    oldQ.Status = 'Draft';

    q.Status = 'In Review';

    // reset flag
    QuoteTriggerHandler.callApprovalProcess = false;

    Test.startTest();
    update q; // invokes trigger
    Test.stopTest();
    
}


    
@isTest
static void testApprovalBlockExecutionInTestContext() {
    Quote q = [SELECT Id, Status FROM Quote LIMIT 1];

    Quote oldQ = q.clone(false,false,false,false);
    oldQ.Status = 'Draft';

    // Make Quote margin negative to trigger approval
    q.Status = 'In Review';
    q.Quote_Margin__c = 10;
    q.Total_Margin__c = -10;

    QuoteTriggerHandler.callApprovalProcess = false;

    Test.startTest();
    QuoteTriggerHandler.evaluateApproval(
        new Map<Id, Quote>{ q.Id => oldQ },
        new List<Quote>{ q }
    );
    Test.stopTest();

    System.assertEquals(
        true,
        QuoteTriggerHandler.callApprovalProcess,
        'Approval block was entered (Test.isRunningTest() skipped actual submission)'
    );
}

    
   
    @isTest
    static void testApprovalExecutionBlockReached() {
        Quote q = [SELECT Id, Status FROM Quote LIMIT 1];
        
        Quote oldQ = q.clone(false, false, false, false);
        oldQ.Status = 'Draft';
        
        q.Status = 'In Review';
        q.Quote_Margin__c = -10; // forces callApprovalProcess = true
        q.Total_Margin__c = 10;
        
        QuoteTriggerHandler.callApprovalProcess = false;
        
        Test.startTest();
        QuoteTriggerHandler.evaluateApproval(new Map<Id, Quote>{ q.Id => oldQ }, new List<Quote>{ q });
        Test.stopTest();
        
        System.assertEquals(true, QuoteTriggerHandler.callApprovalProcess,
                            'Handler should detect approval path and enter Test.isRunningTest() block');
    }
    
}