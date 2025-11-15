/**
 * @description Test class for FS_MonitorFlowAction
 * @author FlowSense
 * @version 1.0
 */
@IsTest
private class FS_MonitorFlowActionTest {
    
    @IsTest
    static void testMonitorFlowSuccess() {
        DateTime testStartTime = System.now().addMinutes(-5);
        DateTime testEndTime = System.now();
        
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Test_Monitor_Flow';
        request.flowLabel = 'Test Monitor Flow Label';
        request.startTime = testStartTime;
        request.endTime = testEndTime;
        request.status = 'Success';
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertNotEquals(null, results[0].durationSeconds, 'Should calculate duration');
        System.assertNotEquals(null, results[0].performanceScore, 'Should calculate performance score');
        System.assertEquals('Success', results[0].status, 'Should return correct status');
        System.assert(results[0].message.contains('Monitoring completed'), 'Should contain success message');
        System.assert(results[0].message.contains('Test_Monitor_Flow'), 'Should contain flow name');
    }
    
    @IsTest
    static void testMonitorFlowBulkRequests() {
        List<FS_MonitorFlowAction.Request> requests = new List<FS_MonitorFlowAction.Request>();
        
        for (Integer i = 0; i < 5; i++) {
            FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
            request.flowApiName = 'Bulk_Monitor_Flow_' + i;
            request.flowLabel = 'Bulk Flow ' + i;
            request.startTime = System.now().addMinutes(-i - 1);
            request.endTime = System.now();
            request.status = Math.mod(i, 2) == 0 ? 'Success' : 'Running';
            requests.add(request);
        }
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(requests);
        Test.stopTest();
        
        // Verify bulk processing
        System.assertEquals(5, results.size(), 'Should return five results');
        for (FS_MonitorFlowAction.Result result : results) {
            System.assertEquals(true, result.isSuccess, 'All should be successful');
            System.assertNotEquals(null, result.durationSeconds, 'All should have duration');
            System.assertNotEquals(null, result.performanceScore, 'All should have performance score');
            System.assertNotEquals(null, result.message, 'All should have message');
        }
    }
    
    @IsTest
    static void testMonitorFlowMinimalData() {
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Minimal_Monitor_Flow';
        // Leave other fields null to test defaults
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should handle minimal data gracefully
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertEquals('Running', results[0].status, 'Should default to Running status');
        System.assertEquals(null, results[0].durationSeconds, 'Should not calculate duration without end time');
        System.assertEquals(null, results[0].performanceScore, 'Should not calculate performance score without duration');
    }
    
    @IsTest
    static void testMonitorFlowWithStartTimeOnly() {
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Start_Only_Flow';
        request.flowLabel = 'Start Time Only Flow';
        request.startTime = System.now().addMinutes(-2);
        request.status = 'Running';
        // No end time provided
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should handle start time only scenario
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertEquals('Running', results[0].status, 'Should have Running status');
        System.assertEquals(null, results[0].durationSeconds, 'Should not calculate duration without end time');
        System.assertEquals(null, results[0].performanceScore, 'Should not calculate performance score');
    }
    
    @IsTest
    static void testMonitorFlowWithEndTimeOnly() {
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'End_Only_Flow';
        request.flowLabel = 'End Time Only Flow';
        request.endTime = System.now();
        request.status = 'Success';
        // No start time provided, should default to current time
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should use default start time and calculate duration
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertEquals('Success', results[0].status, 'Should have Completed status');
        System.assertNotEquals(null, results[0].durationSeconds, 'Should calculate duration using default start time');
        System.assertNotEquals(null, results[0].performanceScore, 'Should calculate performance score');
    }
    
    @IsTest
    static void testPerformanceScoreCalculationExcellent() {
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Excellent_Performance_Flow';
        request.startTime = System.now().addSeconds(-1); // 1 second duration
        request.endTime = System.now();
        request.status = 'Success';
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should get excellent performance score
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(100.0, results[0].performanceScore, 'Should get perfect performance score');
        System.assert(results[0].durationSeconds <= 1.0, 'Duration should be 1 second or less');
    }
    
