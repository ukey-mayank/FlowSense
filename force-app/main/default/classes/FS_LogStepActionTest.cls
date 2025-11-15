/**
 * @description Test class for FS_LogStepAction
 * @author FlowSense
 * @version 1.0
 */
@isTest
private class FS_LogStepActionTest {
    
    /**
     * @description Setup test data for all test methods
     */
    @TestSetup
    static void makeData() {
        // Create test data using our factory
        FS_TestDataFactory.createCompleteFlowDataSet('Test_LogStep_Flow_' + String.valueOf(System.currentTimeMillis()));
    }
    
    /**
     * @description Test successful step logging with all fields
     */
    @isTest
    static void testLogStepSuccess() {
        // Get test flow run
        FS_Flow_Run__c flowRun = [SELECT Id FROM FS_Flow_Run__c LIMIT 1];
        
        // Create request with all fields populated
        FS_LogStepAction.Request request = new FS_LogStepAction.Request();
        request.flowRunId = flowRun.Id;
        request.sequence = 1;
        request.elementDeveloperName = 'Test_Assignment';
        request.elementType = 'Assignment';
        request.elementLabel = 'Test Assignment Step';
        request.enteredAt = System.now().addSeconds(-5);
        request.exitedAt = System.now();
        request.durationMs = 5000;
        request.cpuTimeMs = 500;
        request.soqlCount = 2;
        request.dmlCount = 1;
        request.outcome = 'Success';
        request.inputVariables = '{"variable1": "value1"}';
        request.outputVariables = '{"result": "success"}';
        
        Test.startTest();
        
        List<FS_LogStepAction.Result> results = FS_LogStepAction.logFlowStep(new List<FS_LogStepAction.Request>{request});
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Step logging should be successful');
        System.assertNotEquals(null, results[0].stepId, 'Step ID should be populated');
        System.assert(results[0].message.contains('Test_Assignment'), 'Message should contain element name');
        
        // Verify step record was created
        FS_Flow_Step__c step = [SELECT Id, Flow_Run__c, Sequence__c, Element_DeveloperName__c, 
                               Element_Type__c, Element_Label__c, Entered_At__c, Exited_At__c,
                               Outcome__c, Input_Variables__c, Output_Variables__c 
                               FROM FS_Flow_Step__c 
                               WHERE Id = :results[0].stepId];
        
        System.assertEquals(flowRun.Id, step.Flow_Run__c, 'Flow Run ID should match');
        System.assertEquals(1, step.Sequence__c, 'Sequence should match');
        System.assertEquals('Test_Assignment', step.Element_DeveloperName__c, 'Element developer name should match');
        System.assertEquals('Assignment', step.Element_Type__c, 'Element type should match');
        System.assertEquals('Test Assignment Step', step.Element_Label__c, 'Element label should match');
        System.assertEquals('Success', step.Outcome__c, 'Outcome should match');
        System.assertEquals('{"variable1": "value1"}', step.Input_Variables__c, 'Input variables should match');
        System.assertEquals('{"result": "success"}', step.Output_Variables__c, 'Output variables should match');
    }
    
    /**
     * @description Test step logging with minimal required fields only
     */
    @isTest
    static void testLogStepMinimalFields() {
        // Get test flow run
        FS_Flow_Run__c flowRun = [SELECT Id FROM FS_Flow_Run__c LIMIT 1];
        
        // Create request with only required fields
        FS_LogStepAction.Request request = new FS_LogStepAction.Request();
        request.flowRunId = flowRun.Id;
        request.sequence = 2;
        request.elementDeveloperName = 'Minimal_Screen';
        request.elementType = 'Screen';
        
        Test.startTest();
        
        List<FS_LogStepAction.Result> results = FS_LogStepAction.logFlowStep(new List<FS_LogStepAction.Request>{request});
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Step logging should be successful');
        System.assertNotEquals(null, results[0].stepId, 'Step ID should be populated');
        
        // Verify step record was created with minimal data
        FS_Flow_Step__c step = [SELECT Id, Flow_Run__c, Sequence__c, Element_DeveloperName__c, 
                               Element_Type__c, Element_Label__c
                               FROM FS_Flow_Step__c 
                               WHERE Id = :results[0].stepId];
        
        System.assertEquals(flowRun.Id, step.Flow_Run__c, 'Flow Run ID should match');
        System.assertEquals(2, step.Sequence__c, 'Sequence should match');
        System.assertEquals('Minimal_Screen', step.Element_DeveloperName__c, 'Element developer name should match');
        System.assertEquals('Screen', step.Element_Type__c, 'Element type should match');
    }
    
