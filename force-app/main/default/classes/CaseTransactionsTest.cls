@IsTest
public class CaseTransactionsTest {
    
    @IsTest
    static void testCheckMultipicklistValues() {
        
        // 1. Create test data
        Case testCase = new Case(
            Subject = 'Test Case',
            Status = 'New',
            Origin = 'Web'
        );
        insert testCase;

        // 2. Prepare the input for the invocable method
        List<CaseTransactions.wrapperX> wrapperList = new List<CaseTransactions.wrapperX>();
        
        // Create an instance of the wrapper class.
        CaseTransactions.wrapperX wrap = new CaseTransactions.wrapperX();
        
        // Populate the wrapper variables with test data.
        wrap.a1 = new List<String>{'Value1', 'Value2'}; 
        wrap.a2 = new List<ID>{testCase.Id}; 
        
        // Add the populated wrapper instance to the list.
        wrapperList.add(wrap);

        // 3. Invoke the method
        Test.startTest();
        List<String> result = CaseTransactions.checkmultipicklistvalues(wrapperList);
        Test.stopTest();

        // 4. Assertions
        System.assert(result == null, 'The method should return null.');
    }
}