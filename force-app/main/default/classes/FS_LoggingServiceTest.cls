/**
 * @description Test class for FS_LoggingService
 * @author FlowSense
 * @version 1.0
 */
@IsTest
private class FS_LoggingServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // TEMPORARY: Commented out during CMDT migration
        // Create global settings with retention and logging preferences
        // FS_Global_Settings__c settings = new FS_Global_Settings__c(
        //     Name = 'Default',
        //     Data_Retention_Days__c = 90,
        //     Enable_Step_Logging__c = true,
        //     Enable_Debug_Logging__c = true,
        //     CPU_Excellent_Threshold__c = 1000,
        //     CPU_Good_Threshold__c = 3000,
        //     CPU_Fair_Threshold__c = 5000,
        //     CPU_Poor_Threshold__c = 8000
        // );
        // CMDT Migration: Commented out - FS_SettingsUtil provides defaults
        // insert settings;
    }
    
    @IsTest
    static void testLogFlowStartSuccess() {
        String flowApiName = 'Test_Flow_Start';
        String interviewId = 'test-interview-123';
        String runtimeUser = UserInfo.getUserId();
        String flowLabel = 'Test Flow Label';
        
        Test.startTest();
        FS_Flow_Run__c flowRun = FS_LoggingService.logFlowStart(flowApiName, interviewId, runtimeUser, flowLabel);
        Test.stopTest();
        
        // Verify flow run was created successfully
        System.assertNotEquals(null, flowRun, 'Flow run should be created');
        System.assertNotEquals(null, flowRun.Id, 'Flow run should have ID');
        System.assertEquals(flowApiName, flowRun.Flow_API_Name__c, 'API name should match');
        System.assertEquals(interviewId, flowRun.Interview_ID__c, 'Interview ID should match');
        System.assertEquals(runtimeUser, flowRun.Runtime_User__c, 'Runtime user should match');
        System.assertEquals(flowLabel, flowRun.Flow_Label__c, 'Flow label should match');
        System.assertEquals('Success', flowRun.Status__c, 'Status should be Success');
        System.assertNotEquals(null, flowRun.Started_At__c, 'Started at should be set');
        
        // Verify record exists in database
        List<FS_Flow_Run__c> createdRuns = [
            SELECT Id, Flow_API_Name__c, Interview_ID__c, Runtime_User__c, 
                   Flow_Label__c, Status__c, Started_At__c
            FROM FS_Flow_Run__c 
            WHERE Interview_ID__c = :interviewId
        ];
        
        System.assertEquals(1, createdRuns.size(), 'Should create one flow run record');
        System.assertEquals(flowApiName, createdRuns[0].Flow_API_Name__c, 'Database record should match');
    }
    
    @IsTest
    static void testLogFlowStartWithNullValues() {
        Test.startTest();
        FS_Flow_Run__c flowRun = FS_LoggingService.logFlowStart(null, null, null, null);
        Test.stopTest();
        
        // Should handle null values gracefully
        System.assertNotEquals(null, flowRun, 'Should create flow run even with nulls');
        System.assertEquals('Unknown_Flow', flowRun.Flow_API_Name__c, 'API name should have default value');
        System.assert(flowRun.Interview_ID__c.startsWith('test-interview-'), 'Interview ID should have default value');
        System.assertEquals(null, flowRun.Runtime_User__c, 'Runtime user should be null');
        System.assertEquals(null, flowRun.Flow_Label__c, 'Flow label should be null');
        System.assertEquals('Success', flowRun.Status__c, 'Status should be Success');
    }
    
    @IsTest
    static void testLogFlowStartExceptionHandling() {
        // Create a scenario that might cause an exception
        String longInterviewId = 'a'.repeat(300); // Exceeding field length
        
        Test.startTest();
        FS_Flow_Run__c flowRun = FS_LoggingService.logFlowStart('Test_Flow', longInterviewId, UserInfo.getUserId(), 'Test');
        Test.stopTest();
        
        // Should handle exceptions gracefully and return null
        System.assertEquals(null, flowRun, 'Should return null on exception');
    }
    
    @IsTest
    static void testLogFlowCompletionSuccess() {
        // Create initial flow run
        FS_Flow_Run__c initialRun = FS_LoggingService.logFlowStart('Test_Completion_Flow', 'test-completion-123', UserInfo.getUserId(), 'Test Flow');
        
        String status = 'Success';
        String errorMessage = null;
        Decimal cpuTime = 1500.5;
        Decimal soqlCount = 8.0;
        Decimal dmlCount = 5.0;
        Decimal heapSize = 2048000.0;
        
        Test.startTest();
        FS_LoggingService.logFlowCompletion(initialRun.Id, status, errorMessage, cpuTime, soqlCount, dmlCount, heapSize);
        Test.stopTest();
        
        // Verify completion was logged
        FS_Flow_Run__c updatedRun = [
            SELECT Id, Status__c, Completed_At__c, Error_Message__c, CPU_Time_Millis__c,
                   SOQL_Count__c, DML_Count__c, Heap_Size_Bytes__c, Duration_Ms__c, Started_At__c
            FROM FS_Flow_Run__c 
            WHERE Id = :initialRun.Id
        ];
        
        System.assertEquals(status, updatedRun.Status__c, 'Status should be updated');
        System.assertNotEquals(null, updatedRun.Completed_At__c, 'Completed at should be set');
        System.assertEquals(errorMessage, updatedRun.Error_Message__c, 'Error message should match');
        System.assertEquals(cpuTime, updatedRun.CPU_Time_Millis__c, 'CPU time should match');
        System.assertEquals(soqlCount, updatedRun.SOQL_Count__c, 'SOQL count should match');
        System.assertEquals(dmlCount, updatedRun.DML_Count__c, 'DML count should match');
        System.assertEquals(heapSize, updatedRun.Heap_Size_Bytes__c, 'Heap size should match');
        System.assertNotEquals(null, updatedRun.Duration_Ms__c, 'Duration should be calculated');
    }
    
    @IsTest
    static void testLogFlowCompletionWithError() {
        // Create initial flow run
        FS_Flow_Run__c initialRun = FS_LoggingService.logFlowStart('Test_Error_Flow', 'test-error-123', UserInfo.getUserId(), 'Test Error Flow');
        
        String status = 'Failed';
        String errorMessage = 'Test error occurred during flow execution';
        
        Test.startTest();
        FS_LoggingService.logFlowCompletion(initialRun.Id, status, errorMessage, null, null, null, null);
        Test.stopTest();
        
        // Verify error was logged
        FS_Flow_Run__c updatedRun = [
            SELECT Status__c, Error_Message__c, CPU_Time_Millis__c
            FROM FS_Flow_Run__c 
            WHERE Id = :initialRun.Id
        ];
        
        System.assertEquals(status, updatedRun.Status__c, 'Status should be Failed');
        System.assertEquals(errorMessage, updatedRun.Error_Message__c, 'Error message should be logged');
        System.assertEquals(null, updatedRun.CPU_Time_Millis__c, 'CPU time should remain null');
    }
    
    @IsTest
    static void testLogFlowCompletionWithNullId() {
        Test.startTest();
        FS_LoggingService.logFlowCompletion(null, 'Success', null, 1000, 5, 3, 1024000);
        Test.stopTest();
        
        // Should handle null ID gracefully (no exception)
        // No assertions needed as method should simply return without error
        System.assert(true, 'Method should complete without exception');
    }
    
    @IsTest
    static void testLogFlowStepSuccess() {
        // Create flow run
        FS_Flow_Run__c flowRun = FS_LoggingService.logFlowStart('Test_Step_Flow', 'test-step-123', UserInfo.getUserId(), 'Test Step Flow');
        
        // Create step data
        FS_LoggingService.FlowStepData stepData = new FS_LoggingService.FlowStepData();
        stepData.sequenceNumber = 1;
        stepData.elementDeveloperName = 'Test_Decision_Element';
        stepData.elementLabel = 'Test Decision';
        stepData.elementType = 'Decision';
        stepData.enteredAt = System.now().addSeconds(-5);
        stepData.exitedAt = System.now();
        stepData.durationMillis = 5000;
        stepData.cpuMillis = 100;
        stepData.soqlCount = 2;
        stepData.dmlCount = 0;
        stepData.outcome = 'True';
        stepData.inputVariables = '{"var1":"value1"}';
        stepData.outputVariables = '{"result":"success"}';
        
        Test.startTest();
        FS_LoggingService.logFlowStep(flowRun.Id, stepData);
        Test.stopTest();
        
        // Verify step was logged
        List<FS_Flow_Step__c> steps = [
            SELECT Id, Flow_Run__c, Sequence__c, Element_DeveloperName__c,
                   Element_Label__c, Element_Type__c, Entered_At__c, Exited_At__c,
                   Outcome__c, Input_Variables__c, Output_Variables__c
            FROM FS_Flow_Step__c 
            WHERE Flow_Run__c = :flowRun.Id
        ];
        
        System.assertEquals(1, steps.size(), 'Should create one step record');
        FS_Flow_Step__c step = steps[0];
        System.assertEquals(flowRun.Id, step.Flow_Run__c, 'Flow run should match');
        System.assertEquals(1, step.Sequence__c, 'Sequence number should match');
        System.assertEquals('Test_Decision_Element', step.Element_DeveloperName__c, 'Element name should match');
        System.assertEquals('Decision', step.Element_Type__c, 'Element type should match');
    }
    
    @IsTest
    static void testLogFlowStepWithNullData() {
        // Create flow run
        FS_Flow_Run__c flowRun = FS_LoggingService.logFlowStart('Test_Null_Step_Flow', 'test-null-step-123', UserInfo.getUserId(), 'Test Null Step Flow');
        
        Test.startTest();
        FS_LoggingService.logFlowStep(flowRun.Id, null);
        Test.stopTest();
        
        // Should handle null step data gracefully
        List<FS_Flow_Step__c> steps = [SELECT Id FROM FS_Flow_Step__c WHERE Flow_Run__c = :flowRun.Id];
        System.assertEquals(0, steps.size(), 'Should not create step with null data');
    }
    
    @IsTest
    static void testLogFlowStepWithNullFlowRunId() {
        FS_LoggingService.FlowStepData stepData = new FS_LoggingService.FlowStepData('Test_Element', 'Assignment');
        
        Test.startTest();
        FS_LoggingService.logFlowStep(null, stepData);
        Test.stopTest();
        
        // Should handle null flow run ID gracefully
        List<FS_Flow_Step__c> steps = [SELECT Id FROM FS_Flow_Step__c];
        System.assertEquals(0, steps.size(), 'Should not create step with null flow run ID');
    }
    
    @IsTest
    static void testLogFlowStepsSuccess() {
        // Create flow run
        FS_Flow_Run__c flowRun = FS_LoggingService.logFlowStart('Test_Bulk_Steps_Flow', 'test-bulk-steps-123', UserInfo.getUserId(), 'Test Bulk Steps Flow');
        
        // Create multiple step data
        List<FS_LoggingService.FlowStepData> stepDataList = new List<FS_LoggingService.FlowStepData>();
        
        for (Integer i = 1; i <= 5; i++) {
            FS_LoggingService.FlowStepData stepData = new FS_LoggingService.FlowStepData();
            stepData.sequenceNumber = i;
            stepData.elementDeveloperName = 'Test_Element_' + i;
            stepData.elementLabel = 'Test Element ' + i;
            stepData.elementType = i == 1 ? 'Start' : (i == 5 ? 'Action' : 'Assignment');
            stepData.enteredAt = System.now().addSeconds(-10 + i);
            stepData.exitedAt = System.now().addSeconds(-5 + i);
            stepData.durationMillis = 1000 + (i * 100);
            stepData.cpuMillis = 50 + (i * 10);
            stepData.soqlCount = i <= 3 ? i : 0;
            stepData.dmlCount = i == 2 || i == 4 ? 1 : 0;
            stepData.outcome = 'Success';
            stepDataList.add(stepData);
        }
        
        Test.startTest();
        FS_LoggingService.logFlowSteps(flowRun.Id, stepDataList);
        Test.stopTest();
        
        // Verify all steps were logged
        List<FS_Flow_Step__c> steps = [
            SELECT Id, Sequence__c, Element_DeveloperName__c, Element_Type__c
            FROM FS_Flow_Step__c 
            WHERE Flow_Run__c = :flowRun.Id
            ORDER BY Sequence__c
        ];
        
        System.assertEquals(5, steps.size(), 'Should create 5 step records');
        
        for (Integer i = 0; i < steps.size(); i++) {
            FS_Flow_Step__c step = steps[i];
            System.assertEquals(i + 1, step.Sequence__c, 'Sequence number should match');
            System.assertEquals('Test_Element_' + (i + 1), step.Element_DeveloperName__c, 'Element name should match');
        }
    }
    
    @IsTest
    static void testLogFlowStepsWithEmptyList() {
        FS_Flow_Run__c flowRun = FS_LoggingService.logFlowStart('Test_Empty_Steps_Flow', 'test-empty-steps-123', UserInfo.getUserId(), 'Test Empty Steps Flow');
        
        Test.startTest();
        FS_LoggingService.logFlowSteps(flowRun.Id, new List<FS_LoggingService.FlowStepData>());
        Test.stopTest();
        
        // Should handle empty list gracefully
        List<FS_Flow_Step__c> steps = [SELECT Id FROM FS_Flow_Step__c WHERE Flow_Run__c = :flowRun.Id];
        System.assertEquals(0, steps.size(), 'Should not create steps with empty list');
    }
    
    @IsTest
    static void testCreateFlowAnalysisSuccess() {
        String flowApiName = 'Test_Analysis_Flow';
        String analysisType = 'Performance';
        String analysisData = '{"totalSteps": 10, "complexity": "Medium"}';
        String recommendations = 'Consider optimizing loop logic';
        Decimal riskScore = 75.5;
        Decimal performanceScore = 82.3;
        
        Test.startTest();
        FS_Flow_Analysis__c analysis = FS_LoggingService.createFlowAnalysis(flowApiName, analysisType, analysisData, recommendations, riskScore, performanceScore);
        Test.stopTest();
        
        // Verify analysis was created
        System.assertNotEquals(null, analysis, 'Analysis should be created');
        System.assertNotEquals(null, analysis.Id, 'Analysis should have ID');
        System.assertEquals(flowApiName, analysis.Flow_API_Name__c, 'Flow API name should match');
        System.assertEquals(analysisType, analysis.Analysis_Type__c, 'Analysis type should match');
        System.assertEquals(performanceScore, analysis.Performance_Score__c, 'Performance score should match');
        System.assertEquals('Completed', analysis.Status__c, 'Status should be Completed');
        System.assertNotEquals(null, analysis.Analysis_Date__c, 'Analysis date should be set');
        
        // Verify record exists in database
        List<FS_Flow_Analysis__c> analyses = [
            SELECT Id, Flow_API_Name__c, Analysis_Type__c, Risk_Score__c, Performance_Score__c
            FROM FS_Flow_Analysis__c 
            WHERE Flow_API_Name__c = :flowApiName
        ];
        
        System.assertEquals(1, analyses.size(), 'Should create one analysis record');
        System.assertEquals(riskScore, analyses[0].Risk_Score__c, 'Database record should match');
    }
    
    @IsTest
    static void testCreateFlowAnalysisWithNullValues() {
        Test.startTest();
        FS_Flow_Analysis__c analysis = FS_LoggingService.createFlowAnalysis(null, null, null, null, null, null);
        Test.stopTest();
        
        // Should handle null values gracefully
        System.assertNotEquals(null, analysis, 'Should create analysis even with nulls');
        System.assertEquals('Unknown_Flow', analysis.Flow_API_Name__c, 'API name should have default value');
        System.assertEquals('Performance', analysis.Analysis_Type__c, 'Analysis type should have default value');
        System.assertEquals('Completed', analysis.Status__c, 'Status should still be Completed');
    }
    
    @IsTest
    static void testGetFlowExecutionStatsWithData() {
        String flowApiName = 'Test_Stats_Flow';
        
        // Create test flow runs
        List<FS_Flow_Run__c> flowRuns = new List<FS_Flow_Run__c>();
        for (Integer i = 0; i < 10; i++) {
            FS_Flow_Run__c run = new FS_Flow_Run__c(
                Flow_API_Name__c = flowApiName,
                Interview_ID__c = 'test-stats-' + i,
                Runtime_User__c = i < 5 ? UserInfo.getUserId() : [SELECT Id FROM User WHERE Id != :UserInfo.getUserId() LIMIT 1].Id,
                Status__c = i < 8 ? 'Success' : 'Failed',
                Started_At__c = System.now().addDays(-i),
                Completed_At__c = System.now().addDays(-i).addMinutes(5),
                Duration_Ms__c = 5000 + (i * 1000),
                CPU_Time_Millis__c = 1000 + (i * 200),
                SOQL_Count__c = 5 + i,
                DML_Count__c = 3 + i
            );
            flowRuns.add(run);
        }
        insert flowRuns;
        
        Test.startTest();
        FS_LoggingService.FlowExecutionStats stats = FS_LoggingService.getFlowExecutionStats(flowApiName, 30);
        Test.stopTest();
        
        // Verify statistics
        System.assertEquals(10, stats.totalRuns, 'Should have 10 total runs');
        System.assertEquals(8, stats.successfulRuns, 'Should have 8 successful runs');
        System.assertEquals(2, stats.failedRuns, 'Should have 2 failed runs');
        System.assertEquals(80.0, stats.successRate, 'Should have 80% success rate');
        System.assertNotEquals(null, stats.avgDuration, 'Should have average duration');
        System.assertNotEquals(null, stats.maxDuration, 'Should have max duration');
        System.assertNotEquals(null, stats.avgCpuTime, 'Should have average CPU time');
        System.assertNotEquals(null, stats.avgSoqlCount, 'Should have average SOQL count');
        System.assertNotEquals(null, stats.avgDmlCount, 'Should have average DML count');
    }
    
    @IsTest
    static void testGetFlowExecutionStatsNoData() {
        Test.startTest();
        FS_LoggingService.FlowExecutionStats stats = FS_LoggingService.getFlowExecutionStats('Non_Existent_Flow', 30);
        Test.stopTest();
        
        // Verify default statistics for non-existent flow
        System.assertEquals(0, stats.totalRuns, 'Should have 0 total runs');
        System.assertEquals(0, stats.successfulRuns, 'Should have 0 successful runs');
        System.assertEquals(0, stats.failedRuns, 'Should have 0 failed runs');
        System.assertEquals(0, stats.successRate, 'Should have 0% success rate');
        System.assertEquals(null, stats.avgDuration, 'Should have null average duration');
        System.assertEquals(null, stats.maxDuration, 'Should have null max duration');
    }
    
    @IsTest
    static void testGetFlowExecutionStatsDateFiltering() {
        String flowApiName = 'Test_Date_Filter_Flow';
        
        // Create old flow run (should be excluded)
        FS_Flow_Run__c oldRun = new FS_Flow_Run__c(
            Flow_API_Name__c = flowApiName,
            Interview_ID__c = 'test-old',
            Status__c = 'Success',
            Started_At__c = System.now().addDays(-45),
            Duration_Ms__c = 3000
        );
        insert oldRun;
        
        // Create recent flow run (should be included)
        FS_Flow_Run__c recentRun = new FS_Flow_Run__c(
            Flow_API_Name__c = flowApiName,
            Interview_ID__c = 'test-recent',
            Status__c = 'Success',
            Started_At__c = System.now().addDays(-5),
            Duration_Ms__c = 5000
        );
        insert recentRun;
        
        Test.startTest();
        FS_LoggingService.FlowExecutionStats stats = FS_LoggingService.getFlowExecutionStats(flowApiName, 30);
        Test.stopTest();
        
        // Should only include recent run
        System.assertEquals(1, stats.totalRuns, 'Should only include recent run');
        System.assertEquals(1, stats.successfulRuns, 'Should have 1 successful run');
        System.assertEquals(5000, stats.avgDuration, 'Should have duration from recent run');
    }
    
    @IsTest
    static void testCleanupOldRecordsWithSettings() {
        // TEMPORARY: Commented out during CMDT migration
        // Create global settings with retention period
        // FS_Global_Settings__c settings = new FS_Global_Settings__c();
        // settings.Name = 'Test Settings';
        // settings.Data_Retention_Days__c = 60; // 60 day retention
        // insert settings;
        
        // Create old records to be cleaned up
        FS_Flow_Run__c oldRun = new FS_Flow_Run__c(
            Flow_API_Name__c = 'Old_Flow',
            Interview_ID__c = 'old-run',
            Status__c = 'Success',
            Started_At__c = System.now().addDays(-100) // Older than 60 days
        );
        insert oldRun;
        
        FS_Flow_Step__c oldStep = new FS_Flow_Step__c(
            Flow_Run__c = oldRun.Id,
            Element_DeveloperName__c = 'Old_Element',
            Element_Type__c = 'Assignment',
            Sequence__c = 1
        );
        insert oldStep;
        
        FS_Flow_Analysis__c oldAnalysis = new FS_Flow_Analysis__c(
            Flow_API_Name__c = 'Old_Flow',
            Flow_Run__c = oldRun.Id,
            Analysis_Type__c = 'Performance',
            Analysis_Date__c = System.now().addDays(-100),
            Status__c = 'Completed'
        );
        insert oldAnalysis;
        
        // Create recent records to be kept
        FS_Flow_Run__c recentRun = new FS_Flow_Run__c(
            Flow_API_Name__c = 'Recent_Flow',
            Interview_ID__c = 'recent-run',
            Status__c = 'Success',
            Started_At__c = System.now().addDays(-30) // Within 90 days
        );
        insert recentRun;
        
        Test.startTest();
        FS_LoggingService.cleanupOldRecords();
        Test.stopTest();
        
        // Verify old records were deleted
        System.assertEquals(0, [SELECT COUNT() FROM FS_Flow_Step__c WHERE Id = :oldStep.Id], 'Old step should be deleted');
        System.assertEquals(0, [SELECT COUNT() FROM FS_Flow_Run__c WHERE Id = :oldRun.Id], 'Old run should be deleted');
        System.assertEquals(0, [SELECT COUNT() FROM FS_Flow_Analysis__c WHERE Id = :oldAnalysis.Id], 'Old analysis should be deleted');
        
        // Verify recent records were kept
        System.assertEquals(1, [SELECT COUNT() FROM FS_Flow_Run__c WHERE Id = :recentRun.Id], 'Recent run should be kept');
    }
    
    @IsTest
    static void testCleanupOldRecordsWithoutSettings() {
        // TEMPORARY: Commented out during CMDT migration
        // Delete settings to test default behavior
        // delete [SELECT Id FROM FS_Global_Settings__c];
        
        // Create old record (older than default 90 days)
        FS_Flow_Run__c oldRun = new FS_Flow_Run__c(
            Flow_API_Name__c = 'Old_Flow_No_Settings',
            Interview_ID__c = 'old-run-no-settings',
            Status__c = 'Success',
            Started_At__c = System.now().addDays(-100)
        );
        insert oldRun;
        
        Test.startTest();
        FS_LoggingService.cleanupOldRecords();
        Test.stopTest();
        
        // Should use default 90 days and delete old record
        System.assertEquals(0, [SELECT COUNT() FROM FS_Flow_Run__c WHERE Id = :oldRun.Id], 'Old run should be deleted with default retention');
    }
    
    @IsTest
    static void testIsStepLoggingEnabled() {
        Test.startTest();
        Boolean isEnabled = FS_LoggingService.isStepLoggingEnabled();
        Test.stopTest();
        
        // Should return true based on test setup
        System.assertEquals(true, isEnabled, 'Step logging should be enabled');
    }
    
    @IsTest
    static void testIsStepLoggingEnabledWithoutSettings() {
        // TEMPORARY: Commented out during CMDT migration
        // Delete settings
        // delete [SELECT Id FROM FS_Global_Settings__c];
        
        Test.startTest();
        Boolean isEnabled = FS_LoggingService.isStepLoggingEnabled();
        Test.stopTest();
        
        // Should return false when no settings exist
        System.assertEquals(false, isEnabled, 'Step logging should be disabled without settings');
    }
    
    @IsTest
    static void testIsDebugLoggingEnabled() {
        Test.startTest();
        Boolean isEnabled = FS_LoggingService.isDebugLoggingEnabled();
        Test.stopTest();
        
        // Should return true based on test setup
        System.assertEquals(true, isEnabled, 'Debug logging should be enabled');
    }
    
    @IsTest
    static void testIsDebugLoggingEnabledWithoutSettings() {
        // TEMPORARY: Commented out during CMDT migration
        // Delete settings
        // delete [SELECT Id FROM FS_Global_Settings__c];
        
        Test.startTest();
        Boolean isEnabled = FS_LoggingService.isDebugLoggingEnabled();
        Test.stopTest();
        
        // Should return false when no settings exist
        System.assertEquals(false, isEnabled, 'Debug logging should be disabled without settings');
    }
    
    @IsTest
    static void testFlowStepDataConstructors() {
        // Test default constructor
        FS_LoggingService.FlowStepData stepData1 = new FS_LoggingService.FlowStepData();
        System.assertEquals(null, stepData1.elementDeveloperName, 'Developer name should be null');
        System.assertEquals(null, stepData1.elementType, 'Element type should be null');
        System.assertEquals(null, stepData1.enteredAt, 'Entered at should be null');
        
        // Test parameterized constructor
        FS_LoggingService.FlowStepData stepData2 = new FS_LoggingService.FlowStepData('Test_Element', 'Decision');
        System.assertEquals('Test_Element', stepData2.elementDeveloperName, 'Developer name should be set');
        System.assertEquals('Decision', stepData2.elementType, 'Element type should be set');
        System.assertNotEquals(null, stepData2.enteredAt, 'Entered at should be set automatically');
    }
    
    @IsTest
    static void testFlowExecutionStatsStructure() {
        FS_LoggingService.FlowExecutionStats stats = new FS_LoggingService.FlowExecutionStats();
        
        // Test default values
        System.assertEquals(0, stats.totalRuns, 'Should default to 0');
        System.assertEquals(0, stats.uniqueUsers, 'Should default to 0');
        System.assertEquals(0, stats.successfulRuns, 'Should default to 0');
        System.assertEquals(0, stats.failedRuns, 'Should default to 0');
        System.assertEquals(0, stats.successRate, 'Should default to 0');
        System.assertEquals(0, stats.avgDuration, 'Should default to 0');
        System.assertEquals(0, stats.maxDuration, 'Should default to 0');
        System.assertEquals(0, stats.avgCpuTime, 'Should default to 0');
        System.assertEquals(0, stats.avgSoqlCount, 'Should default to 0');
        System.assertEquals(0, stats.avgDmlCount, 'Should default to 0');
        
        // Test property assignment
        stats.totalRuns = 100;
        stats.uniqueUsers = 25;
        stats.successfulRuns = 95;
        stats.failedRuns = 5;
        stats.successRate = 95.0;
        stats.avgDuration = 3500.5;
        stats.maxDuration = 8000.0;
        stats.avgCpuTime = 1200.3;
        stats.avgSoqlCount = 7.5;
        stats.avgDmlCount = 4.2;
        
        System.assertEquals(100, stats.totalRuns, 'Total runs should be set');
        System.assertEquals(25, stats.uniqueUsers, 'Unique users should be set');
        System.assertEquals(95, stats.successfulRuns, 'Successful runs should be set');
        System.assertEquals(5, stats.failedRuns, 'Failed runs should be set');
        System.assertEquals(95.0, stats.successRate, 'Success rate should be set');
        System.assertEquals(3500.5, stats.avgDuration, 'Average duration should be set');
        System.assertEquals(8000.0, stats.maxDuration, 'Max duration should be set');
        System.assertEquals(1200.3, stats.avgCpuTime, 'Average CPU time should be set');
        System.assertEquals(7.5, stats.avgSoqlCount, 'Average SOQL count should be set');
        System.assertEquals(4.2, stats.avgDmlCount, 'Average DML count should be set');
    }
}
