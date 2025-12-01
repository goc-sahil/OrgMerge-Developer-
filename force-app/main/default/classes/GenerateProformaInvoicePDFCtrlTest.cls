@isTest
public class GenerateProformaInvoicePDFCtrlTest {

    @testSetup
    static void setupData() {
        // Create base test data using factory
        TestDataFactory.setupTestData();
    }

    @isTest
    static void testINRFlow() {
        // Get existing Quote (INR flow — assume default test data currency setup)
        Quote qt = [SELECT Id FROM Quote LIMIT 1];

        // Prepare VF page context
        Test.startTest();
        PageReference pageRef = Page.GenerateProformaInvoicePDF;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id', qt.Id);
        ApexPages.currentPage().getParameters().put('ObjectName', 'isQuote');
        ApexPages.currentPage().getParameters().put('paid', '2000');
        ApexPages.currentPage().getParameters().put('paying', '1000');
        ApexPages.currentPage().getParameters().put('remaining', '7000');
        ApexPages.currentPage().getParameters().put('taxAmount', '500');
        ApexPages.currentPage().getParameters().put('totalGrandAmount', '10000');
        ApexPages.currentPage().getParameters().put('selectedTaxType', 'GST');
        ApexPages.currentPage().getParameters().put('dueDate', String.valueOf(System.today()));
        ApexPages.currentPage().getParameters().put('tDate', String.valueOf(System.today()));
        ApexPages.currentPage().getParameters().put('shipVia', 'By Air');
        ApexPages.currentPage().getParameters().put('index', '2');
        ApexPages.currentPage().getParameters().put('totalpaidPercentage', '50');
        ApexPages.currentPage().getParameters().put('totalUnpaidPercentage', '40');
        ApexPages.currentPage().getParameters().put('paymentTerm', 'paymentTerm');

        GenerateProformaInvoicePDFCtrl ctrl = new GenerateProformaInvoicePDFCtrl();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, ctrl.quote, 'Quote should be initialized');
        System.assert(ctrl.hasPaidAmount, 'Paid amount flag should be true');
        System.assertEquals('nd installment', ctrl.indexString.substring(1), 'Index suffix check');
        System.assert(ctrl.hasDiscount(ctrl.quote.QuoteLineItems), 'Discount logic check');
        System.assert(ctrl.hasTax, 'Tax should be marked as true');
        System.assertEquals('$', ctrl.quote.quoteCurrency, 'Currency should be set to $');
        System.assert(ctrl.showDiscountColumn, 'Discount column should be visible');
    }

    @isTest
    static void testUSDFlow() {
        Id pricebookId = Test.getStandardPricebookId();

        // Get base quote from factory data
        Quote qt = [SELECT Id, Name, OpportunityId, CurrencyIsoCode, QuoteAccountId 
                    FROM Quote LIMIT 1];

        // Create a USD opportunity
        Opportunity oppUSD = new Opportunity(
            Name = 'USD Opportunity',
            StageName = 'Prospecting',
            CloseDate = System.today().addDays(5),
            CurrencyIsoCode = 'USD',
            AccountId = qt.QuoteAccountId,
            Engagement_Model__c = 'Direct',
            Opportunity_tagging__c = 'Enterprise',
            End_Customer__c = qt.QuoteAccountId,
            Pricebook2Id = pricebookId
        );
        insert oppUSD;

        // Clone quote to associate with USD Opportunity
        Quote qtUSD = qt.clone(false, false, false, false);
        qtUSD.Name = 'USD Test Quote';
        qtUSD.OpportunityId = oppUSD.Id;
        qtUSD.CurrencyIsoCode = 'USD';
        insert qtUSD;

        // Prepare VF page
        Test.startTest();
        PageReference pageRef = Page.GenerateProformaInvoicePDF;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id', qtUSD.Id);
        ApexPages.currentPage().getParameters().put('ObjectName', 'isQuote');
        ApexPages.currentPage().getParameters().put('paid', '0');
        ApexPages.currentPage().getParameters().put('paying', '0');
        ApexPages.currentPage().getParameters().put('remaining', '10000');
        ApexPages.currentPage().getParameters().put('taxAmount', '0');
        ApexPages.currentPage().getParameters().put('totalGrandAmount', '10000');
        ApexPages.currentPage().getParameters().put('selectedTaxType', 'VAT');
        ApexPages.currentPage().getParameters().put('dueDate', '2024-11-05');
        ApexPages.currentPage().getParameters().put('tDate', '2024-11-01');
        ApexPages.currentPage().getParameters().put('index', '3');
        ApexPages.currentPage().getParameters().put('totalpaidPercentage', '0');
        ApexPages.currentPage().getParameters().put('totalUnpaidPercentage', '100');
		ApexPages.currentPage().getParameters().put('paymentTerm', 'paymentTerm');
        GenerateProformaInvoicePDFCtrl ctrl = new GenerateProformaInvoicePDFCtrl();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, ctrl.quote, 'Quote should be initialized');
        System.assertEquals('$', ctrl.quote.quoteCurrency, 'Currency should be $');
        System.assert(!ctrl.hasPaidAmount, 'Paid amount should be false for USD flow');
    }
}