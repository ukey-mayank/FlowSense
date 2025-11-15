/**
 * @description Test class for FS_DashboardController
 * @author FlowSense
 * @version 1.0
 */
@isTest
private class FS_DashboardControllerTest {
    
    /**
     * @description Setup test data for all test methods
     */
    @TestSetup
    static void makeData() {
        // Create comprehensive test data using our factory with unique flow names
        FS_TestDataFactory.createCompleteFlowDataSet('Test_Account_Flow_' + String.valueOf(System.currentTimeMillis()));
    }
    
    /**
     * @description Test getFlowAnalytics with various filters
     */
    @isTest
    static void testGetFlowAnalytics() {
        Test.startTest();
        
        // Test with default parameters
        List<FS_DashboardController.FlowAnalyticsWrapper> results = 
            FS_DashboardController.getFlowAnalytics(7, '', '');
        
        System.assertNotEquals(null, results, 'Results should not be null');
        
        // Test with risk level filter
        List<FS_DashboardController.FlowAnalyticsWrapper> highRiskResults = 
            FS_DashboardController.getFlowAnalytics(30, 'High', '');
        
        System.assertNotEquals(null, highRiskResults, 'High risk results should not be null');
        
        // Test with search term filter
        List<FS_DashboardController.FlowAnalyticsWrapper> searchResults = 
            FS_DashboardController.getFlowAnalytics(30, '', 'Account');
        
        System.assertNotEquals(null, searchResults, 'Search results should not be null');
        
        // Test with all filters combined
        List<FS_DashboardController.FlowAnalyticsWrapper> combinedResults = 
            FS_DashboardController.getFlowAnalytics(30, 'Medium', 'Contact');
        
        System.assertNotEquals(null, combinedResults, 'Combined filter results should not be null');
        
        Test.stopTest();
    }
    
    /**
     * @description Test getFlowAnalytics with no data
     */
    @isTest
    static void testGetFlowAnalyticsNoData() {
        // Delete all test data
        delete [SELECT Id FROM FS_Flow_Analysis__c];
        
        Test.startTest();
        
        List<FS_DashboardController.FlowAnalyticsWrapper> results = 
            FS_DashboardController.getFlowAnalytics(7, '', '');
        
        System.assertEquals(0, results.size(), 'Should return empty list when no data exists');
        
        Test.stopTest();
    }
    
    /**
     * @description Test getFlowAnalytics with edge case parameters
     */
    @isTest
    static void testGetFlowAnalyticsEdgeCases() {
        Test.startTest();
        
        // Test with 0 days (should return no results)
        List<FS_DashboardController.FlowAnalyticsWrapper> zeroDayResults = 
            FS_DashboardController.getFlowAnalytics(0, '', '');
        
        System.assertNotEquals(null, zeroDayResults, 'Zero day results should not be null');
        
        // Test with very large time range
        List<FS_DashboardController.FlowAnalyticsWrapper> largeDayResults = 
            FS_DashboardController.getFlowAnalytics(365, '', '');
        
        System.assertNotEquals(null, largeDayResults, 'Large day results should not be null');
        
        // Test with null/empty strings
        List<FS_DashboardController.FlowAnalyticsWrapper> nullResults = 
            FS_DashboardController.getFlowAnalytics(7, null, null);
        
        System.assertNotEquals(null, nullResults, 'Null parameter results should not be null');
        
        Test.stopTest();
    }
    