    /**
     * @description Test step logging with error information
     */
    @isTest
    static void testLogStepWithError() {
        // Get test flow run
        FS_Flow_Run__c flowRun = [SELECT Id FROM FS_Flow_Run__c LIMIT 1];
        
        // Create request with error information
        FS_LogStepAction.Request request = new FS_LogStepAction.Request();
        request.flowRunId = flowRun.Id;
        request.sequence = 3;
        request.elementDeveloperName = 'Failed_Decision';
        request.elementType = 'Decision';
        request.elementLabel = 'Failed Decision Step';
        request.enteredAt = System.now().addSeconds(-2);
        request.exitedAt = System.now();
        request.durationMs = 2000;
        request.outcome = 'Error';
        request.errorMessage = 'Test error message for decision failure';
        
        Test.startTest();
        
        List<FS_LogStepAction.Result> results = FS_LogStepAction.logFlowStep(new List<FS_LogStepAction.Request>{request});
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Step logging should be successful even with error data');
        
        // Verify step record was created with error information
        FS_Flow_Step__c step = [SELECT Id, Outcome__c, Error_Message__c
                               FROM FS_Flow_Step__c 
                               WHERE Id = :results[0].stepId];
        
        System.assertEquals('Error', step.Outcome__c, 'Outcome should be Error');
        System.assertEquals('Test error message for decision failure', step.Error_Message__c, 'Error message should match');
    }
    
    /**
     * @description Test bulk step logging with multiple requests
     */
    @isTest
    static void testLogStepBulk() {
        // Get test flow run
        FS_Flow_Run__c flowRun = [SELECT Id FROM FS_Flow_Run__c LIMIT 1];
        
        // Create multiple requests
        List<FS_LogStepAction.Request> requests = new List<FS_LogStepAction.Request>();
        
        for (Integer i = 1; i <= 5; i++) {
            FS_LogStepAction.Request request = new FS_LogStepAction.Request();
            request.flowRunId = flowRun.Id;
            request.sequence = i;
            request.elementDeveloperName = 'Bulk_Element_' + i;
            request.elementType = 'Assignment';
            request.elementLabel = 'Bulk Element ' + i;
            request.durationMs = 1000 * i;
            request.cpuTimeMs = 100 * i;
            requests.add(request);
        }
        
        Test.startTest();
        
        List<FS_LogStepAction.Result> results = FS_LogStepAction.logFlowStep(requests);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(5, results.size(), 'Should return five results');
        
        for (Integer i = 0; i < 5; i++) {
            System.assertEquals(true, results[i].isSuccess, 'Step ' + (i+1) + ' logging should be successful');
            System.assertNotEquals(null, results[i].stepId, 'Step ' + (i+1) + ' ID should be populated');
            System.assert(results[i].message.contains('Bulk_Element_' + (i+1)), 'Message should contain element name');
        }
        
        // Verify all step records were created
        List<FS_Flow_Step__c> steps = [SELECT Id, Sequence__c, Element_DeveloperName__c
                                       FROM FS_Flow_Step__c 
                                       WHERE Element_DeveloperName__c LIKE 'Bulk_Element_%'
                                       ORDER BY Sequence__c];
        
        System.assertEquals(5, steps.size(), 'Should create 5 step records');
        
        for (Integer i = 0; i < 5; i++) {
            System.assertEquals(i + 1, steps[i].Sequence__c, 'Sequence should match');
            System.assertEquals('Bulk_Element_' + (i + 1), steps[i].Element_DeveloperName__c, 'Element name should match');
        }
    }
    
