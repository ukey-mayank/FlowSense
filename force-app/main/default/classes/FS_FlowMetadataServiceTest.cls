/**
 * @description Test class for FS_FlowMetadataService
 * @author FlowSense
 * @version 1.0
 */
@IsTest
private class FS_FlowMetadataServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test data using the factory
        FS_TestDataFactory.createGlobalSettings();
        
        // Create Flow Run records for testing statistics
        List<FS_Flow_Run__c> flowRuns = new List<FS_Flow_Run__c>();
        
        // Recent successful runs
        for (Integer i = 0; i < 5; i++) {
            FS_Flow_Run__c run = new FS_Flow_Run__c(
                Flow_API_Name__c = 'Test_Successful_Flow',
                Interview_ID__c = 'test-success-' + i,
                Status__c = 'Success',
                Started_At__c = System.now().addDays(-i * 2),
                Completed_At__c = System.now().addDays(-i * 2).addMinutes(5),
                Duration_Ms__c = 5000,
                CPU_Time_Millis__c = 1000 + (i * 200),
                SOQL_Count__c = 5 + i,
                DML_Count__c = 3 + i,
                Heap_Size_Bytes__c = 1024 * 1024 * (1 + i)
            );
            flowRuns.add(run);
        }
        
        // Failed runs
        for (Integer i = 0; i < 3; i++) {
            FS_Flow_Run__c run = new FS_Flow_Run__c(
                Flow_API_Name__c = 'Test_Successful_Flow',
                Interview_ID__c = 'test-failed-' + i,
                Status__c = 'Failed',
                Started_At__c = System.now().addDays(-i * 3),
                Completed_At__c = System.now().addDays(-i * 3).addMinutes(2),
                Duration_Ms__c = 2000,
                CPU_Time_Millis__c = 3000 + (i * 500),
                SOQL_Count__c = 10 + i,
                DML_Count__c = 8 + i,
                Heap_Size_Bytes__c = 2 * 1024 * 1024 * (1 + i)
            );
            flowRuns.add(run);
        }
        
        // Old runs (older than 30 days) - should not be included in statistics
        for (Integer i = 0; i < 2; i++) {
            FS_Flow_Run__c run = new FS_Flow_Run__c(
                Flow_API_Name__c = 'Test_Successful_Flow',
                Interview_ID__c = 'test-old-' + i,
                Status__c = 'Success',
                Started_At__c = System.now().addDays(-35 - i),
                Completed_At__c = System.now().addDays(-35 - i).addMinutes(3),
                Duration_Ms__c = 3000,
                CPU_Time_Millis__c = 1500,
                SOQL_Count__c = 7,
                DML_Count__c = 5,
                Heap_Size_Bytes__c = 1024 * 1024
            );
            flowRuns.add(run);
        }
        
        // Different flow runs
        for (Integer i = 0; i < 3; i++) {
            FS_Flow_Run__c run = new FS_Flow_Run__c(
                Flow_API_Name__c = 'Test_Different_Flow',
                Interview_ID__c = 'test-different-' + i,
                Status__c = 'Success',
                Started_At__c = System.now().addDays(-i),
                Completed_At__c = System.now().addDays(-i).addMinutes(10),
                Duration_Ms__c = 10000,
                CPU_Time_Millis__c = 2000,
                SOQL_Count__c = 8,
                DML_Count__c = 6,
                Heap_Size_Bytes__c = 3 * 1024 * 1024
            );
            flowRuns.add(run);
        }
        
        insert flowRuns;
    }
    
    @IsTest
    static void testGetFlowMetadataExistingFlow() {
        // Use test data from @TestSetup - no need to create duplicate data
        String flowApiName = 'Test_Successful_Flow';
        
        // Debug: Check how many records we have
        List<FS_Flow_Run__c> testRuns = [SELECT Id, Flow_API_Name__c, Started_At__c, Status__c FROM FS_Flow_Run__c WHERE Flow_API_Name__c = :flowApiName];
        System.debug('Total test runs found: ' + testRuns.size());
        
        DateTime last30Days = System.now().addDays(-30);
        List<FS_Flow_Run__c> recentRuns = [SELECT Id FROM FS_Flow_Run__c WHERE Flow_API_Name__c = :flowApiName AND Started_At__c >= :last30Days];
        System.debug('Recent runs in last 30 days: ' + recentRuns.size());
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata(flowApiName, true);
        Test.stopTest();
        
        // Verify metadata structure
        System.assertNotEquals(null, metadata, 'Metadata should not be null');
        System.assertEquals(flowApiName, metadata.apiName, 'API name should match');
        
        // Verify statistics from test data
        System.assertEquals(8, metadata.totalExecutions, 'Should have 8 executions in last 30 days. Found: ' + metadata.totalExecutions);
        System.assertEquals(3, metadata.errorCount, 'Should have 3 failed executions. Found: ' + metadata.errorCount);
        System.assertNotEquals(null, metadata.avgCpuTime, 'Should have average CPU time');
        System.assertNotEquals(null, metadata.avgSoqlQueries, 'Should have average SOQL count');
        System.assertNotEquals(null, metadata.avgDmlStatements, 'Should have average DML count');
        System.assertNotEquals(null, metadata.avgHeapSize, 'Should have average heap size');
    }
    
    @IsTest
    static void testGetFlowMetadataNonExistentFlow() {
        String flowApiName = 'Non_Existent_Flow';
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata(flowApiName, false);
        Test.stopTest();
        
        // Verify non-existent flow handling
        System.assertNotEquals(null, metadata, 'Metadata should not be null');
        System.assertEquals(flowApiName, metadata.apiName, 'API name should match');
        System.assertEquals(false, metadata.exists, 'Should mark as not existing');
        System.assertNotEquals(null, metadata.errorMessage, 'Should have error message');
        System.assert(metadata.errorMessage.contains('Flow not found'), 'Error message should indicate flow not found');
        
        // Verify default statistics
        System.assertEquals(0, metadata.totalExecutions, 'Should have no executions');
        System.assertEquals(0, metadata.errorCount, 'Should have no errors');
        System.assertEquals(0, metadata.avgCpuTime, 'Should have zero average CPU time');
        System.assertEquals(0, metadata.avgSoqlQueries, 'Should have zero average SOQL count');
        System.assertEquals(0, metadata.avgDmlStatements, 'Should have zero average DML count');
        System.assertEquals(0, metadata.avgHeapSize, 'Should have zero average heap size');
    }
    
    @IsTest
    static void testGetFlowMetadataWithCache() {
        String flowApiName = 'Test_Successful_Flow';
        
        Test.startTest();
        // Test with cache enabled
        FS_FlowMetadataService.FlowMetadata metadataWithCache = FS_FlowMetadataService.getFlowMetadata(flowApiName, true);
        
        // Test with cache disabled
        FS_FlowMetadataService.FlowMetadata metadataWithoutCache = FS_FlowMetadataService.getFlowMetadata(flowApiName, false);
        Test.stopTest();
        
        // Both should return the same data (cache not implemented yet)
        System.assertEquals(metadataWithCache.apiName, metadataWithoutCache.apiName, 'API names should match');
        System.assertEquals(metadataWithCache.totalExecutions, metadataWithoutCache.totalExecutions, 'Executions should match');
        System.assertEquals(metadataWithCache.errorCount, metadataWithoutCache.errorCount, 'Error counts should match');
    }
    
    @IsTest
    static void testGetFlowMetadataStatisticsCalculation() {
        String flowApiName = 'Test_Successful_Flow';
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata(flowApiName, false);
        Test.stopTest();
        
        // Verify statistics calculations
        System.assertEquals(8, metadata.totalExecutions, 'Should count all recent executions');
        System.assertEquals(3, metadata.errorCount, 'Should count failed executions');
        
        // Verify averages are calculated (approximate ranges since we have 5 successful + 3 failed)
        System.assert(metadata.avgCpuTime >= 1000 && metadata.avgCpuTime <= 4000, 'Average CPU time should be in expected range');
        System.assert(metadata.avgSoqlQueries >= 5 && metadata.avgSoqlQueries <= 15, 'Average SOQL count should be in expected range');
        System.assert(metadata.avgDmlStatements >= 3 && metadata.avgDmlStatements <= 12, 'Average DML count should be in expected range');
        System.assert(metadata.avgHeapSize >= 1024*1024 && metadata.avgHeapSize <= 6*1024*1024, 'Average heap size should be in expected range');
    }
    
    @IsTest
    static void testGetFlowMetadataNoStatistics() {
        String flowApiName = 'Flow_With_No_Stats';
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata(flowApiName, false);
        Test.stopTest();
        
        // Should handle flows with no execution history
        System.assertNotEquals(null, metadata, 'Metadata should not be null');
        System.assertEquals(flowApiName, metadata.apiName, 'API name should match');
        System.assertEquals(0, metadata.totalExecutions, 'Should have no executions');
        System.assertEquals(0, metadata.errorCount, 'Should have no errors');
        System.assertEquals(0, metadata.avgCpuTime, 'Should have zero average CPU time');
        System.assertEquals(0, metadata.avgSoqlQueries, 'Should have zero average SOQL count');
        System.assertEquals(0, metadata.avgDmlStatements, 'Should have zero average DML count');
        System.assertEquals(0, metadata.avgHeapSize, 'Should have zero average heap size');
    }
    
    @IsTest
    static void testGetFlowMetadataDateFiltering() {
        String flowApiName = 'Test_Successful_Flow';
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata(flowApiName, false);
        Test.stopTest();
        
        // Should only include runs from last 30 days (8 runs), not the old ones (2 runs)
        System.assertEquals(8, metadata.totalExecutions, 'Should only count recent executions');
        
        // Old runs should not affect statistics
        System.assertNotEquals(10, metadata.totalExecutions, 'Should not include old executions');
    }
    
    @IsTest
    static void testGetFlowMetadataDifferentFlow() {
        String flowApiName = 'Test_Different_Flow';
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata(flowApiName, false);
        Test.stopTest();
        
        // Should get statistics for the different flow
        System.assertEquals(3, metadata.totalExecutions, 'Should have 3 executions for different flow');
        System.assertEquals(0, metadata.errorCount, 'Should have no errors for different flow');
        System.assertEquals(2000, metadata.avgCpuTime, 'Should have correct average CPU time');
        System.assertEquals(8, metadata.avgSoqlQueries, 'Should have correct average SOQL count');
        System.assertEquals(6, metadata.avgDmlStatements, 'Should have correct average DML count');
    }
    
    @IsTest
    static void testFlowMetadataClassStructure() {
        FS_FlowMetadataService.FlowMetadata metadata = new FS_FlowMetadataService.FlowMetadata();
        
        // Test default values
        System.assertEquals(false, metadata.exists, 'Should default to false');
        System.assertEquals(false, metadata.isActive, 'Should default to false');
        System.assertEquals(0, metadata.totalExecutions, 'Should default to 0');
        System.assertEquals(0, metadata.errorCount, 'Should default to 0');
        System.assertEquals(0, metadata.avgCpuTime, 'Should default to 0');
        System.assertEquals(0, metadata.avgSoqlQueries, 'Should default to 0');
        System.assertEquals(0, metadata.avgDmlStatements, 'Should default to 0');
        System.assertEquals(0, metadata.avgHeapSize, 'Should default to 0');
        System.assertEquals(0, metadata.complexityScore, 'Should default to 0');
        
        // Test property assignment
        metadata.apiName = 'Test_API_Name';
        metadata.label = 'Test Label';
        metadata.description = 'Test Description';
        metadata.exists = true;
        metadata.isActive = true;
        metadata.processType = 'Flow';
        metadata.triggerType = 'None';
        metadata.totalExecutions = 100;
        
        System.assertEquals('Test_API_Name', metadata.apiName, 'API name should be set');
        System.assertEquals('Test Label', metadata.label, 'Label should be set');
        System.assertEquals('Test Description', metadata.description, 'Description should be set');
        System.assertEquals(true, metadata.exists, 'Exists should be set');
        System.assertEquals(true, metadata.isActive, 'IsActive should be set');
        System.assertEquals('Flow', metadata.processType, 'ProcessType should be set');
        System.assertEquals('None', metadata.triggerType, 'TriggerType should be set');
        System.assertEquals(100, metadata.totalExecutions, 'TotalExecutions should be set');
    }
    
    @IsTest
    static void testFlowVersionClassStructure() {
        FS_FlowMetadataService.FlowVersion version = new FS_FlowMetadataService.FlowVersion();
        
        // Test property assignment
        version.versionNumber = 1;
        version.status = 'Active';
        version.lastModifiedDate = System.now();
        version.lastModifiedBy = 'Test User';
        version.description = 'Version 1 description';
        
        System.assertEquals(1, version.versionNumber, 'Version number should be set');
        System.assertEquals('Active', version.status, 'Status should be set');
        System.assertNotEquals(null, version.lastModifiedDate, 'Last modified date should be set');
        System.assertEquals('Test User', version.lastModifiedBy, 'Last modified by should be set');
        System.assertEquals('Version 1 description', version.description, 'Description should be set');
    }
    
    @IsTest
    static void testGetFlowMetadataExceptionHandling() {
        // Test with null flow name to potentially trigger exception
        String flowApiName = null;
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata(flowApiName, false);
        Test.stopTest();
        
        // Should handle exceptions gracefully
        System.assertNotEquals(null, metadata, 'Metadata should not be null');
        System.assertEquals(false, metadata.exists, 'Should mark as not existing');
        System.assertNotEquals(null, metadata.errorMessage, 'Should have error message');
    }
    
    @IsTest
    static void testGetFlowMetadataQueryExceptionHandling() {
        // Create a test scenario where statistics query might fail
        String flowApiName = 'Test_Query_Exception_Flow';
        
        // Delete all test data to potentially cause query issues
        delete [SELECT Id FROM FS_Flow_Run__c];
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata(flowApiName, false);
        Test.stopTest();
        
        // Should handle query exceptions gracefully
        System.assertNotEquals(null, metadata, 'Metadata should not be null');
        System.assertEquals(flowApiName, metadata.apiName, 'API name should be set');
        System.assertEquals(0, metadata.totalExecutions, 'Should have zero executions');
        System.assertEquals(0, metadata.errorCount, 'Should have zero errors');
    }
    
    @IsTest
    static void testGetFlowMetadataPartialStatistics() {
        // Create flow run with some null statistics
        FS_Flow_Run__c run = new FS_Flow_Run__c(
            Flow_API_Name__c = 'Test_Partial_Stats_Flow',
            Interview_ID__c = 'test-partial-stats',
            Status__c = 'Success',
            Started_At__c = System.now().addDays(-1),
            Completed_At__c = System.now().addDays(-1).addMinutes(5),
            Duration_Ms__c = 5000,
            CPU_Time_Millis__c = null, // Null CPU time
            SOQL_Count__c = 5,
            DML_Count__c = null, // Null DML count
            Heap_Size_Bytes__c = 1024 * 1024
        );
        insert run;
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata('Test_Partial_Stats_Flow', false);
        Test.stopTest();
        
        // Should handle partial statistics gracefully
        System.assertEquals(1, metadata.totalExecutions, 'Should have one execution');
        System.assertEquals(0, metadata.errorCount, 'Should have no errors');
        // Averages should handle null values correctly
        System.assertEquals(null, metadata.avgCpuTime, 'Should handle null CPU time');
        System.assertEquals(5, metadata.avgSoqlQueries, 'Should have correct SOQL average');
        System.assertEquals(null, metadata.avgDmlStatements, 'Should handle null DML count');
        System.assertEquals(1024 * 1024, metadata.avgHeapSize, 'Should have correct heap average');
    }
    
    @IsTest
    static void testGetFlowMetadataEmptyStringFlow() {
        String flowApiName = '';
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata(flowApiName, false);
        Test.stopTest();
        
        // Should handle empty string gracefully
        System.assertNotEquals(null, metadata, 'Metadata should not be null');
        System.assertEquals('', metadata.apiName, 'API name should be empty string');
        System.assertEquals(false, metadata.exists, 'Should mark as not existing');
        System.assertNotEquals(null, metadata.errorMessage, 'Should have error message');
    }
    
    @IsTest
    static void testGetFlowMetadataLongFlowName() {
        // Test with very long flow name
        String flowApiName = 'Very_Long_Flow_Name_That_Exceeds_Normal_Length_Limits_For_Testing_Purposes_And_Edge_Cases';
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata(flowApiName, false);
        Test.stopTest();
        
        // Should handle long names gracefully
        System.assertNotEquals(null, metadata, 'Metadata should not be null');
        System.assertEquals(flowApiName, metadata.apiName, 'API name should match');
        System.assertEquals(false, metadata.exists, 'Should mark as not existing');
        System.assertNotEquals(null, metadata.errorMessage, 'Should have error message');
    }
    
    @IsTest
    static void testGetFlowMetadataSpecialCharacters() {
        // Test with special characters in flow name
        String flowApiName = 'Test_Flow_With_Special_Characters_$@#';
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata(flowApiName, false);
        Test.stopTest();
        
        // Should handle special characters gracefully
        System.assertNotEquals(null, metadata, 'Metadata should not be null');
        System.assertEquals(flowApiName, metadata.apiName, 'API name should match');
        // Might exist or not depending on system, but should not crash
        System.assertNotEquals(null, metadata.exists, 'Exists should be set');
    }
    
    @IsTest
    static void testGetFlowMetadataPerformanceWithLargeDataset() {
        // Create a large number of flow runs to test performance
        List<FS_Flow_Run__c> largeDataset = new List<FS_Flow_Run__c>();
        
        for (Integer i = 0; i < 200; i++) {
            FS_Flow_Run__c run = new FS_Flow_Run__c(
                Flow_API_Name__c = 'Large_Dataset_Flow',
                Interview_ID__c = 'large-dataset-' + i,
                Status__c = Math.mod(i, 5) == 0 ? 'Failed' : 'Success',
                Started_At__c = System.now().addDays(-Math.mod(i, 25)),
                Completed_At__c = System.now().addDays(-Math.mod(i, 25)).addMinutes(3),
                Duration_Ms__c = 3000,
                CPU_Time_Millis__c = 1000 + Math.mod(i, 1000),
                SOQL_Count__c = 5 + Math.mod(i, 10),
                DML_Count__c = 3 + Math.mod(i, 5),
                Heap_Size_Bytes__c = 1024 * 1024 * (1 + Math.mod(i, 3))
            );
            largeDataset.add(run);
        }
        
        insert largeDataset;
        
        Test.startTest();
        FS_FlowMetadataService.FlowMetadata metadata = FS_FlowMetadataService.getFlowMetadata('Large_Dataset_Flow', false);
        Test.stopTest();
        
        // Should handle large dataset efficiently
        System.assertNotEquals(null, metadata, 'Metadata should not be null');
        System.assertEquals('Large_Dataset_Flow', metadata.apiName, 'API name should match');
        System.assertEquals(200, metadata.totalExecutions, 'Should count all executions');
        System.assert(metadata.errorCount > 0, 'Should have some failed executions');
        System.assertNotEquals(null, metadata.avgCpuTime, 'Should calculate average CPU time');
        System.assertNotEquals(null, metadata.avgSoqlQueries, 'Should calculate average SOQL count');
        System.assertNotEquals(null, metadata.avgDmlStatements, 'Should calculate average DML count');
        System.assertNotEquals(null, metadata.avgHeapSize, 'Should calculate average heap size');
    }
}