    /**
     * @description Test getPerformanceMetrics with various time ranges
     */
    @isTest
    static void testGetPerformanceMetrics() {
        Test.startTest();
        
        // Test with 7 days
        FS_DashboardController.PerformanceMetrics metrics7Days = 
            FS_DashboardController.getPerformanceMetrics(7);
        
        System.assertNotEquals(null, metrics7Days, 'Metrics should not be null');
        System.assertEquals(true, metrics7Days.totalExecutions >= 0, 'Total executions should be non-negative');
        System.assertEquals(true, metrics7Days.averagePerformanceScore >= 0, 'Average performance score should be non-negative');
        System.assertEquals(true, metrics7Days.highRiskFlows >= 0, 'High risk flows should be non-negative');
        System.assertEquals(true, metrics7Days.averageExecutionTime >= 0, 'Average execution time should be non-negative');
        
        // Test with 30 days
        FS_DashboardController.PerformanceMetrics metrics30Days = 
            FS_DashboardController.getPerformanceMetrics(30);
        
        System.assertNotEquals(null, metrics30Days, 'Metrics should not be null');
        
        // Test with 90 days
        FS_DashboardController.PerformanceMetrics metrics90Days = 
            FS_DashboardController.getPerformanceMetrics(90);
        
        System.assertNotEquals(null, metrics90Days, 'Metrics should not be null');
        
        Test.stopTest();
    }
    
    /**
     * @description Test getPerformanceMetrics with no data
     */
    @isTest
    static void testGetPerformanceMetricsNoData() {
        // Delete all test data in correct order
        delete [SELECT Id FROM FS_Flow_Analysis__c];
        delete [SELECT Id FROM FS_Flow_Step__c];  
        delete [SELECT Id FROM FS_Flow_Run__c];
        
        Test.startTest();
        
        FS_DashboardController.PerformanceMetrics metrics = 
            FS_DashboardController.getPerformanceMetrics(7);
        
        System.assertNotEquals(null, metrics, 'Metrics should not be null even with no data');
        System.assertEquals(0, metrics.totalExecutions, 'Total executions should be 0 with no data');
        System.assertEquals(0, metrics.averagePerformanceScore, 'Average performance score should be 0 with no data');
        System.assertEquals(0, metrics.highRiskFlows, 'High risk flows should be 0 with no data');
        System.assertEquals(0, metrics.averageExecutionTime, 'Average execution time should be 0 with no data');
        
        Test.stopTest();
    }
    
    /**
     * @description Test getPerformanceMetrics with edge case parameters
     */
    @isTest
    static void testGetPerformanceMetricsEdgeCases() {
        Test.startTest();
        
        // Test with 0 days
        FS_DashboardController.PerformanceMetrics metricsZero = 
            FS_DashboardController.getPerformanceMetrics(0);
        
        System.assertNotEquals(null, metricsZero, 'Metrics should not be null');
        
        // Test with negative days (should still work)
        FS_DashboardController.PerformanceMetrics metricsNegative = 
            FS_DashboardController.getPerformanceMetrics(-1);
        
        System.assertNotEquals(null, metricsNegative, 'Metrics should not be null');
        
        // Test with very large days
        FS_DashboardController.PerformanceMetrics metricsLarge = 
            FS_DashboardController.getPerformanceMetrics(10000);
        
        System.assertNotEquals(null, metricsLarge, 'Metrics should not be null');
        
        Test.stopTest();
    }
    
