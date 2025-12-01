@isTest
public class ProductDiscoveryContextDataTest {
    
    @isTest
    static void testGenerateJSONWithValidInputs() {
        // Test data setup
        String testObjectApiName = 'Account';
        String testRecordId = '001000000000001AAA';
        
        // Create input parameter
        ProductDiscoveryAdditionalContextData.FlowInput input = new ProductDiscoveryAdditionalContextData.FlowInput();
        input.objectApiName = testObjectApiName;
        input.recordId = testRecordId;
        
        List<ProductDiscoveryAdditionalContextData.FlowInput> inputs = new List<ProductDiscoveryAdditionalContextData.FlowInput>();
        inputs.add(input);
        
        // Start test
        Test.startTest();
        List<ProductDiscoveryAdditionalContextData.FlowOutput> outputs = ProductDiscoveryAdditionalContextData.generateJSON(inputs);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, outputs, 'Output should not be null');
        System.assertEquals(1, outputs.size(), 'Should return one output');
        
        ProductDiscoveryAdditionalContextData.FlowOutput output = outputs[0];
        System.assertNotEquals(null, output.additionalContextData, 'Additional context data should not be null');
        System.assertEquals(1, output.additionalContextData.size(), 'Should have one context data item');
        
        runtime_industries_cpq.ContextDataInput contextData = output.additionalContextData[0];
        System.assertEquals(testObjectApiName, contextData.nodeName, 'Node name should match object API name');
        System.assertNotEquals(null, contextData.nodeData, 'Node data should not be null');
        System.assertEquals(testRecordId, contextData.nodeData.get('id'), 'Record ID should match');
    }
    
    @isTest
    static void testGenerateJSONWithMultipleInputs() {
        // Test data setup with multiple inputs
        List<ProductDiscoveryAdditionalContextData.FlowInput> inputs = new List<ProductDiscoveryAdditionalContextData.FlowInput>();
        
        ProductDiscoveryAdditionalContextData.FlowInput input1 = new ProductDiscoveryAdditionalContextData.FlowInput();
        input1.objectApiName = 'Account';
        input1.recordId = '001000000000001AAA';
        inputs.add(input1);
        
        ProductDiscoveryAdditionalContextData.FlowInput input2 = new ProductDiscoveryAdditionalContextData.FlowInput();
        input2.objectApiName = 'Opportunity';
        input2.recordId = '006000000000001AAA';
        inputs.add(input2);
        
        // Start test
        Test.startTest();
        List<ProductDiscoveryAdditionalContextData.FlowOutput> outputs = ProductDiscoveryAdditionalContextData.generateJSON(inputs);
        Test.stopTest();
        
        // Assertions - Note: Current implementation uses last input values
        System.assertNotEquals(null, outputs, 'Output should not be null');
        System.assertEquals(1, outputs.size(), 'Should return one output');
        
        ProductDiscoveryAdditionalContextData.FlowOutput output = outputs[0];
        System.assertNotEquals(null, output.additionalContextData, 'Additional context data should not be null');
        
        runtime_industries_cpq.ContextDataInput contextData = output.additionalContextData[0];
        System.assertEquals('Opportunity', contextData.nodeName, 'Node name should match last input object API name');
        System.assertEquals('006000000000001AAA', contextData.nodeData.get('id'), 'Record ID should match last input');
    }
    
    @isTest
    static void testGenerateJSONWithNullValues() {
        // Test with null values
        ProductDiscoveryAdditionalContextData.FlowInput input = new ProductDiscoveryAdditionalContextData.FlowInput();
        input.objectApiName = null;
        input.recordId = null;
        
        List<ProductDiscoveryAdditionalContextData.FlowInput> inputs = new List<ProductDiscoveryAdditionalContextData.FlowInput>();
        inputs.add(input);
        
        // Start test
        Test.startTest();
        List<ProductDiscoveryAdditionalContextData.FlowOutput> outputs = ProductDiscoveryAdditionalContextData.generateJSON(inputs);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, outputs, 'Output should not be null');
        System.assertEquals(1, outputs.size(), 'Should return one output');
        
        ProductDiscoveryAdditionalContextData.FlowOutput output = outputs[0];
        System.assertNotEquals(null, output.additionalContextData, 'Additional context data should not be null');
        
        runtime_industries_cpq.ContextDataInput contextData = output.additionalContextData[0];
        System.assertEquals(null, contextData.nodeName, 'Node name should be null');
        System.assertEquals(null, contextData.nodeData.get('id'), 'Record ID should be null');
    }
    
    @isTest
    static void testGenerateJSONWithEmptyInputList() {
        // Test with empty input list
        List<ProductDiscoveryAdditionalContextData.FlowInput> inputs = new List<ProductDiscoveryAdditionalContextData.FlowInput>();
        
        // Start test
        Test.startTest();
        List<ProductDiscoveryAdditionalContextData.FlowOutput> outputs = ProductDiscoveryAdditionalContextData.generateJSON(inputs);
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, outputs, 'Output should not be null');
        System.assertEquals(1, outputs.size(), 'Should return one output even with empty input');
    }
}