/**
 * @description Test class for FS_LogEndAction
 * @author FlowSense
 * @version 1.0
 */
@isTest
private class FS_LogEndActionTest {
    
    /**
     * @description Setup test data for all test methods
     */
    @TestSetup
    static void makeData() {
        // Create test data using our factory
        FS_TestDataFactory.createCompleteFlowDataSet('Test_LogEnd_Flow_' + String.valueOf(System.currentTimeMillis()));
    }
    
    /**
     * @description Test successful flow logging end with all fields
     */
    @isTest
    static void testEndLoggingSuccess() {
        // Get test flow run and set it to running state
        FS_Flow_Run__c flowRun = [SELECT Id, Interview_Id__c, Start_Time__c FROM FS_Flow_Run__c LIMIT 1];
        flowRun.Status__c = 'Running';
        flowRun.Start_Time__c = System.now().addMinutes(-5);
        update flowRun;
        
        // Create request with all fields populated
        FS_LogEndAction.LogEndRequest request = new FS_LogEndAction.LogEndRequest();
        request.interviewId = flowRun.Interview_Id__c;
        request.status = 'Success';
        request.totalCpuMillis = 5000;
        request.totalSoqlCount = 10;
        request.totalDmlCount = 5;
        
        Test.startTest();
        
        List<FS_LogEndAction.LogEndResult> results = FS_LogEndAction.endLogging(
            new List<FS_LogEndAction.LogEndRequest>{request}
        );
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'End logging should be successful');
        System.assertEquals('Flow logging ended successfully', results[0].message, 'Success message should be correct');
        
        // Verify Flow Run record was updated
        FS_Flow_Run__c updatedFlowRun = [SELECT Id, Status__c, End_Time__c, Duration_Ms__c,
                                         CPU_Time__c, SOQL_Queries__c, DML_Statements__c, Error_Details__c
                                         FROM FS_Flow_Run__c 
                                         WHERE Id = :flowRun.Id];
        
