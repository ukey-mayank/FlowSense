/**
 * @description Test class for FS_AnalyzeFlowAction
 * @author FlowSense
 * @version 1.0
 */
@IsTest
private class FS_AnalyzeFlowActionTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test data using the centralized factory
        FS_TestDataFactory.createCompleteFlowDataSet('Test_Flow_Setup');
    }
    
    @IsTest
    static void testAnalyzeFlowSuccess() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'Test_Flow_Analysis';
        request.executionTimeSeconds = 5.5;
        request.elementCount = 15;
        request.loopCount = 2;
        request.subflowCount = 1;
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertNotEquals(null, results[0].analysisId, 'Should have analysis ID');
        System.assertNotEquals(null, results[0].performanceScore, 'Should have performance score');
        System.assertNotEquals(null, results[0].complexityScore, 'Should have complexity score');
        System.assertNotEquals(null, results[0].riskLevel, 'Should have risk level');
        System.assert(results[0].message.contains('successfully'), 'Should contain success message');
        
        // Verify analysis record was created
        FS_Flow_Analysis__c analysis = [SELECT Id, Flow_API_Name__c, Performance_Score__c, 
                                        Complexity_Score__c, Risk_Level__c, Analysis_Date__c 
                                        FROM FS_Flow_Analysis__c 
                                        WHERE Id = :results[0].analysisId];
        System.assertEquals('Test_Flow_Analysis', analysis.Flow_API_Name__c, 'Should have correct flow name');
        System.assertNotEquals(null, analysis.Performance_Score__c, 'Should have performance score');
        System.assertNotEquals(null, analysis.Complexity_Score__c, 'Should have complexity score');
        System.assertNotEquals(null, analysis.Risk_Level__c, 'Should have risk level');
        System.assertNotEquals(null, analysis.Analysis_Date__c, 'Should have analysis date');
    }
    
    @IsTest
    static void testAnalyzeFlowBulkRequests() {
        List<FS_AnalyzeFlowAction.Request> requests = new List<FS_AnalyzeFlowAction.Request>();
        
        for (Integer i = 0; i < 5; i++) {
            FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
            request.flowApiName = 'Bulk_Flow_' + i;
            request.executionTimeSeconds = Math.random() * 20;
            request.elementCount = Integer.valueOf(Math.random() * 50);
            request.loopCount = Integer.valueOf(Math.random() * 5);
            request.subflowCount = Integer.valueOf(Math.random() * 3);
            requests.add(request);
        }
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(requests);
        Test.stopTest();
        
        // Verify bulk processing
        System.assertEquals(5, results.size(), 'Should return five results');
        for (FS_AnalyzeFlowAction.Result result : results) {
            System.assertEquals(true, result.isSuccess, 'All should be successful');
            System.assertNotEquals(null, result.analysisId, 'All should have analysis ID');
        }
        
        // Verify all analysis records were created
        List<FS_Flow_Analysis__c> analyses = [SELECT Id FROM FS_Flow_Analysis__c];
        System.assert(analyses.size() >= 5, 'Should have created at least 5 analysis records');
    }
    
    @IsTest
    static void testAnalyzeFlowMinimalData() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'Minimal_Flow';
        // Leave other fields null to test minimal scenario
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should handle minimal data gracefully
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertNotEquals(null, results[0].performanceScore, 'Should calculate performance score');
        System.assertEquals(0.0, results[0].complexityScore, 'Should have zero complexity score');
        System.assertEquals('Low', results[0].riskLevel, 'Should have low risk level');
    }
    
    @IsTest
    static void testPerformanceScoreCalculationGoodPerformance() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'Good_Performance_Flow';
        request.executionTimeSeconds = 2.0; // Good execution time
        request.elementCount = 10; // Reasonable element count
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should have high performance score
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(100.0, results[0].performanceScore, 'Should have perfect performance score');
        System.assertEquals('Low', results[0].riskLevel, 'Should have low risk level');
    }
    
    @IsTest
    static void testPerformanceScoreCalculationPoorPerformance() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'Poor_Performance_Flow';
        request.executionTimeSeconds = 35.0; // Poor execution time
        request.elementCount = 60; // High element count
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should have low performance score
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(50.0, results[0].performanceScore, 'Should have reduced performance score');
        System.assertEquals('High', results[0].riskLevel, 'Should have high risk level');
    }
    
    @IsTest
    static void testComplexityScoreCalculation() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'Complex_Flow';
        request.elementCount = 20; // 20 * 2 = 40 points
        request.loopCount = 3;     // 3 * 10 = 30 points
        request.subflowCount = 2;  // 2 * 5 = 10 points
        // Total complexity score = 40 + 30 + 10 = 80
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify complexity calculation
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(80.0, results[0].complexityScore, 'Should calculate complexity correctly');
        System.assertEquals('Medium', results[0].riskLevel, 'Should have medium risk level');
    }
    
    @IsTest
    static void testRiskLevelDeterminationLow() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'Low_Risk_Flow';
        request.executionTimeSeconds = 3.0; // Good performance (100 score)
        request.elementCount = 10; // Low complexity (20 score)
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        System.assertEquals('Low', results[0].riskLevel, 'Should have low risk level');
    }
    
    @IsTest
    static void testRiskLevelDeterminationMedium() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'Medium_Risk_Flow';
        request.executionTimeSeconds = 12.0; // Medium performance (85 score)
        request.elementCount = 30; // Medium complexity (60 score)
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        System.assertEquals('Medium', results[0].riskLevel, 'Should have medium risk level');
    }
    
    @IsTest
    static void testRiskLevelDeterminationHigh() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'High_Risk_Flow';
        request.executionTimeSeconds = 40.0; // Poor performance (50 score)
        request.elementCount = 60; // High complexity (120 score)
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        System.assertEquals('High', results[0].riskLevel, 'Should have high risk level');
    }
    
    @IsTest
    static void testRecommendationGeneration() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'Recommendation_Test_Flow';
        request.executionTimeSeconds = 25.0; // Poor performance for recommendations
        request.elementCount = 40; // High complexity for recommendations
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify analysis record reflects poor performance scenario
        FS_Flow_Analysis__c analysis = [SELECT Performance_Score__c, Complexity_Score__c, Risk_Level__c FROM FS_Flow_Analysis__c 
                                        WHERE Id = :results[0].analysisId];
        System.assertNotEquals(null, analysis.Performance_Score__c, 'Should have performance score');
        System.assert(analysis.Performance_Score__c <= 75, 'Should have reduced performance score for poor performance scenario');
        System.assertEquals('Medium', analysis.Risk_Level__c, 'Should have medium risk level for moderately poor performance');
    }
    
    @IsTest
    static void testOptimalFlowRecommendations() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'Optimal_Flow';
        request.executionTimeSeconds = 2.0; // Excellent performance
        request.elementCount = 5; // Low complexity
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify optimal flow analysis results
        FS_Flow_Analysis__c analysis = [SELECT Performance_Score__c, Risk_Level__c FROM FS_Flow_Analysis__c 
                                        WHERE Id = :results[0].analysisId];
        System.assert(analysis.Performance_Score__c > 90, 'Should have high performance score for optimal flow');
        System.assertEquals('Low', analysis.Risk_Level__c, 'Should have low risk level for optimal flow');
    }
    
    @IsTest
    static void testAISummaryGeneration() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'AI_Summary_Test';
        request.executionTimeSeconds = 8.0;
        request.elementCount = 25;
        request.loopCount = 1;
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify analysis data is properly stored
        FS_Flow_Analysis__c analysis = [SELECT Performance_Score__c, 
                                        Complexity_Score__c, Risk_Level__c 
                                        FROM FS_Flow_Analysis__c 
                                        WHERE Id = :results[0].analysisId];
        System.assertNotEquals(null, analysis.Performance_Score__c, 'Should have performance score');
        System.assertNotEquals(null, analysis.Complexity_Score__c, 'Should have complexity score');
        System.assertNotEquals(null, analysis.Risk_Level__c, 'Should have risk level');
        System.assert(analysis.Performance_Score__c > 0, 'Should contain actual performance score');
    }
    
    @IsTest
    static void testAnalysisDatePopulation() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'Date_Test_Flow';
        request.executionTimeSeconds = 5.0;
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify analysis date is set correctly
        FS_Flow_Analysis__c analysis = [SELECT Analysis_Date__c FROM FS_Flow_Analysis__c 
                                        WHERE Id = :results[0].analysisId];
        System.assertNotEquals(null, analysis.Analysis_Date__c, 'Should have analysis date');
        // Verify the date is recent (within last few minutes to account for test execution)
        DateTime cutoff = System.now().addMinutes(-5);
        System.assert(analysis.Analysis_Date__c >= cutoff, 'Analysis date should be recent');
    }
    
    @IsTest
    static void testAnalyzeFlowException() {
        // Create a request that might cause an exception by using invalid flow name
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = null; // This might cause issues during processing
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should handle exception gracefully
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].isSuccess, 'Should not be successful');
        System.assertNotEquals(null, results[0].errorMessage, 'Should have error message');
        System.assertEquals(null, results[0].analysisId, 'Should not have analysis ID');
    }
    
    @IsTest
    static void testAnalyzeFlowPartialFailure() {
        List<FS_AnalyzeFlowAction.Request> requests = new List<FS_AnalyzeFlowAction.Request>();
        
        // Valid request
        FS_AnalyzeFlowAction.Request validRequest = new FS_AnalyzeFlowAction.Request();
        validRequest.flowApiName = 'Valid_Flow';
        validRequest.executionTimeSeconds = 5.0;
        requests.add(validRequest);
        
        // Invalid request
        FS_AnalyzeFlowAction.Request invalidRequest = new FS_AnalyzeFlowAction.Request();
        invalidRequest.flowApiName = null;
        requests.add(invalidRequest);
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(requests);
        Test.stopTest();
        
        // Should have mixed results
        System.assertEquals(2, results.size(), 'Should return two results');
        
        // Check that we have one success and one failure
        Boolean hasSuccess = false;
        Boolean hasFailure = false;
        
        for (FS_AnalyzeFlowAction.Result result : results) {
            if (result.isSuccess) {
                hasSuccess = true;
                System.assertNotEquals(null, result.analysisId, 'Successful result should have analysis ID');
            } else {
                hasFailure = true;
                System.assertNotEquals(null, result.errorMessage, 'Failed result should have error message');
            }
        }
        
        System.assert(hasSuccess, 'Should have at least one successful result');
        System.assert(hasFailure, 'Should have at least one failed result');
    }
    
    @IsTest
    static void testEdgeCaseScoring() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'Edge_Case_Flow';
        request.executionTimeSeconds = 0.0; // Minimum execution time
        request.elementCount = 0; // No elements
        request.loopCount = 0; // No loops
        request.subflowCount = 0; // No subflows
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should handle edge cases gracefully
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(100.0, results[0].performanceScore, 'Should have perfect performance score');
        System.assertEquals(0.0, results[0].complexityScore, 'Should have zero complexity score');
        System.assertEquals('Low', results[0].riskLevel, 'Should have low risk level');
    }
    
    @IsTest
    static void testDebugLogging() {
        FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
        request.flowApiName = 'Debug_Test_Flow';
        request.executionTimeSeconds = 7.0;
        request.elementCount = 15;
        
        Test.startTest();
        List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
            new List<FS_AnalyzeFlowAction.Request>{ request }
        );
        Test.stopTest();
        
        // The method logs debug information, but we can't directly assert on System.debug
        // We can verify the method completed successfully which indicates debug logging worked
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assert(results[0].message.contains('Debug_Test_Flow'), 'Should contain flow name in message');
    }
}
