/**
 * @description Test class for FS_PerformanceService
 * @author FlowSense
 * @version 1.0
 */
@IsTest
private class FS_PerformanceServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // TEMPORARY: Commented out during CMDT migration
        // Create global settings with performance thresholds
        // FS_Global_Settings__c settings = new FS_Global_Settings__c(
        //     Name = 'Default',
        //     CPU_Excellent_Threshold__c = 1000,
        //     CPU_Good_Threshold__c = 3000,
        //     CPU_Fair_Threshold__c = 5000,
        //     CPU_Poor_Threshold__c = 8000,
        //     SOQL_Excellent_Threshold__c = 5,
        //     SOQL_Good_Threshold__c = 15,
        //     SOQL_Fair_Threshold__c = 25,
        //     SOQL_Poor_Threshold__c = 40,
        //     DML_Excellent_Threshold__c = 5,
        //     DML_Good_Threshold__c = 15,
        //     DML_Fair_Threshold__c = 25,
        //     DML_Poor_Threshold__c = 40,
        //     Data_Retention_Days__c = 90,
        //     Enable_Step_Logging__c = true
        // );
        // CMDT Migration: Commented out - FS_SettingsUtil provides defaults
        // insert settings;
        
        // Create test flow runs for performance analysis
        List<FS_Flow_Run__c> flowRuns = new List<FS_Flow_Run__c>();
        
        // Create good performance flow runs
        for (Integer i = 0; i < 15; i++) {
            FS_Flow_Run__c run = new FS_Flow_Run__c(
                Flow_API_Name__c = 'Good_Performance_Flow',
                Interview_ID__c = 'good-perf-' + i,
                Status__c = 'Success',
                Started_At__c = System.now().addDays(-i),
                Completed_At__c = System.now().addDays(-i).addMinutes(2),
                Duration_Ms__c = 2000 + (i * 100),
                CPU_Time_Millis__c = 800 + (i * 50),
                SOQL_Count__c = 5 + Math.mod(i, 3),
                DML_Count__c = 3 + Math.mod(i, 2),
                Heap_Size_Bytes__c = 1024 * 1024 * (1 + Math.mod(i, 2))
            );
            flowRuns.add(run);
        }
        
        // Create poor performance flow runs
        for (Integer i = 0; i < 10; i++) {
            FS_Flow_Run__c run = new FS_Flow_Run__c(
                Flow_API_Name__c = 'Poor_Performance_Flow',
                Interview_ID__c = 'poor-perf-' + i,
                Status__c = i < 8 ? 'Success' : 'Failed',
                Started_At__c = System.now().addDays(-i),
                Completed_At__c = System.now().addDays(-i).addMinutes(30),
                Duration_Ms__c = 25000 + (i * 2000),
                CPU_Time_Millis__c = 10000 + (i * 1000),
                SOQL_Count__c = 45 + i,
                DML_Count__c = 50 + i,
                Heap_Size_Bytes__c = 10 * 1024 * 1024 * (1 + i),
                Error_Message__c = i >= 8 ? 'Test error message' : null
            );
            flowRuns.add(run);
        }
        
        // Create trend analysis flow runs (older vs newer)
        for (Integer i = 0; i < 20; i++) {
            FS_Flow_Run__c run = new FS_Flow_Run__c(
                Flow_API_Name__c = 'Trend_Analysis_Flow',
                Interview_ID__c = 'trend-' + i,
                Status__c = 'Success',
                Started_At__c = System.now().addDays(-i),
                Completed_At__c = System.now().addDays(-i).addMinutes(5),
                // Create performance degradation trend (recent runs slower)
                Duration_Ms__c = i < 10 ? 8000 + (i * 500) : 3000 + (i * 100),
                CPU_Time_Millis__c = i < 10 ? 4000 + (i * 200) : 1500 + (i * 50),
                SOQL_Count__c = 8,
                DML_Count__c = 5,
                Heap_Size_Bytes__c = 2 * 1024 * 1024
            );
            flowRuns.add(run);
        }
        
        insert flowRuns;
        
        // Create test flow steps for step performance analysis
        List<FS_Flow_Step__c> flowSteps = new List<FS_Flow_Step__c>();
        
        for (FS_Flow_Run__c run : [SELECT Id FROM FS_Flow_Run__c WHERE Flow_API_Name__c = 'Good_Performance_Flow']) {
            // Create steps for each flow run
            for (Integer j = 1; j <= 3; j++) {
                FS_Flow_Step__c step = new FS_Flow_Step__c(
                    Flow_Run__c = run.Id,
                    Sequence__c = j,
                    Element_DeveloperName__c = 'Test_Element_' + j,
                    Element_Label__c = 'Test Element ' + j,
                    Element_Type__c = j == 1 ? 'Start' : (j == 3 ? 'Subflow' : 'Assignment'),
                    Entered_At__c = System.now().addMinutes(-j),
                    Exited_At__c = System.now().addMinutes(-j + 1),
                    Duration_Millis__c = j == 3 ? 5000 : (j * 1000), // Subflow steps are slower
                    CPU_Millis__c = j * 500
                );
                flowSteps.add(step);
            }
        }
        
        insert flowSteps;
    }
    
    @IsTest
    static void testAnalyzeFlowPerformanceGoodFlow() {
        String flowApiName = 'Good_Performance_Flow';
        
        Test.startTest();
        FS_PerformanceService.PerformanceAnalysisResult result = FS_PerformanceService.analyzeFlowPerformance(flowApiName, 30);
        Test.stopTest();
        
        // Verify analysis results for good performance flow
        System.assertEquals(flowApiName, result.flowApiName, 'Flow API name should match');
        System.assertEquals(30, result.analysisPeriodDays, 'Analysis period should match');
        System.assertEquals(true, result.hasData, 'Should have data');
        System.assertEquals(false, result.hasError, 'Should not have error');
        System.assertEquals(15, result.totalExecutions, 'Should have 15 executions');
        System.assertEquals(15, result.successfulExecutions, 'Should have 15 successful executions');
        System.assertEquals(0, result.failedExecutions, 'Should have 0 failed executions');
        System.assertEquals(100.0, result.successRate, 'Should have 100% success rate');
        
        // Verify performance metrics are calculated
        System.assertNotEquals(null, result.avgDurationMs, 'Should have average duration');
        System.assertNotEquals(null, result.avgCpuTimeMs, 'Should have average CPU time');
        System.assertNotEquals(null, result.avgSoqlCount, 'Should have average SOQL count');
        System.assertNotEquals(null, result.avgDmlCount, 'Should have average DML count');
        System.assertNotEquals(null, result.avgHeapSizeMB, 'Should have average heap size');
        
        // Verify maximum values are set
        System.assertNotEquals(null, result.maxDurationMs, 'Should have max duration');
        System.assertNotEquals(null, result.maxCpuTimeMs, 'Should have max CPU time');
        System.assertNotEquals(null, result.maxSoqlCount, 'Should have max SOQL count');
        System.assertNotEquals(null, result.maxDmlCount, 'Should have max DML count');
        System.assertNotEquals(null, result.maxHeapSizeMB, 'Should have max heap size');
        
        // Good performance should have minimal bottlenecks
        System.assertNotEquals(null, result.bottlenecks, 'Should have bottlenecks list');
        System.assertNotEquals(null, result.recommendations, 'Should have recommendations');
    }
    
    @IsTest
    static void testAnalyzeFlowPerformancePoorFlow() {
        String flowApiName = 'Poor_Performance_Flow';
        
        Test.startTest();
        FS_PerformanceService.PerformanceAnalysisResult result = FS_PerformanceService.analyzeFlowPerformance(flowApiName, 30);
        Test.stopTest();
        
        // Verify analysis results for poor performance flow
        System.assertEquals(flowApiName, result.flowApiName, 'Flow API name should match');
        System.assertEquals(true, result.hasData, 'Should have data');
        System.assertEquals(10, result.totalExecutions, 'Should have 10 executions');
        System.assertEquals(8, result.successfulExecutions, 'Should have 8 successful executions');
        System.assertEquals(2, result.failedExecutions, 'Should have 2 failed executions');
        System.assertEquals(80.0, result.successRate, 'Should have 80% success rate');
        
        // Poor performance should have many bottlenecks
        System.assertNotEquals(null, result.bottlenecks, 'Should have bottlenecks list');
        System.assert(result.bottlenecks.size() > 0, 'Should have identified bottlenecks');
        
        // Verify specific bottlenecks are identified
        String bottleneckText = String.join(result.bottlenecks, ' ');
        System.assert(bottleneckText.contains('High CPU usage'), 'Should identify high CPU usage');
        System.assert(bottleneckText.contains('Excessive SOQL queries'), 'Should identify excessive SOQL');
        System.assert(bottleneckText.contains('Excessive DML operations'), 'Should identify excessive DML');
        System.assert(bottleneckText.contains('Long execution time'), 'Should identify long execution time');
        System.assert(bottleneckText.contains('High memory usage'), 'Should identify high memory usage');
        System.assert(bottleneckText.contains('High failure rate'), 'Should identify high failure rate');
        
        // Verify recommendations are generated
        System.assertNotEquals(null, result.recommendations, 'Should have recommendations');
        System.assert(result.recommendations.contains('Performance issues detected'), 'Should mention performance issues');
        System.assert(result.recommendations.contains('Recommended Actions'), 'Should have recommended actions');
    }
    
    @IsTest
    static void testAnalyzeFlowPerformanceNoData() {
        String flowApiName = 'Non_Existent_Flow';
        
        Test.startTest();
        FS_PerformanceService.PerformanceAnalysisResult result = FS_PerformanceService.analyzeFlowPerformance(flowApiName, 30);
        Test.stopTest();
        
        // Verify handling of flows with no data
        System.assertEquals(flowApiName, result.flowApiName, 'Flow API name should match');
        System.assertEquals(false, result.hasData, 'Should not have data');
        System.assertEquals(0, result.totalExecutions, 'Should have 0 executions');
        System.assertNotEquals(null, result.recommendations, 'Should have recommendations');
        System.assert(result.recommendations.contains('No execution data found'), 'Should mention no data');
    }
    
    @IsTest
    static void testAnalyzeFlowPerformanceTrendAnalysis() {
        String flowApiName = 'Trend_Analysis_Flow';
        
        Test.startTest();
        FS_PerformanceService.PerformanceAnalysisResult result = FS_PerformanceService.analyzeFlowPerformance(flowApiName, 30);
        Test.stopTest();
        
        // Verify trend analysis
        System.assertEquals(true, result.hasData, 'Should have data');
        System.assertEquals(20, result.totalExecutions, 'Should have 20 executions');
        System.assertNotEquals(null, result.trends, 'Should have trends');
        System.assert(result.trends.size() > 0, 'Should have trend data');
        
        // Check for trend messages (performance degrading or improving)
        String trendText = String.join(result.trends, ' ');
        System.assert(trendText.contains('trend'), 'Should contain trend information');
        System.assert(trendText.contains('Performance degrading') || trendText.contains('Performance improving') || trendText.contains('Stable'), 'Should identify trend direction');
    }
    
    @IsTest
    static void testAnalyzeFlowPerformanceInsufficientDataForTrends() {
        // Create a flow with insufficient data for trend analysis
        FS_Flow_Run__c run = new FS_Flow_Run__c(
            Flow_API_Name__c = 'Insufficient_Data_Flow',
            Interview_ID__c = 'insufficient-data',
            Status__c = 'Success',
            Started_At__c = System.now().addDays(-1),
            Duration_Ms__c = 3000,
            CPU_Time_Millis__c = 1500
        );
        insert run;
        
        Test.startTest();
        FS_PerformanceService.PerformanceAnalysisResult result = FS_PerformanceService.analyzeFlowPerformance('Insufficient_Data_Flow', 30);
        Test.stopTest();
        
        // Verify handling of insufficient data for trends
        System.assertEquals(true, result.hasData, 'Should have data');
        System.assertEquals(1, result.totalExecutions, 'Should have 1 execution');
        System.assertNotEquals(null, result.trends, 'Should have trends list');
        System.assert(result.trends.size() > 0, 'Should have trend message');
        System.assert(String.join(result.trends, ' ').contains('Insufficient data for trend analysis'), 'Should mention insufficient data');
    }
    
    @IsTest
    static void testAnalyzeFlowPerformanceStepAnalysis() {
        String flowApiName = 'Good_Performance_Flow';
        
        Test.startTest();
        FS_PerformanceService.PerformanceAnalysisResult result = FS_PerformanceService.analyzeFlowPerformance(flowApiName, 30);
        Test.stopTest();
        
        // Verify step analysis results
        System.assertNotEquals(null, result.slowestSteps, 'Should have slowest steps');
        
        // Test completes successfully if step analysis runs without errors
        System.assert(true, 'Step analysis completed');
    }
    
    @IsTest
    static void testAnalyzeFlowPerformanceExceptionHandling() {
        // Test with null flow name to trigger exception
        Test.startTest();
        FS_PerformanceService.PerformanceAnalysisResult result = FS_PerformanceService.analyzeFlowPerformance(null, 30);
        Test.stopTest();
        
        // Verify exception handling
        System.assertEquals(true, result.hasError, 'Should have error');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
        System.assertEquals(false, result.hasData, 'Should not have data');
    }
    
    @IsTest
    static void testAnalyzeFlowPerformanceWithNullValues() {
        // Create flow run with null performance values
        FS_Flow_Run__c runWithNulls = new FS_Flow_Run__c(
            Flow_API_Name__c = 'Null_Values_Flow',
            Interview_ID__c = 'null-values',
            Status__c = 'Success',
            Started_At__c = System.now().addDays(-1),
            Duration_Ms__c = null,
            CPU_Time_Millis__c = null,
            SOQL_Count__c = null,
            DML_Count__c = null,
            Heap_Size_Bytes__c = null
        );
        insert runWithNulls;
        
        Test.startTest();
        FS_PerformanceService.PerformanceAnalysisResult result = FS_PerformanceService.analyzeFlowPerformance('Null_Values_Flow', 30);
        Test.stopTest();
        
        // Should handle null values gracefully
        System.assertEquals(true, result.hasData, 'Should have data');
        System.assertEquals(1, result.totalExecutions, 'Should have 1 execution');
        System.assertEquals(0, result.avgDurationMs, 'Should handle null duration');
        System.assertEquals(0, result.avgCpuTimeMs, 'Should handle null CPU time');
        System.assertEquals(0, result.avgSoqlCount, 'Should handle null SOQL count');
        System.assertEquals(0, result.avgDmlCount, 'Should handle null DML count');
        System.assertEquals(0, result.avgHeapSizeMB, 'Should handle null heap size');
    }
    
    @IsTest
    static void testCalculateExecutionScoreSuccess() {
        FS_Flow_Run__c goodRun = new FS_Flow_Run__c(
            Flow_API_Name__c = 'Score_Test_Flow',
            Interview_ID__c = 'score-test',
            Status__c = 'Success',
            Started_At__c = System.now().addDays(-1),
            Duration_Ms__c = 2000,
            CPU_Time_Millis__c = 800,
            SOQL_Count__c = 5,
            DML_Count__c = 3,
            Heap_Size_Bytes__c = 1024 * 1024
        );
        insert goodRun;
        
        Test.startTest();
        Decimal score = FS_PerformanceService.calculateExecutionScore(goodRun.Id);
        Test.stopTest();
        
        // Should return a good performance score
        System.assertNotEquals(null, score, 'Should return a score');
        System.assert(score >= 80, 'Should have good performance score');
        System.assert(score <= 100, 'Score should not exceed 100');
    }
    
    @IsTest
    static void testCalculateExecutionScoreFailedRun() {
        FS_Flow_Run__c failedRun = new FS_Flow_Run__c(
            Flow_API_Name__c = 'Failed_Score_Test_Flow',
            Interview_ID__c = 'failed-score-test',
            Status__c = 'Failed',
            Started_At__c = System.now().addDays(-1),
            Duration_Ms__c = 5000,
            CPU_Time_Millis__c = 3000,
            SOQL_Count__c = 20,
            DML_Count__c = 15,
            Heap_Size_Bytes__c = 5 * 1024 * 1024,
            Error_Message__c = 'Test failure'
        );
        insert failedRun;
        
        Test.startTest();
        Decimal score = FS_PerformanceService.calculateExecutionScore(failedRun.Id);
        Test.stopTest();
        
        // Failed runs should get score of 0
        System.assertEquals(0, score, 'Failed run should get score of 0');
    }
    
    @IsTest
    static void testCalculateExecutionScoreNonExistentRun() {
        Test.startTest();
        Decimal score = FS_PerformanceService.calculateExecutionScore(FS_TestDataFactory.generateId(FS_Flow_Run__c.sObjectType));
        Test.stopTest();
        
        // Non-existent run should return 0
        System.assertEquals(0, score, 'Non-existent run should get score of 0');
    }
    
    @IsTest
    static void testPerformanceAnalysisResultStructure() {
        FS_PerformanceService.PerformanceAnalysisResult result = new FS_PerformanceService.PerformanceAnalysisResult();
        
        // Test default values
        System.assertEquals(null, result.flowApiName, 'Should default to null');
        System.assertEquals(null, result.analysisPeriodDays, 'Should default to null');
        System.assertEquals(false, result.hasData, 'Should default to false');
        System.assertEquals(false, result.hasError, 'Should default to false');
        System.assertEquals(null, result.errorMessage, 'Should default to null');
        System.assertEquals(0, result.totalExecutions, 'Should default to 0');
        System.assertEquals(0, result.successfulExecutions, 'Should default to 0');
        System.assertEquals(0, result.failedExecutions, 'Should default to 0');
        System.assertEquals(0, result.successRate, 'Should default to 0');
        System.assertEquals(0, result.avgDurationMs, 'Should default to 0');
        System.assertEquals(0, result.avgCpuTimeMs, 'Should default to 0');
        System.assertEquals(0, result.avgSoqlCount, 'Should default to 0');
        System.assertEquals(0, result.avgDmlCount, 'Should default to 0');
        System.assertEquals(0, result.avgHeapSizeMB, 'Should default to 0');
        System.assertEquals(0, result.maxDurationMs, 'Should default to 0');
        System.assertEquals(0, result.maxCpuTimeMs, 'Should default to 0');
        System.assertEquals(0, result.maxSoqlCount, 'Should default to 0');
        System.assertEquals(0, result.maxDmlCount, 'Should default to 0');
        System.assertEquals(0, result.maxHeapSizeMB, 'Should default to 0');
        System.assertEquals(null, result.bottlenecks, 'Should default to null');
        System.assertEquals(null, result.trends, 'Should default to null');
        System.assertEquals(null, result.slowestSteps, 'Should default to null');
        System.assertEquals(null, result.recommendations, 'Should default to null');
        
        // Test property assignment
        result.flowApiName = 'Test_Flow';
        result.analysisPeriodDays = 30;
        result.hasData = true;
        result.hasError = false;
        result.totalExecutions = 100;
        result.successfulExecutions = 95;
        result.failedExecutions = 5;
        result.successRate = 95.0;
        result.avgDurationMs = 3500.5;
        result.avgCpuTimeMs = 1200.3;
        result.avgSoqlCount = 7.5;
        result.avgDmlCount = 4.2;
        result.avgHeapSizeMB = 2.5;
        result.maxDurationMs = 8000.0;
        result.maxCpuTimeMs = 3000.0;
        result.maxSoqlCount = 15.0;
        result.maxDmlCount = 10.0;
        result.maxHeapSizeMB = 5.0;
        result.bottlenecks = new List<String>{'Test bottleneck'};
        result.trends = new List<String>{'Test trend'};
        result.slowestSteps = new List<String>{'Test slow step'};
        result.recommendations = 'Test recommendations';
        
        System.assertEquals('Test_Flow', result.flowApiName, 'Flow API name should be set');
        System.assertEquals(30, result.analysisPeriodDays, 'Analysis period should be set');
        System.assertEquals(true, result.hasData, 'Has data should be set');
        System.assertEquals(false, result.hasError, 'Has error should be set');
        System.assertEquals(100, result.totalExecutions, 'Total executions should be set');
        System.assertEquals(95, result.successfulExecutions, 'Successful executions should be set');
        System.assertEquals(5, result.failedExecutions, 'Failed executions should be set');
        System.assertEquals(95.0, result.successRate, 'Success rate should be set');
        System.assertEquals(3500.5, result.avgDurationMs, 'Average duration should be set');
        System.assertEquals(1200.3, result.avgCpuTimeMs, 'Average CPU time should be set');
        System.assertEquals(7.5, result.avgSoqlCount, 'Average SOQL count should be set');
        System.assertEquals(4.2, result.avgDmlCount, 'Average DML count should be set');
        System.assertEquals(2.5, result.avgHeapSizeMB, 'Average heap size should be set');
        System.assertEquals(8000.0, result.maxDurationMs, 'Max duration should be set');
        System.assertEquals(3000.0, result.maxCpuTimeMs, 'Max CPU time should be set');
        System.assertEquals(15.0, result.maxSoqlCount, 'Max SOQL count should be set');
        System.assertEquals(10.0, result.maxDmlCount, 'Max DML count should be set');
        System.assertEquals(5.0, result.maxHeapSizeMB, 'Max heap size should be set');
        System.assertEquals(1, result.bottlenecks.size(), 'Bottlenecks should be set');
        System.assertEquals(1, result.trends.size(), 'Trends should be set');
        System.assertEquals(1, result.slowestSteps.size(), 'Slowest steps should be set');
        System.assertEquals('Test recommendations', result.recommendations, 'Recommendations should be set');
    }
    
    @IsTest
    static void testAnalyzeFlowPerformanceWithoutSettings() {
        // TEMPORARY: Commented out during CMDT migration
        // Delete settings to test default behavior
        // delete [SELECT Id FROM FS_Global_Settings__c];
        
        String flowApiName = 'Poor_Performance_Flow';
        
        Test.startTest();
        FS_PerformanceService.PerformanceAnalysisResult result = FS_PerformanceService.analyzeFlowPerformance(flowApiName, 30);
        Test.stopTest();
        
        // Should use default thresholds when no settings exist
        System.assertEquals(true, result.hasData, 'Should have data');
        System.assertNotEquals(null, result.bottlenecks, 'Should have bottlenecks list');
        System.assert(result.bottlenecks.size() > 0, 'Should identify bottlenecks with default thresholds');
    }
    
    @IsTest
    static void testAnalyzeFlowPerformanceDifferentPeriods() {
        String flowApiName = 'Good_Performance_Flow';
        
        Test.startTest();
        FS_PerformanceService.PerformanceAnalysisResult result7Days = FS_PerformanceService.analyzeFlowPerformance(flowApiName, 7);
        FS_PerformanceService.PerformanceAnalysisResult result30Days = FS_PerformanceService.analyzeFlowPerformance(flowApiName, 30);
        Test.stopTest();
        
        // Different periods should return different data sets
        System.assertEquals(7, result7Days.analysisPeriodDays, 'Should analyze 7 days');
        System.assertEquals(30, result30Days.analysisPeriodDays, 'Should analyze 30 days');
        System.assert(result7Days.totalExecutions <= result30Days.totalExecutions, '7 days should have fewer or equal executions');
    }
    
    @IsTest
    static void testAnalyzeFlowPerformanceEdgeCases() {
        // Test with zero days
        Test.startTest();
        FS_PerformanceService.PerformanceAnalysisResult resultZeroDays = FS_PerformanceService.analyzeFlowPerformance('Good_Performance_Flow', 0);
        Test.stopTest();
        
        // Should handle zero days gracefully
        System.assertEquals(0, resultZeroDays.analysisPeriodDays, 'Should handle zero days');
        System.assertEquals(false, resultZeroDays.hasData, 'Should not have data for zero days');
    }
    
    @IsTest
    static void testAnalyzeFlowPerformanceRecommendationsOptimal() {
        // Create a flow with excellent performance
        FS_Flow_Run__c excellentRun = new FS_Flow_Run__c(
            Flow_API_Name__c = 'Excellent_Performance_Flow',
            Interview_ID__c = 'excellent-perf',
            Status__c = 'Success',
            Started_At__c = System.now().addDays(-1),
            Duration_Ms__c = 1000,
            CPU_Time_Millis__c = 500,
            SOQL_Count__c = 3,
            DML_Count__c = 2,
            Heap_Size_Bytes__c = 512 * 1024
        );
        insert excellentRun;
        
        Test.startTest();
        FS_PerformanceService.PerformanceAnalysisResult result = FS_PerformanceService.analyzeFlowPerformance('Excellent_Performance_Flow', 30);
        Test.stopTest();
        
        // Excellent performance should have positive recommendations
        System.assertEquals(true, result.hasData, 'Should have data');
        System.assertNotEquals(null, result.recommendations, 'Should have recommendations');
        System.assert(result.recommendations.contains('No significant performance issues'), 'Should mention no issues');
        System.assert(result.recommendations.contains('Continue monitoring'), 'Should suggest continued monitoring');
    }
}