    @IsTest
    static void testPerformanceScoreCalculationGood() {
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Good_Performance_Flow';
        request.startTime = System.now().addSeconds(-2); // 2 seconds duration
        request.endTime = System.now();
        request.status = 'Success';
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should get good performance score
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(90.0, results[0].performanceScore, 'Should get good performance score');
        System.assert(results[0].durationSeconds > 1.0 && results[0].durationSeconds <= 3.0, 'Duration should be 2-3 seconds');
    }
    
    @IsTest
    static void testPerformanceScoreCalculationFair() {
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Fair_Performance_Flow';
        request.startTime = System.now().addSeconds(-4); // 4 seconds duration
        request.endTime = System.now();
        request.status = 'Success';
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should get fair performance score
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(80.0, results[0].performanceScore, 'Should get fair performance score');
        System.assert(results[0].durationSeconds > 3.0 && results[0].durationSeconds <= 5.0, 'Duration should be 3-5 seconds');
    }
    
    @IsTest
    static void testPerformanceScoreCalculationPoor() {
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Poor_Performance_Flow';
        request.startTime = System.now().addSeconds(-8); // 8 seconds duration
        request.endTime = System.now();
        request.status = 'Success';
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should get poor performance score
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(70.0, results[0].performanceScore, 'Should get poor performance score');
        System.assert(results[0].durationSeconds > 5.0 && results[0].durationSeconds <= 10.0, 'Duration should be 5-10 seconds');
    }
    
    @IsTest
    static void testPerformanceScoreCalculationVeryPoor() {
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Very_Poor_Performance_Flow';
        request.startTime = System.now().addSeconds(-35); // 35 seconds duration
        request.endTime = System.now();
        request.status = 'Success';
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should get very poor performance score
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(25.0, results[0].performanceScore, 'Should get very poor performance score');
        System.assert(results[0].durationSeconds > 30.0, 'Duration should be more than 30 seconds');
    }
    
    @IsTest
    static void testDurationCalculationAccuracy() {
        DateTime startTime = DateTime.newInstance(2025, 11, 9, 10, 0, 0);
        DateTime endTime = DateTime.newInstance(2025, 11, 9, 10, 0, 5); // Exactly 5 seconds later
        
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Duration_Test_Flow';
        request.startTime = startTime;
        request.endTime = endTime;
        request.status = 'Success';
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should calculate exactly 5 seconds
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(5.0, results[0].durationSeconds, 'Should calculate exactly 5 seconds');
        System.assertEquals(80.0, results[0].performanceScore, 'Should get correct performance score for 5 seconds');
    }
    
    @IsTest
    static void testDifferentStatusValues() {
        List<String> statuses = new List<String>{'Running', 'Success', 'Failed', 'Paused', 'Cancelled'};
        List<FS_MonitorFlowAction.Request> requests = new List<FS_MonitorFlowAction.Request>();
        
        for (String status : statuses) {
            FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
            request.flowApiName = 'Status_Test_Flow_' + status;
            request.flowLabel = 'Status Test: ' + status;
            request.startTime = System.now().addSeconds(-3);
            request.endTime = System.now();
            request.status = status;
            requests.add(request);
        }
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(requests);
        Test.stopTest();
        
        // Verify all statuses are handled correctly
        System.assertEquals(statuses.size(), results.size(), 'Should return results for all statuses');
        for (Integer i = 0; i < results.size(); i++) {
            System.assertEquals(true, results[i].isSuccess, 'All should be successful');
            System.assertEquals(statuses[i], results[i].status, 'Should return correct status');
            System.assertNotEquals(null, results[i].durationSeconds, 'All should have duration');
            System.assertNotEquals(null, results[i].performanceScore, 'All should have performance score');
        }
    }
    