        System.assertEquals('Success', updatedFlowRun.Status__c, 'Status should be updated');
        System.assertNotEquals(null, updatedFlowRun.End_Time__c, 'End time should be populated');
        System.assertNotEquals(null, updatedFlowRun.Duration_Ms__c, 'Duration should be calculated');
        System.assertEquals(5000, updatedFlowRun.CPU_Time__c, 'CPU time should match');
        System.assertEquals(10, updatedFlowRun.SOQL_Queries__c, 'SOQL count should match');
        System.assertEquals(5, updatedFlowRun.DML_Statements__c, 'DML count should match');
        System.assertEquals(null, updatedFlowRun.Error_Details__c, 'Error details should be null for success');
    }
    
    /**
     * @description Test flow logging end with error status
     */
    @isTest
    static void testEndLoggingWithError() {
        // Get test flow run and set it to running state
        FS_Flow_Run__c flowRun = [SELECT Id, Interview_Id__c FROM FS_Flow_Run__c LIMIT 1];
        flowRun.Status__c = 'Running';
        flowRun.Start_Time__c = System.now().addMinutes(-2);
        update flowRun;
        
        // Create request with error information
        FS_LogEndAction.LogEndRequest request = new FS_LogEndAction.LogEndRequest();
        request.interviewId = flowRun.Interview_Id__c;
        request.status = 'Failed';
        request.errorMessage = 'Test error occurred during flow execution';
        request.totalCpuMillis = 2000;
        request.totalSoqlCount = 3;
        request.totalDmlCount = 1;
        
        Test.startTest();
        
        List<FS_LogEndAction.LogEndResult> results = FS_LogEndAction.endLogging(
            new List<FS_LogEndAction.LogEndRequest>{request}
        );
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'End logging should be successful even with error status');
        
        // Verify Flow Run record was updated with error information
        FS_Flow_Run__c updatedFlowRun = [SELECT Id, Status__c, Error_Details__c, CPU_Time__c
                                         FROM FS_Flow_Run__c 
                                         WHERE Id = :flowRun.Id];
        
        System.assertEquals('Failed', updatedFlowRun.Status__c, 'Status should be Failed');
        System.assertEquals('Test error occurred during flow execution', updatedFlowRun.Error_Details__c, 'Error details should match');
        System.assertEquals(2000, updatedFlowRun.CPU_Time__c, 'CPU time should match');
    }
    
    /**
     * @description Test flow logging end with minimal required fields (auto-detect limits)
     */
    @isTest
    static void testEndLoggingMinimalFields() {
        // Get test flow run and set it to running state
        FS_Flow_Run__c flowRun = [SELECT Id, Interview_Id__c FROM FS_Flow_Run__c LIMIT 1];
        flowRun.Status__c = 'Running';
        flowRun.Start_Time__c = System.now().addMinutes(-1);
        update flowRun;
        
        // Create request with only required fields (should auto-detect current limits)
        FS_LogEndAction.LogEndRequest request = new FS_LogEndAction.LogEndRequest();
        request.interviewId = flowRun.Interview_Id__c;
        
        Test.startTest();
        
        List<FS_LogEndAction.LogEndResult> results = FS_LogEndAction.endLogging(
            new List<FS_LogEndAction.LogEndRequest>{request}
        );
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'End logging should be successful');
        
        // Verify Flow Run record was updated with auto-detected values
        FS_Flow_Run__c updatedFlowRun = [SELECT Id, Status__c, CPU_Time__c, SOQL_Queries__c, DML_Statements__c
                                         FROM FS_Flow_Run__c 
                                         WHERE Id = :flowRun.Id];
        
        System.assertEquals('Success', updatedFlowRun.Status__c, 'Status should default to Success');
        System.assertNotEquals(null, updatedFlowRun.CPU_Time__c, 'CPU time should be auto-detected');
        System.assertNotEquals(null, updatedFlowRun.SOQL_Queries__c, 'SOQL count should be auto-detected');
        System.assertNotEquals(null, updatedFlowRun.DML_Statements__c, 'DML count should be auto-detected');
    }
    
    /**
     * @description Test bulk flow logging end with multiple requests
     */
    @isTest
    static void testEndLoggingBulk() {
        // Get test flow runs and update them to running state
        List<FS_Flow_Run__c> flowRuns = [SELECT Id, Interview_Id__c FROM FS_Flow_Run__c LIMIT 3];
        for (FS_Flow_Run__c run : flowRuns) {
            run.Status__c = 'Running';
            run.Start_Time__c = System.now().addMinutes(-3);
        }
        update flowRuns;
        
        // Create multiple requests
        List<FS_LogEndAction.LogEndRequest> requests = new List<FS_LogEndAction.LogEndRequest>();
        
        for (Integer i = 0; i < flowRuns.size(); i++) {
            FS_LogEndAction.LogEndRequest request = new FS_LogEndAction.LogEndRequest();
            request.interviewId = flowRuns[i].Interview_Id__c;
            request.status = i == 0 ? 'Failed' : 'Success';
            request.errorMessage = i == 0 ? 'Bulk test error' : null;
            request.totalCpuMillis = 1000 * (i + 1);
            request.totalSoqlCount = 5 * (i + 1);
            request.totalDmlCount = 2 * (i + 1);
            requests.add(request);
        }
        
        Test.startTest();
        
        List<FS_LogEndAction.LogEndResult> results = FS_LogEndAction.endLogging(requests);
        
        Test.stopTest();
        
        // Verify results
        System.assertEquals(flowRuns.size(), results.size(), 'Should return result for each request');
        
        for (Integer i = 0; i < results.size(); i++) {
            System.assertEquals(true, results[i].success, 'End logging ' + (i+1) + ' should be successful');
            System.assertEquals('Flow logging ended successfully', results[i].message, 'Message should be correct');
        }
        
        // Verify all Flow Run records were updated
        List<FS_Flow_Run__c> updatedFlowRuns = [SELECT Id, Status__c, Error_Details__c, CPU_Time__c
                                                FROM FS_Flow_Run__c 
                                                WHERE Id IN :flowRuns
                                                ORDER BY Id];
        
        for (Integer i = 0; i < updatedFlowRuns.size(); i++) {
            String expectedStatus = i == 0 ? 'Failed' : 'Success';
            System.assertEquals(expectedStatus, updatedFlowRuns[i].Status__c, 'Status should match for run ' + (i+1));
            System.assertEquals(1000 * (i + 1), updatedFlowRuns[i].CPU_Time__c, 'CPU time should match for run ' + (i+1));
            
            if (i == 0) {
                System.assertEquals('Bulk test error', updatedFlowRuns[i].Error_Details__c, 'Error details should match for failed run');
            }
        }
    }
    
    /**
     * @description Test flow logging end with invalid interview ID
     */
    @isTest
    static void testEndLoggingInvalidInterviewId() {
        // Create request with non-existent interview ID
        FS_LogEndAction.LogEndRequest request = new FS_LogEndAction.LogEndRequest();
        request.interviewId = 'INVALID_INTERVIEW_ID_123';
        request.status = 'Success';
        
        Test.startTest();
        
        List<FS_LogEndAction.LogEndResult> results = FS_LogEndAction.endLogging(
            new List<FS_LogEndAction.LogEndRequest>{request}
        );
        
        Test.stopTest();
        
        // Verify result - should still be successful but no records updated
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].success, 'End logging should be successful even with invalid interview ID');
        System.assertEquals('Flow logging ended successfully', results[0].message, 'Should return success message');
    }
    
    /**
     * @description Test flow logging end with failed status (terminated flow)
     */
    @isTest
    static void testEndLoggingTerminated() {
        // Get test flow run and set it to running state
        FS_Flow_Run__c flowRun = [SELECT Id, Interview_Id__c FROM FS_Flow_Run__c LIMIT 1];
        flowRun.Status__c = 'Running';
        flowRun.Start_Time__c = System.now().addMinutes(-10);
        update flowRun;
        
        // Create request with terminated status
        FS_LogEndAction.LogEndRequest request = new FS_LogEndAction.LogEndRequest();
        request.interviewId = flowRun.Interview_Id__c;
        request.status = 'Failed'; // Use valid picklist value instead of 'Terminated'
        request.errorMessage = 'Flow was manually terminated by user';
        
        Test.startTest();
        
        List<FS_LogEndAction.LogEndResult> results = FS_LogEndAction.endLogging(
            new List<FS_LogEndAction.LogEndRequest>{request}
        );
        
        Test.stopTest();
        
        // Verify result
        System.assertEquals(1, results.size(), 'Should return one result');
        if (!results[0].success) {
            System.debug('Error message: ' + results[0].message);
        }
        System.assertEquals(true, results[0].success, 'End logging should be successful. Error: ' + results[0].message);
        
        // Verify Flow Run record was updated with terminated status
        FS_Flow_Run__c updatedFlowRun = [SELECT Id, Status__c, Error_Details__c
                                         FROM FS_Flow_Run__c 
                                         WHERE Id = :flowRun.Id];
        
        System.assertEquals('Failed', updatedFlowRun.Status__c, 'Status should be Failed');
        System.assertEquals('Flow was manually terminated by user', updatedFlowRun.Error_Details__c, 'Error details should match');
    }
    
    /**
     * @description Test duration calculation when start time is available
     */
    @isTest
    static void testDurationCalculation() {
        // Get test flow run and set specific start time
        FS_Flow_Run__c flowRun = [SELECT Id, Interview_Id__c FROM FS_Flow_Run__c LIMIT 1];
        DateTime specificStartTime = DateTime.newInstance(2024, 1, 1, 12, 0, 0);
        flowRun.Status__c = 'Running';
        flowRun.Start_Time__c = specificStartTime;
        update flowRun;
        
        // Create request
        FS_LogEndAction.LogEndRequest request = new FS_LogEndAction.LogEndRequest();
        request.interviewId = flowRun.Interview_Id__c;
        request.status = 'Success';
        
        Test.startTest();
        
        List<FS_LogEndAction.LogEndResult> results = FS_LogEndAction.endLogging(
            new List<FS_LogEndAction.LogEndRequest>{request}
        );
        
        Test.stopTest();
        
        // Verify duration was calculated
        FS_Flow_Run__c updatedFlowRun = [SELECT Id, Start_Time__c, End_Time__c, Duration_Ms__c
                                         FROM FS_Flow_Run__c 
                                         WHERE Id = :flowRun.Id];
        
        System.assertNotEquals(null, updatedFlowRun.Duration_Ms__c, 'Duration should be calculated');
        System.assert(updatedFlowRun.Duration_Ms__c > 0, 'Duration should be positive');
        
        // Verify duration calculation is reasonable (allow for small timing differences)
        Long expectedDuration = updatedFlowRun.End_Time__c.getTime() - updatedFlowRun.Start_Time__c.getTime();
        Long actualDuration = updatedFlowRun.Duration_Ms__c.longValue();
        Long difference = Math.abs(expectedDuration - actualDuration);
        System.assert(difference < 1000, 'Duration calculation should be within 1 second tolerance. Expected: ' + expectedDuration + ', Actual: ' + actualDuration);
    }
    
    /**
     * @description Test with empty request list
     */
    @isTest
    static void testEndLoggingEmptyList() {
        Test.startTest();
        
        List<FS_LogEndAction.LogEndResult> results = FS_LogEndAction.endLogging(
            new List<FS_LogEndAction.LogEndRequest>()
        );
        
        Test.stopTest();
        
        // Verify empty result
        System.assertEquals(0, results.size(), 'Should return empty result list for empty input');
    }
    
    /**
     * @description Test wrapper classes for proper instantiation
     */
    @isTest
    static void testWrapperClasses() {
        // Test LogEndRequest wrapper
        FS_LogEndAction.LogEndRequest request = new FS_LogEndAction.LogEndRequest();
        request.interviewId = 'test_interview';
        request.status = 'Success';
        request.errorMessage = 'test error';
        request.totalCpuMillis = 1000;
        request.totalSoqlCount = 5;
        request.totalDmlCount = 2;
        
        System.assertEquals('test_interview', request.interviewId, 'Request wrapper should work correctly');
        System.assertEquals('Success', request.status, 'Request status should be set correctly');
        System.assertEquals('test error', request.errorMessage, 'Request error message should be set correctly');
        System.assertEquals(1000, request.totalCpuMillis, 'Request CPU millis should be set correctly');
        System.assertEquals(5, request.totalSoqlCount, 'Request SOQL count should be set correctly');
        System.assertEquals(2, request.totalDmlCount, 'Request DML count should be set correctly');
        
        // Test LogEndResult wrapper  
        FS_LogEndAction.LogEndResult result = new FS_LogEndAction.LogEndResult();
        result.success = true;
        result.message = 'test message';
        
        System.assertEquals(true, result.success, 'Result wrapper should work correctly');
        System.assertEquals('test message', result.message, 'Result message should be set correctly');
    }
}