    /**
     * @description Test step logging with invalid Flow Run ID
     */
    @isTest
    static void testLogStepInvalidFlowRunId() {
        // Create request with invalid flow run ID
        FS_LogStepAction.Request request = new FS_LogStepAction.Request();
        request.flowRunId = 'a01000000000000'; // Invalid ID
        request.sequence = 1;
        request.elementDeveloperName = 'Test_Element';
        request.elementType = 'Assignment';
        
        Test.startTest();
        
        List<FS_LogStepAction.Result> results = FS_LogStepAction.logFlowStep(new List<FS_LogStepAction.Request>{request});
        
        Test.stopTest();
        
        // Verify error result
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].isSuccess, 'Step logging should fail with invalid Flow Run ID');
        System.assertNotEquals(null, results[0].errorMessage, 'Error message should be populated');
        System.assert(results[0].errorMessage.contains('Failed to log step'), 'Error message should indicate failure');
    }
    
    /**
     * @description Test step logging with null sequence (should default to 0)
     */
    @isTest
    static void testLogStepNullSequence() {
        // Get test flow run
        FS_Flow_Run__c flowRun = [SELECT Id FROM FS_Flow_Run__c LIMIT 1];
        
        // Create request with null sequence
        FS_LogStepAction.Request request = new FS_LogStepAction.Request();
        request.flowRunId = flowRun.Id;
        request.sequence = null; // This should default to 0
        request.elementDeveloperName = 'Null_Sequence_Element';
        request.elementType = 'Assignment';
        
        Test.startTest();
        
        List<FS_LogStepAction.Result> results = FS_LogStepAction.logFlowStep(new List<FS_LogStepAction.Request>{request});
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Step logging should be successful');
        
        // Verify step record was created with sequence 0
        FS_Flow_Step__c step = [SELECT Id, Sequence__c FROM FS_Flow_Step__c WHERE Id = :results[0].stepId];
        System.assertEquals(0, step.Sequence__c, 'Sequence should default to 0');
    }
    
    /**
     * @description Test debug logging functionality
     */
    @isTest
    static void testDebugLogging() {
        // CMDT Migration: Settings use default values from FS_SettingsUtil
        // No setup needed - FS_SettingsUtil.isDebugLoggingEnabled() returns defaults
        
        // Get test flow run
        FS_Flow_Run__c flowRun = [SELECT Id FROM FS_Flow_Run__c LIMIT 1];
        
        // Create request
        FS_LogStepAction.Request request = new FS_LogStepAction.Request();
        request.flowRunId = flowRun.Id;
        request.sequence = 1;
        request.elementDeveloperName = 'Debug_Test_Element';
        request.elementType = 'Assignment';
        request.durationMs = 3000;
        
        Test.startTest();
        
        List<FS_LogStepAction.Result> results = FS_LogStepAction.logFlowStep(new List<FS_LogStepAction.Request>{request});
        
        Test.stopTest();
        
        // Verify result (debug logging doesn't affect functionality)
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Step logging should be successful with debug enabled');
    }
    
    /**
     * @description Test with empty request list
     */
    @isTest
    static void testLogStepEmptyList() {
        Test.startTest();
        
        List<FS_LogStepAction.Result> results = FS_LogStepAction.logFlowStep(new List<FS_LogStepAction.Request>());
        
        Test.stopTest();
        
        // Verify empty result
        System.assertEquals(0, results.size(), 'Should return empty result list for empty input');
    }
    
    /**
     * @description Test wrapper classes for proper instantiation
     */
    @isTest
    static void testWrapperClasses() {
        // Test Request wrapper
        FS_LogStepAction.Request request = new FS_LogStepAction.Request();
        request.flowRunId = 'test';
        System.assertEquals('test', request.flowRunId, 'Request wrapper should work correctly');
        
        // Test Result wrapper  
        FS_LogStepAction.Result result = new FS_LogStepAction.Result();
        result.isSuccess = true;
        result.message = 'test message';
        System.assertEquals(true, result.isSuccess, 'Result wrapper should work correctly');
        System.assertEquals('test message', result.message, 'Result message should be set correctly');
    }
}