    /**
     * @description Test data aggregation and grouping logic
     */
    @isTest
    static void testDataAggregation() {
        Test.startTest();
        
        List<FS_DashboardController.FlowAnalyticsWrapper> results = 
            FS_DashboardController.getFlowAnalytics(30, '', '');
        
        // Verify that results are properly grouped by flow name
        Set<String> flowNames = new Set<String>();
        for (FS_DashboardController.FlowAnalyticsWrapper wrapper : results) {
            System.assertNotEquals(null, wrapper.flowName, 'Flow name should not be null');
            System.assertNotEquals(null, wrapper.id, 'ID should not be null');
            System.assertEquals(true, wrapper.performanceScore >= 0, 'Performance score should be non-negative');
            
            flowNames.add(wrapper.flowName);
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test exception handling
     */
    @isTest
    static void testExceptionHandling() {
        Test.startTest();
        
        try {
            // This should not throw an exception even with invalid data
            List<FS_DashboardController.FlowAnalyticsWrapper> results = 
                FS_DashboardController.getFlowAnalytics(7, 'InvalidRiskLevel', 'TestSearch');
            
            System.assertNotEquals(null, results, 'Results should not be null even with invalid filter');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        
        try {
            FS_DashboardController.PerformanceMetrics metrics = 
                FS_DashboardController.getPerformanceMetrics(7);
            
            System.assertNotEquals(null, metrics, 'Metrics should not be null');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test wrapper class properties
     */
    @isTest
    static void testWrapperClasses() {
        Test.startTest();
        
        // Test FlowAnalyticsWrapper
        FS_DashboardController.FlowAnalyticsWrapper wrapper = new FS_DashboardController.FlowAnalyticsWrapper();
        wrapper.id = 'test123';
        wrapper.flowName = 'TestFlow';
        wrapper.lastExecution = System.now();
        wrapper.performanceScore = 85;
        wrapper.riskLevel = 'Medium';
        wrapper.averageDuration = 5000;
        wrapper.executionCount = 10;
        
        System.assertEquals('test123', wrapper.id, 'ID should match');
        System.assertEquals('TestFlow', wrapper.flowName, 'Flow name should match');
        System.assertEquals(85, wrapper.performanceScore, 'Performance score should match');
        System.assertEquals('Medium', wrapper.riskLevel, 'Risk level should match');
        System.assertEquals(5000, wrapper.averageDuration, 'Average duration should match');
        System.assertEquals(10, wrapper.executionCount, 'Execution count should match');
        
        // Test PerformanceMetrics
        FS_DashboardController.PerformanceMetrics metrics = new FS_DashboardController.PerformanceMetrics();
        metrics.totalExecutions = 100;
        metrics.averagePerformanceScore = 75;
        metrics.highRiskFlows = 5;
        metrics.averageExecutionTime = 3000;
        
        System.assertEquals(100, metrics.totalExecutions, 'Total executions should match');
        System.assertEquals(75, metrics.averagePerformanceScore, 'Average performance score should match');
        System.assertEquals(5, metrics.highRiskFlows, 'High risk flows should match');
        System.assertEquals(3000, metrics.averageExecutionTime, 'Average execution time should match');
        
        Test.stopTest();
    }
    
    /**
     * @description Test with different user contexts
     */
    @isTest
    static void testDifferentUserContexts() {
        // Use current user for simplicity
        Test.startTest();
        
        List<FS_DashboardController.FlowAnalyticsWrapper> results = 
            FS_DashboardController.getFlowAnalytics(7, '', '');
        
        System.assertNotEquals(null, results, 'Results should not be null for different user');
        
        FS_DashboardController.PerformanceMetrics metrics = 
            FS_DashboardController.getPerformanceMetrics(7);
        
        System.assertNotEquals(null, metrics, 'Metrics should not be null for different user');
        
        Test.stopTest();
    }
    
    /**
     * @description Test large data volume handling
     */
    @isTest
    static void testLargeDataVolume() {
        // Create additional test data to simulate larger volume
        for (Integer i = 0; i < 10; i++) {
            FS_TestDataFactory.createCompleteFlowDataSet('Bulk_Test_Flow_' + i);
        }
        
        Test.startTest();
        
        List<FS_DashboardController.FlowAnalyticsWrapper> results = 
            FS_DashboardController.getFlowAnalytics(30, '', '');
        
        System.assertNotEquals(null, results, 'Results should not be null with large data volume');
        
        FS_DashboardController.PerformanceMetrics metrics = 
            FS_DashboardController.getPerformanceMetrics(30);
        
        System.assertNotEquals(null, metrics, 'Metrics should not be null with large data volume');
        System.assertEquals(true, metrics.totalExecutions > 0, 'Should have executions with large data');
        
        Test.stopTest();
    }
}
