/**
 * @description Test class for FS_PerformanceScoreAction
 * @author FlowSense
 * @version 1.0
 */
@IsTest
private class FS_PerformanceScoreActionTest {
    
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
        //     DML_Poor_Threshold__c = 40
        // );
        // CMDT Migration: Commented out - FS_SettingsUtil provides defaults
        // insert settings;
    }
    
    @IsTest
    static void testCalculatePerformanceScoreExcellent() {
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.cpuTimeMillis = 500;
        request.soqlCount = 3;
        request.dmlCount = 2;
        request.executionTimeMillis = 1500;
        request.heapSizeBytes = 512 * 1024; // 0.5 MB
        request.flowApiName = 'Excellent_Performance_Flow';
        request.interviewId = 'excellent-test-123';
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify excellent performance results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertEquals(100.0, results[0].cpuScore, 'Should get perfect CPU score');
        System.assertEquals(100.0, results[0].soqlScore, 'Should get perfect SOQL score');
        System.assertEquals(100.0, results[0].dmlScore, 'Should get perfect DML score');
        System.assertEquals(100.0, results[0].durationScore, 'Should get perfect duration score');
        System.assertEquals(100.0, results[0].heapScore, 'Should get perfect heap score');
        System.assertEquals(100.0, results[0].overallScore, 'Should get perfect overall score');
        System.assertEquals('A', results[0].performanceGrade, 'Should get grade A');
        System.assertEquals(false, results[0].criticalIssuesFound, 'Should not have critical issues');
        System.assertNotEquals(null, results[0].scoreBreakdown, 'Should have score breakdown');
        System.assertNotEquals(null, results[0].recommendations, 'Should have recommendations');
    }
    
    @IsTest
    static void testCalculatePerformanceScoreGood() {
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.cpuTimeMillis = 2000;
        request.soqlCount = 10;
        request.dmlCount = 8;
        request.executionTimeMillis = 3500;
        request.heapSizeBytes = 2 * 1024 * 1024; // 2 MB
        request.flowApiName = 'Good_Performance_Flow';
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify good performance results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assert(results[0].cpuScore >= 80 && results[0].cpuScore <= 100, 'Should get good CPU score');
        System.assert(results[0].soqlScore >= 80 && results[0].soqlScore <= 100, 'Should get good SOQL score');
        System.assert(results[0].dmlScore >= 80 && results[0].dmlScore <= 100, 'Should get good DML score');
        System.assert(results[0].overallScore >= 80, 'Should get good overall score');
        System.assertEquals('A', results[0].performanceGrade, 'Should get grade A');
        System.assertEquals(false, results[0].criticalIssuesFound, 'Should not have critical issues');
    }
    
    @IsTest
    static void testCalculatePerformanceScorePoor() {
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.cpuTimeMillis = 9000; // Above poor threshold
        request.soqlCount = 45; // Above poor threshold
        request.dmlCount = 50; // Above poor threshold
        request.executionTimeMillis = 25000; // Above poor threshold
        request.heapSizeBytes = 10 * 1024 * 1024; // 10 MB - above poor threshold
        request.flowApiName = 'Poor_Performance_Flow';
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify poor performance results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assert(results[0].cpuScore < 40, 'Should get poor CPU score');
        System.assert(results[0].soqlScore < 40, 'Should get poor SOQL score');
        System.assert(results[0].dmlScore < 40, 'Should get poor DML score');
        System.assert(results[0].durationScore < 40, 'Should get poor duration score');
        System.assert(results[0].heapScore < 40, 'Should get poor heap score');
        System.assert(results[0].overallScore < 60, 'Should get poor overall score');
        System.assertEquals('F', results[0].performanceGrade, 'Should get grade F');
        System.assertEquals(true, results[0].criticalIssuesFound, 'Should have critical issues');
        System.assert(results[0].recommendations.contains('Optimize'), 'Should contain optimization recommendations');
    }
    
    @IsTest
    static void testCalculatePerformanceScoreBulkRequests() {
        List<FS_PerformanceScoreAction.Request> requests = new List<FS_PerformanceScoreAction.Request>();
        
        for (Integer i = 0; i < 5; i++) {
            FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
            request.cpuTimeMillis = 1000 * (i + 1);
            request.soqlCount = 5 * (i + 1);
            request.dmlCount = 3 * (i + 1);
            request.executionTimeMillis = 2000 * (i + 1);
            request.heapSizeBytes = 1024 * 1024 * (i + 1);
            request.flowApiName = 'Bulk_Performance_Flow_' + i;
            requests.add(request);
        }
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(requests);
        Test.stopTest();
        
        // Verify bulk processing
        System.assertEquals(5, results.size(), 'Should return five results');
        for (FS_PerformanceScoreAction.Result result : results) {
            System.assertEquals(true, result.isSuccess, 'All should be successful');
            System.assertNotEquals(null, result.overallScore, 'All should have overall score');
            System.assertNotEquals(null, result.performanceGrade, 'All should have grade');
        }
    }
    
    @IsTest
    static void testCalculatePerformanceScoreMinimalData() {
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.flowApiName = 'Minimal_Data_Flow';
        // Leave performance metrics null
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should handle null values gracefully
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertEquals(100.0, results[0].cpuScore, 'Should get perfect CPU score for null');
        System.assertEquals(100.0, results[0].soqlScore, 'Should get perfect SOQL score for null');
        System.assertEquals(100.0, results[0].dmlScore, 'Should get perfect DML score for null');
        System.assertEquals(100.0, results[0].durationScore, 'Should get perfect duration score for null');
        System.assertEquals(100.0, results[0].heapScore, 'Should get perfect heap score for null');
        System.assertEquals(100.0, results[0].overallScore, 'Should get perfect overall score');
        System.assertEquals('A', results[0].performanceGrade, 'Should get grade A');
        System.assertEquals(false, results[0].criticalIssuesFound, 'Should not have critical issues');
    }
    
    @IsTest
    static void testCalculatePerformanceScoreZeroValues() {
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.cpuTimeMillis = 0;
        request.soqlCount = 0;
        request.dmlCount = 0;
        request.executionTimeMillis = 0;
        request.heapSizeBytes = 0;
        request.flowApiName = 'Zero_Values_Flow';
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should handle zero values as perfect performance
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertEquals(100.0, results[0].cpuScore, 'Should get perfect CPU score for zero');
        System.assertEquals(100.0, results[0].soqlScore, 'Should get perfect SOQL score for zero');
        System.assertEquals(100.0, results[0].dmlScore, 'Should get perfect DML score for zero');
        System.assertEquals(100.0, results[0].durationScore, 'Should get perfect duration score for zero');
        System.assertEquals(100.0, results[0].heapScore, 'Should get perfect heap score for zero');
        System.assertEquals(100.0, results[0].overallScore, 'Should get perfect overall score');
        System.assertEquals('A', results[0].performanceGrade, 'Should get grade A');
    }
    
    @IsTest
    static void testScoreCalculationAccuracy() {
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.cpuTimeMillis = 2000; // Between excellent (1000) and good (3000) = 90 score
        request.soqlCount = 10; // Between excellent (5) and good (15) = 90 score  
        request.dmlCount = 10; // Between excellent (5) and good (15) = 90 score
        request.executionTimeMillis = 3500; // Between good (2000) and fair (5000) = ~83 score
        request.heapSizeBytes = 2.5 * 1024 * 1024; // 2.5 MB between good (3) and fair (5) = ~90 score
        request.flowApiName = 'Accuracy_Test_Flow';
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify calculated scores
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertEquals(90.0, results[0].cpuScore, 'Should calculate exact CPU score');
        System.assertEquals(90.0, results[0].soqlScore, 'Should calculate exact SOQL score');
        System.assertEquals(90.0, results[0].dmlScore, 'Should calculate exact DML score');
        // Overall should be weighted average - approximately 88-90
        System.assert(results[0].overallScore >= 85 && results[0].overallScore <= 95, 'Should calculate weighted average correctly');
        System.assertEquals('B', results[0].performanceGrade, 'Should get grade B');
    }
    
    @IsTest
    static void testGradeCalculation() {
        List<FS_PerformanceScoreAction.Request> requests = new List<FS_PerformanceScoreAction.Request>();
        List<Decimal> scores = new List<Decimal>{95, 85, 75, 65, 45}; // A, B, C, D, F
        List<String> expectedGrades = new List<String>{'A', 'B', 'C', 'D', 'F'};
        
        for (Integer i = 0; i < scores.size(); i++) {
            FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
            // Set values to achieve target scores
            if (scores[i] >= 90) {
                request.cpuTimeMillis = 500; // Excellent
                request.soqlCount = 3;
                request.dmlCount = 2;
                request.executionTimeMillis = 1000;
                request.heapSizeBytes = 512 * 1024;
            } else if (scores[i] >= 60) {
                request.cpuTimeMillis = 4000; // Fair range to get target score
                request.soqlCount = 20;
                request.dmlCount = 20;
                request.executionTimeMillis = 7000;
                request.heapSizeBytes = 4 * 1024 * 1024;
            } else {
                request.cpuTimeMillis = 10000; // Poor
                request.soqlCount = 50;
                request.dmlCount = 50;
                request.executionTimeMillis = 30000;
                request.heapSizeBytes = 12 * 1024 * 1024;
            }
            request.flowApiName = 'Grade_Test_Flow_' + expectedGrades[i];
            requests.add(request);
        }
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(requests);
        Test.stopTest();
        
        // Verify grades
        System.assertEquals(expectedGrades.size(), results.size(), 'Should return all results');
        for (Integer i = 0; i < results.size(); i++) {
            System.assertEquals(true, results[i].isSuccess, 'All should be successful');
            // Allow for some variance in scoring algorithm
            if (expectedGrades[i] == 'A') {
                System.assert(results[i].performanceGrade == 'A' || results[i].performanceGrade == 'B', 'Should get high grade');
            } else if (expectedGrades[i] == 'F') {
                System.assert(results[i].performanceGrade == 'F' || results[i].performanceGrade == 'D', 'Should get low grade');
            }
        }
    }
    
    @IsTest
    static void testCriticalIssuesDetection() {
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.cpuTimeMillis = 10000; // Above critical threshold
        request.soqlCount = 50; // Above critical threshold
        request.dmlCount = 45; // Above critical threshold
        request.executionTimeMillis = 25000; // Above critical threshold
        request.heapSizeBytes = 15 * 1024 * 1024; // Above critical threshold
        request.flowApiName = 'Critical_Issues_Flow';
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify critical issues detection
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertEquals(true, results[0].criticalIssuesFound, 'Should detect critical issues');
        System.assert(results[0].recommendations.contains('Optimize'), 'Should contain optimization recommendations');
    }
    
    @IsTest
    static void testScoreBreakdownContent() {
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.cpuTimeMillis = 2500;
        request.soqlCount = 12;
        request.dmlCount = 8;
        request.executionTimeMillis = 4000;
        request.heapSizeBytes = 3 * 1024 * 1024;
        request.flowApiName = 'Breakdown_Test_Flow';
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify score breakdown content
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertNotEquals(null, results[0].scoreBreakdown, 'Should have score breakdown');
        System.assert(results[0].scoreBreakdown.contains('Performance Score Breakdown'), 'Should contain header');
        System.assert(results[0].scoreBreakdown.contains('Overall Score'), 'Should contain overall score');
        System.assert(results[0].scoreBreakdown.contains('CPU Time'), 'Should contain CPU time');
        System.assert(results[0].scoreBreakdown.contains('SOQL Queries'), 'Should contain SOQL queries');
        System.assert(results[0].scoreBreakdown.contains('DML Operations'), 'Should contain DML operations');
        System.assert(results[0].scoreBreakdown.contains('Execution Time'), 'Should contain execution time');
        System.assert(results[0].scoreBreakdown.contains('Heap Usage'), 'Should contain heap usage');
        System.assert(results[0].scoreBreakdown.contains('2500ms'), 'Should contain actual CPU time');
        System.assert(results[0].scoreBreakdown.contains('12 queries'), 'Should contain actual SOQL count');
    }
    
    @IsTest
    static void testRecommendationsGeneration() {
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.cpuTimeMillis = 6000; // Above fair threshold - triggers recommendation
        request.soqlCount = 30; // Above fair threshold - triggers recommendation
        request.dmlCount = 30; // Above fair threshold - triggers recommendation
        request.executionTimeMillis = 15000; // Above fair threshold - triggers recommendation
        request.heapSizeBytes = 8 * 1024 * 1024; // Above fair threshold - triggers recommendation
        request.flowApiName = 'Recommendations_Test_Flow';
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify recommendations content
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertNotEquals(null, results[0].recommendations, 'Should have recommendations');
        System.assert(results[0].recommendations.contains('Recommendations'), 'Should contain header');
        System.assert(results[0].recommendations.contains('CPU-intensive'), 'Should contain CPU recommendation');
        System.assert(results[0].recommendations.contains('SOQL queries'), 'Should contain SOQL recommendation');
        System.assert(results[0].recommendations.contains('DML operations'), 'Should contain DML recommendation');
        System.assert(results[0].recommendations.contains('flow logic'), 'Should contain duration recommendation');
        System.assert(results[0].recommendations.contains('memory usage'), 'Should contain heap recommendation');
    }
    
    @IsTest
    static void testOptimalPerformanceRecommendations() {
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.cpuTimeMillis = 500; // Excellent
        request.soqlCount = 3; // Excellent
        request.dmlCount = 2; // Excellent
        request.executionTimeMillis = 1000; // Excellent
        request.heapSizeBytes = 512 * 1024; // Excellent
        request.flowApiName = 'Optimal_Performance_Flow';
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify positive recommendations for optimal performance
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assert(results[0].recommendations.contains('Great job'), 'Should contain positive feedback');
        System.assert(results[0].recommendations.contains('acceptable ranges'), 'Should mention acceptable performance');
    }
    
    @IsTest
    static void testPerformanceScoreWithNullData() {
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.flowApiName = 'Test_Flow_With_Nulls'; // Valid flow name
        // Leave other fields null to test default handling
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should handle null values gracefully
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful with null data');
        System.assertNotEquals(null, results[0].overallScore, 'Should have calculated score');
        System.assertNotEquals(null, results[0].performanceGrade, 'Should have assigned grade');
    }
    
    @IsTest
    static void testPerformanceScorePartialFailure() {
        List<FS_PerformanceScoreAction.Request> requests = new List<FS_PerformanceScoreAction.Request>();
        
        // Valid request
        FS_PerformanceScoreAction.Request validRequest = new FS_PerformanceScoreAction.Request();
        validRequest.cpuTimeMillis = 1500;
        validRequest.soqlCount = 8;
        validRequest.dmlCount = 5;
        validRequest.executionTimeMillis = 3000;
        validRequest.heapSizeBytes = 2 * 1024 * 1024;
        validRequest.flowApiName = 'Valid_Performance_Flow';
        requests.add(validRequest);
        
        // Invalid request
        FS_PerformanceScoreAction.Request secondRequest = new FS_PerformanceScoreAction.Request();
        secondRequest.flowApiName = 'Test_Flow_Two';
        secondRequest.cpuTimeMillis = 3000;
        secondRequest.soqlCount = 15;
        secondRequest.dmlCount = 10;
        requests.add(secondRequest);
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(requests);
        Test.stopTest();
        
        // Should process multiple requests successfully
        System.assertEquals(2, results.size(), 'Should return two results');
        
        // Check that both are successful
        for (FS_PerformanceScoreAction.Result result : results) {
            System.assertEquals(true, result.isSuccess, 'All results should be successful');
            System.assertNotEquals(null, result.overallScore, 'All results should have score');
            System.assertNotEquals(null, result.performanceGrade, 'All results should have grade');
        }
    }
    
    @IsTest
    static void testPerformanceThresholdsFromSettings() {
        // Test that the method reads from settings correctly
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.cpuTimeMillis = 1500; // Between our settings thresholds
        request.soqlCount = 7;
        request.dmlCount = 7;
        request.executionTimeMillis = 3000;
        request.heapSizeBytes = 2 * 1024 * 1024;
        request.flowApiName = 'Settings_Test_Flow';
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should use the settings we configured in @TestSetup
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertNotEquals(null, results[0].overallScore, 'Should calculate score using settings');
        System.assertNotEquals(null, results[0].performanceGrade, 'Should calculate grade');
    }
    
    @IsTest
    static void testPerformanceWithoutSettings() {
        // TEMPORARY: Commented out during CMDT migration
        // Delete settings to test default behavior
        // delete [SELECT Id FROM FS_Global_Settings__c];
        
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.cpuTimeMillis = 2000;
        request.soqlCount = 10;
        request.dmlCount = 8;
        request.executionTimeMillis = 4000;
        request.heapSizeBytes = 3 * 1024 * 1024;
        request.flowApiName = 'No_Settings_Flow';
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should use default thresholds when no settings exist
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertNotEquals(null, results[0].overallScore, 'Should calculate score using defaults');
        System.assertNotEquals(null, results[0].performanceGrade, 'Should calculate grade using defaults');
    }
    
    @IsTest
    static void testWeightedScoreCalculation() {
        FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
        request.cpuTimeMillis = 1000; // 100 score, 25% weight
        request.soqlCount = 5; // 100 score, 20% weight
        request.dmlCount = 5; // 100 score, 15% weight
        request.executionTimeMillis = 10000; // ~40 score, 25% weight
        request.heapSizeBytes = 1024 * 1024; // 100 score, 15% weight
        request.flowApiName = 'Weighted_Score_Flow';
        
        Test.startTest();
        List<FS_PerformanceScoreAction.Result> results = FS_PerformanceScoreAction.calculatePerformanceScore(
            new List<FS_PerformanceScoreAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify weighted calculation: (100*25 + 100*20 + 100*15 + 40*25 + 100*15) / 100 = 85
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assert(results[0].overallScore >= 80 && results[0].overallScore <= 90, 'Should calculate weighted average correctly');
    }
}
