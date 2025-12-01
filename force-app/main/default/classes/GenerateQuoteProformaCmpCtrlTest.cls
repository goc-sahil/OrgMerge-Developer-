@isTest
public class GenerateQuoteProformaCmpCtrlTest {
    
    @isTest
    static void testSavePdf() {
        Id quoteId = TestDataFactory.setupTestData();
		String tDate = '20-Oct-2022';
        String dueDate = '20-Oct-2022';
        String paid = '20';
        String paying = '20';
        String remaining = '60';
        String taxAmount = '344';
        String totalGrandAmount = '3333';
        String selectedTaxType = 'IGST';
        String shipVia = 'Courier';
        String index = '1';
        String totalpaidPercentage = '20';
        String totalUnpaidPercentage = '20';
        String paymentTerm = '1';
        Test.startTest();
        GenerateQuoteProformaCmpCtrl.savePdf(quoteId, tDate,dueDate, paid,paying, remaining,taxAmount,totalGrandAmount,
                                            selectedTaxType,shipVia,index,paymentTerm,totalpaidPercentage,totalUnpaidPercentage);
        Test.stopTest();

        ContentVersion cv = [SELECT Id, Title FROM ContentVersion LIMIT 1];
        System.assertNotEquals(null, cv);
    }



    @isTest
    static void testGetTotalQuoteAmount() {
        Id quoteId = TestDataFactory.setupTestData();
        Decimal total = GenerateQuoteProformaCmpCtrl.getTotalQuoteAmount(quoteId);
        System.assertNotEquals(null, total);
    }
}