    @IsTest
    static void testMonitorFlowException() {
        // Create a request that might cause an exception
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = null; // This might cause issues during processing
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should handle exception gracefully
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].isSuccess, 'Should not be successful');
        System.assertNotEquals(null, results[0].errorMessage, 'Should have error message');
        System.assertEquals(null, results[0].performanceScore, 'Should not have performance score');
        System.assertEquals(null, results[0].durationSeconds, 'Should not have duration');
    }
    
    @IsTest
    static void testMonitorFlowPartialFailure() {
        List<FS_MonitorFlowAction.Request> requests = new List<FS_MonitorFlowAction.Request>();
        
        // Valid request
        FS_MonitorFlowAction.Request validRequest = new FS_MonitorFlowAction.Request();
        validRequest.flowApiName = 'Valid_Monitor_Flow';
        validRequest.startTime = System.now().addSeconds(-3);
        validRequest.endTime = System.now();
        validRequest.status = 'Success';
        requests.add(validRequest);
        
        // Invalid request
        FS_MonitorFlowAction.Request invalidRequest = new FS_MonitorFlowAction.Request();
        invalidRequest.flowApiName = null;
        requests.add(invalidRequest);
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(requests);
        Test.stopTest();
        
        // Should have mixed results
        System.assertEquals(2, results.size(), 'Should return two results');
        
        // Check that we have one success and one failure
        Boolean hasSuccess = false;
        Boolean hasFailure = false;
        
        for (FS_MonitorFlowAction.Result result : results) {
            if (result.isSuccess) {
                hasSuccess = true;
                System.assertNotEquals(null, result.performanceScore, 'Successful result should have performance score');
                System.assertNotEquals(null, result.durationSeconds, 'Successful result should have duration');
            } else {
                hasFailure = true;
                System.assertNotEquals(null, result.errorMessage, 'Failed result should have error message');
            }
        }
        
        System.assert(hasSuccess, 'Should have at least one successful result');
        System.assert(hasFailure, 'Should have at least one failed result');
    }
    
    @IsTest
    static void testNegativeDurationHandling() {
        // Test edge case where end time is before start time
        DateTime startTime = System.now();
        DateTime endTime = System.now().addMinutes(-1); // End time before start time
        
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Negative_Duration_Flow';
        request.startTime = startTime;
        request.endTime = endTime;
        request.status = 'Success';
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should handle negative duration gracefully
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assert(results[0].durationSeconds < 0, 'Duration should be negative');
        // Performance score calculation should still work with negative duration
        System.assertNotEquals(null, results[0].performanceScore, 'Should still calculate performance score');
    }
    
    @IsTest
    static void testZeroDurationHandling() {
        // Test edge case where start and end times are the same
        DateTime sameTime = System.now();
        
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Zero_Duration_Flow';
        request.startTime = sameTime;
        request.endTime = sameTime;
        request.status = 'Success';
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should handle zero duration gracefully
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertEquals(0.0, results[0].durationSeconds, 'Duration should be zero');
        System.assertEquals(100.0, results[0].performanceScore, 'Should get perfect score for zero duration');
    }
    
    @IsTest
    static void testDebugLogging() {
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Debug_Test_Flow';
        request.flowLabel = 'Debug Test Flow Label';
        request.startTime = System.now().addSeconds(-3);
        request.endTime = System.now();
        request.status = 'Success';
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // The method logs debug information, but we can't directly assert on System.debug
        // We can verify the method completed successfully which indicates debug logging worked
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assert(results[0].message.contains('Debug_Test_Flow'), 'Should contain flow name in message');
    }
    
    @IsTest
    static void testCompleteMonitoringScenario() {
        FS_MonitorFlowAction.Request request = new FS_MonitorFlowAction.Request();
        request.flowApiName = 'Complete_Monitor_Test';
        request.flowLabel = 'Complete Monitoring Test Flow';
        request.startTime = System.now().addSeconds(-7); // 7 seconds duration for 70 score
        request.endTime = System.now();
        request.status = 'Success';
        
        Test.startTest();
        List<FS_MonitorFlowAction.Result> results = FS_MonitorFlowAction.monitorFlow(
            new List<FS_MonitorFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify complete monitoring scenario
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertEquals('Success', results[0].status, 'Should have correct status');
        System.assert(results[0].durationSeconds >= 6.0 && results[0].durationSeconds <= 8.0, 'Duration should be approximately 7 seconds');
        System.assertEquals(70.0, results[0].performanceScore, 'Should get correct performance score for 7 seconds');
        System.assert(results[0].message.contains('Monitoring completed'), 'Should contain completion message');
        System.assert(results[0].message.contains('Complete_Monitor_Test'), 'Should contain flow name');
    }
}
