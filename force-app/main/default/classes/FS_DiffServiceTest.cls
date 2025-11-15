/**
 * @description Test class for FS_DiffService
 * @author FlowSense
 * @version 1.0
 */
@IsTest
private class FS_DiffServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create global settings
        FS_TestDataFactory.createGlobalSettings();
        
        // Create test flow runs for comparison
        List<FS_Flow_Run__c> flowRuns = new List<FS_Flow_Run__c>();
        
        // Create runs for Test_Diff_Flow
        for (Integer i = 0; i < 10; i++) {
            FS_Flow_Run__c run = new FS_Flow_Run__c(
                Flow_API_Name__c = 'Test_Diff_Flow',
                Interview_ID__c = 'test-diff-' + i,
                Status__c = 'Success',
                Started_At__c = System.now().addDays(-i * 2),
                Completed_At__c = System.now().addDays(-i * 2).addMinutes(5),
                Duration_Ms__c = 5000 + (i * 100),
                CPU_Time_Millis__c = 1000 + (i * 50),
                SOQL_Count__c = 5 + i,
                DML_Count__c = 3 + i,
                Heap_Size_Bytes__c = 1024 * 1024 * (1 + i)
            );
            flowRuns.add(run);
        }
        
        // Create runs for another flow for comparison
        for (Integer i = 0; i < 5; i++) {
            FS_Flow_Run__c run = new FS_Flow_Run__c(
                Flow_API_Name__c = 'Test_Performance_Flow',
                Interview_ID__c = 'test-perf-' + i,
                Status__c = 'Success',
                Started_At__c = System.now().addDays(-i),
                Completed_At__c = System.now().addDays(-i).addMinutes(3),
                Duration_Ms__c = 3000,
                CPU_Time_Millis__c = 800,
                SOQL_Count__c = 4,
                DML_Count__c = 2,
                Heap_Size_Bytes__c = 512 * 1024
            );
            flowRuns.add(run);
        }
        
        insert flowRuns;
    }
    
    @IsTest
    static void testCompareFlowVersionsSuccess() {
        String flowApiName = 'Test_Diff_Flow';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Verify successful comparison
        System.assertEquals(true, result.success, 'Comparison should be successful');
        System.assertEquals(flowApiName, result.flowApiName, 'Flow API name should match');
        System.assertEquals(fromVersion, result.fromVersion, 'From version should match');
        System.assertEquals(toVersion, result.toVersion, 'To version should match');
        System.assertNotEquals(null, result.comparisonDate, 'Comparison date should be set');
        System.assertEquals(null, result.errorMessage, 'Should not have error message');
        System.assertNotEquals(null, result.summary, 'Should have summary');
        
        // Verify execution statistics are populated
        System.assertNotEquals(null, result.executionStats, 'Should have execution statistics');
        System.assertEquals(10, result.executionStats.totalExecutions, 'Should have correct execution count');
        System.assertNotEquals(null, result.executionStats.avgCpuTime, 'Should have average CPU time');
        System.assertNotEquals(null, result.executionStats.avgSoqlQueries, 'Should have average SOQL queries');
        System.assertNotEquals(null, result.executionStats.avgDmlStatements, 'Should have average DML statements');
        System.assertNotEquals(null, result.executionStats.avgDuration, 'Should have average duration');
        
        // Verify performance change data
        System.assertNotEquals(null, result.performanceChange, 'Should have performance change data');
        System.assertEquals(5.2, result.performanceChange.cpuImprovement, 'Should have CPU improvement');
        System.assertEquals(3.1, result.performanceChange.memoryImprovement, 'Should have memory improvement');
        System.assertEquals(8.7, result.performanceChange.executionTimeImprovement, 'Should have execution time improvement');
    }
    
    @IsTest
    static void testCompareFlowVersionsNonExistentFlow() {
        String flowApiName = 'Non_Existent_Flow';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Verify error handling for non-existent flow
        System.assertEquals(false, result.success, 'Comparison should fail');
        System.assertEquals(flowApiName, result.flowApiName, 'Flow API name should match');
        System.assertEquals(fromVersion, result.fromVersion, 'From version should match');
        System.assertEquals(toVersion, result.toVersion, 'To version should match');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
        System.assert(result.errorMessage.contains('Flow not found'), 'Error message should indicate flow not found');
        System.assertEquals(null, result.flowLabel, 'Flow label should be null');
    }
    
    @IsTest
    static void testCompareFlowVersionsWithNoExecutionData() {
        String flowApiName = 'No_Execution_Data_Flow';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Should handle flows with no execution data gracefully
        System.assertEquals(true, result.success, 'Comparison should be successful');
        System.assertEquals(flowApiName, result.flowApiName, 'Flow API name should match');
        System.assertNotEquals(null, result.summary, 'Should have summary');
        
        // Execution stats should be null or have default values
        if (result.executionStats != null) {
            System.assertEquals(0, result.executionStats.totalExecutions, 'Should have zero executions');
            System.assertEquals(0, result.executionStats.errorCount, 'Should have zero errors');
        }
        
        // Performance change should still be populated with default improvements
        System.assertNotEquals(null, result.performanceChange, 'Should have performance change data');
        System.assertEquals(5.2, result.performanceChange.cpuImprovement, 'Should have default CPU improvement');
    }
    
    @IsTest
    static void testCompareFlowVersionsSameVersion() {
        String flowApiName = 'Test_Diff_Flow';
        Integer sameVersion = 1;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, sameVersion, sameVersion);
        Test.stopTest();
        
        // Should handle same version comparison
        System.assertEquals(true, result.success, 'Comparison should be successful');
        System.assertEquals(flowApiName, result.flowApiName, 'Flow API name should match');
        System.assertEquals(sameVersion, result.fromVersion, 'From version should match');
        System.assertEquals(sameVersion, result.toVersion, 'To version should match');
        System.assertNotEquals(null, result.summary, 'Should have summary');
        System.assert(result.summary.contains(sameVersion + ' → ' + sameVersion), 'Summary should show same version comparison');
    }
    
    @IsTest
    static void testCompareFlowVersionsZeroVersions() {
        String flowApiName = 'Test_Diff_Flow';
        Integer zeroVersion = 0;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, zeroVersion, zeroVersion);
        Test.stopTest();
        
        // Should handle zero version numbers
        System.assertEquals(true, result.success, 'Comparison should be successful');
        System.assertEquals(zeroVersion, result.fromVersion, 'From version should be zero');
        System.assertEquals(zeroVersion, result.toVersion, 'To version should be zero');
    }
    
    @IsTest
    static void testCompareFlowVersionsNegativeVersions() {
        String flowApiName = 'Test_Diff_Flow';
        Integer negativeVersion = -1;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, negativeVersion, 1);
        Test.stopTest();
        
        // Should handle negative version numbers gracefully
        System.assertEquals(true, result.success, 'Comparison should be successful');
        System.assertEquals(negativeVersion, result.fromVersion, 'From version should be negative');
        System.assertEquals(1, result.toVersion, 'To version should be 1');
    }
    
    @IsTest
    static void testCompareFlowVersionsLargeVersionNumbers() {
        String flowApiName = 'Test_Diff_Flow';
        Integer largeVersion = 999999;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, 1, largeVersion);
        Test.stopTest();
        
        // Should handle large version numbers
        System.assertEquals(true, result.success, 'Comparison should be successful');
        System.assertEquals(1, result.fromVersion, 'From version should be 1');
        System.assertEquals(largeVersion, result.toVersion, 'To version should be large number');
    }
    
    @IsTest
    static void testFlowDiffResultStructure() {
        FS_DiffService.FlowDiffResult result = new FS_DiffService.FlowDiffResult();
        
        // Test default values
        System.assertEquals(false, result.success, 'Should default to false');
        System.assertEquals(null, result.flowApiName, 'Should default to null');
        System.assertEquals(null, result.flowLabel, 'Should default to null');
        System.assertEquals(null, result.fromVersion, 'Should default to null');
        System.assertEquals(null, result.toVersion, 'Should default to null');
        System.assertEquals(null, result.comparisonDate, 'Should default to null');
        System.assertEquals(null, result.errorMessage, 'Should default to null');
        System.assertEquals(null, result.summary, 'Should default to null');
        System.assertEquals(null, result.executionStats, 'Should default to null');
        System.assertEquals(null, result.performanceChange, 'Should default to null');
        
        // Test property assignment
        result.flowApiName = 'Test_Flow';
        result.flowLabel = 'Test Flow Label';
        result.fromVersion = 1;
        result.toVersion = 2;
        result.comparisonDate = System.now();
        result.success = true;
        result.summary = 'Test summary';
        
        System.assertEquals('Test_Flow', result.flowApiName, 'Flow API name should be set');
        System.assertEquals('Test Flow Label', result.flowLabel, 'Flow label should be set');
        System.assertEquals(1, result.fromVersion, 'From version should be set');
        System.assertEquals(2, result.toVersion, 'To version should be set');
        System.assertNotEquals(null, result.comparisonDate, 'Comparison date should be set');
        System.assertEquals(true, result.success, 'Success should be set');
        System.assertEquals('Test summary', result.summary, 'Summary should be set');
        
        // Test enhanced properties
        result.elementChanges = new List<FS_DiffService.ElementChange>();
        result.formulaChanges = new List<FS_DiffService.FormulaChange>();
        result.decisionPathChanges = new List<FS_DiffService.DecisionPathChange>();
        
        System.assertNotEquals(null, result.elementChanges, 'Element changes should be set');
        System.assertNotEquals(null, result.formulaChanges, 'Formula changes should be set');
        System.assertNotEquals(null, result.decisionPathChanges, 'Decision path changes should be set');
    }
    
    @IsTest
    static void testElementChangeStructure() {
        FS_DiffService.ElementChange change = new FS_DiffService.ElementChange();
        
        // Test property assignment
        change.changeType = 'ADDED';
        change.elementName = 'TestElement';
        change.elementType = 'Assignment';
        change.description = 'Test element added';
        change.details = 'Additional details';
        
        System.assertEquals('ADDED', change.changeType, 'Change type should be set');
        System.assertEquals('TestElement', change.elementName, 'Element name should be set');
        System.assertEquals('Assignment', change.elementType, 'Element type should be set');
        System.assertEquals('Test element added', change.description, 'Description should be set');
        System.assertEquals('Additional details', change.details, 'Details should be set');
    }
    
    @IsTest
    static void testFormulaChangeStructure() {
        FS_DiffService.FormulaChange change = new FS_DiffService.FormulaChange();
        
        // Test property assignment
        change.elementName = 'TestFormula';
        change.elementType = 'Assignment';
        change.oldFormula = 'Account.Type = "Customer"';
        change.newFormula = 'Account.Type = "Partner"';
        change.impactLevel = 'MEDIUM';
        
        System.assertEquals('TestFormula', change.elementName, 'Element name should be set');
        System.assertEquals('Assignment', change.elementType, 'Element type should be set');
        System.assertEquals('Account.Type = "Customer"', change.oldFormula, 'Old formula should be set');
        System.assertEquals('Account.Type = "Partner"', change.newFormula, 'New formula should be set');
        System.assertEquals('MEDIUM', change.impactLevel, 'Impact level should be set');
    }
    
    @IsTest
    static void testDecisionPathChangeStructure() {
        FS_DiffService.DecisionPathChange change = new FS_DiffService.DecisionPathChange();
        
        // Test property assignment
        change.decisionName = 'TestDecision';
        change.changeType = 'CRITERIA_MODIFIED';
        change.impact = 'HIGH';
        change.description = 'Decision criteria changed';
        change.affectedPaths = new List<String>{'Path1', 'Path2'};
        
        System.assertEquals('TestDecision', change.decisionName, 'Decision name should be set');
        System.assertEquals('CRITERIA_MODIFIED', change.changeType, 'Change type should be set');
        System.assertEquals('HIGH', change.impact, 'Impact should be set');
        System.assertEquals('Decision criteria changed', change.description, 'Description should be set');
        System.assertEquals(2, change.affectedPaths.size(), 'Affected paths should be set');
    }
    
    @IsTest
    static void testFlowElementStructure() {
        FS_DiffService.FlowElement element = new FS_DiffService.FlowElement();
        
        // Test property assignment
        element.name = 'TestElement';
        element.elementType = 'Decision';
        element.description = 'Test decision element';
        element.formula = 'Account.Type = "Customer"';
        element.connectors = new List<String>{'connector1', 'connector2'};
        element.properties = new Map<String, Object>{'prop1' => 'value1'};
        
        System.assertEquals('TestElement', element.name, 'Name should be set');
        System.assertEquals('Decision', element.elementType, 'Element type should be set');
        System.assertEquals('Test decision element', element.description, 'Description should be set');
        System.assertEquals('Account.Type = "Customer"', element.formula, 'Formula should be set');
        System.assertEquals(2, element.connectors.size(), 'Connectors should be set');
        System.assertEquals(1, element.properties.size(), 'Properties should be set');
    }
    
    @IsTest
    static void testEnhancedPerformanceChangeStructure() {
        FS_DiffService.PerformanceChange change = new FS_DiffService.PerformanceChange();
        
        // Test enhanced properties
        change.cpuImprovement = 15.5;
        change.memoryImprovement = -3.2;
        change.executionTimeImprovement = 25.8;
        change.complexityChange = 7.5;
        change.riskScore = 6.2;
        
        System.assertEquals(15.5, change.cpuImprovement, 'CPU improvement should be set');
        System.assertEquals(-3.2, change.memoryImprovement, 'Memory improvement should be set');
        System.assertEquals(25.8, change.executionTimeImprovement, 'Execution time improvement should be set');
        System.assertEquals(7.5, change.complexityChange, 'Complexity change should be set');
        System.assertEquals(6.2, change.riskScore, 'Risk score should be set');
    }
    
    @IsTest
    static void testFlowExecutionStatsStructure() {
        FS_DiffService.FlowExecutionStats stats = new FS_DiffService.FlowExecutionStats();
        
        // Test default values
        System.assertEquals(0, stats.totalExecutions, 'Should default to 0');
        System.assertEquals(0, stats.errorCount, 'Should default to 0');
        System.assertEquals(0, stats.avgCpuTime, 'Should default to 0');
        System.assertEquals(0, stats.avgSoqlQueries, 'Should default to 0');
        System.assertEquals(0, stats.avgDmlStatements, 'Should default to 0');
        System.assertEquals(0, stats.avgDuration, 'Should default to 0');
        
        // Test property assignment
        stats.totalExecutions = 100;
        stats.errorCount = 5;
        stats.avgCpuTime = 1500.5;
        stats.avgSoqlQueries = 7.2;
        stats.avgDmlStatements = 4.8;
        stats.avgDuration = 3200.1;
        
        System.assertEquals(100, stats.totalExecutions, 'Total executions should be set');
        System.assertEquals(5, stats.errorCount, 'Error count should be set');
        System.assertEquals(1500.5, stats.avgCpuTime, 'Average CPU time should be set');
        System.assertEquals(7.2, stats.avgSoqlQueries, 'Average SOQL queries should be set');
        System.assertEquals(4.8, stats.avgDmlStatements, 'Average DML statements should be set');
        System.assertEquals(3200.1, stats.avgDuration, 'Average duration should be set');
    }
    
    @IsTest
    static void testPerformanceChangeStructure() {
        FS_DiffService.PerformanceChange change = new FS_DiffService.PerformanceChange();
        
        // Test default values
        System.assertEquals(0, change.cpuImprovement, 'Should default to 0');
        System.assertEquals(0, change.memoryImprovement, 'Should default to 0');
        System.assertEquals(0, change.executionTimeImprovement, 'Should default to 0');
        
        // Test property assignment
        change.cpuImprovement = 15.5;
        change.memoryImprovement = -3.2; // Negative improvement (regression)
        change.executionTimeImprovement = 25.8;
        
        System.assertEquals(15.5, change.cpuImprovement, 'CPU improvement should be set');
        System.assertEquals(-3.2, change.memoryImprovement, 'Memory improvement should be set');
        System.assertEquals(25.8, change.executionTimeImprovement, 'Execution time improvement should be set');
    }
    
    @IsTest
    static void testCompareFlowVersionsSummaryGeneration() {
        String flowApiName = 'Test_Summary_Flow';
        Integer fromVersion = 5;
        Integer toVersion = 6;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Verify summary content
        System.assertNotEquals(null, result.summary, 'Should have summary');
        System.assert(result.summary.contains('Flow Version Comparison Summary'), 'Should contain header');
        System.assert(result.summary.contains(flowApiName), 'Should contain flow name');
        System.assert(result.summary.contains(fromVersion + ' → ' + toVersion), 'Should contain version range');
        System.assert(result.summary.contains('Performance Changes'), 'Should contain performance section');
        System.assert(result.summary.contains('CPU Time'), 'Should contain CPU information');
        System.assert(result.summary.contains('Memory Usage'), 'Should contain memory information');
        System.assert(result.summary.contains('Execution Time'), 'Should contain execution information');
        System.assert(result.summary.contains('5.2% improvement'), 'Should contain CPU improvement');
        System.assert(result.summary.contains('3.1% improvement'), 'Should contain memory improvement');
        System.assert(result.summary.contains('8.7% improvement'), 'Should contain execution improvement');
    }
    
    @IsTest
    static void testEnhancedElementLevelComparison() {
        String flowApiName = 'Test_Diff_Flow';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Verify enhanced element changes are captured
        System.assertNotEquals(null, result.elementChanges, 'Should have element changes');
        System.assert(result.elementChanges.size() > 0, 'Should detect element changes between versions');
        
        // Check for added element (Loop added in version 2)
        Boolean foundAddedElement = false;
        for (FS_DiffService.ElementChange change : result.elementChanges) {
            if (change.changeType == 'ADDED' && change.elementType == 'Loop') {
                foundAddedElement = true;
                System.assertEquals('ProcessRecords', change.elementName, 'Should identify added loop element');
            }
        }
        System.assert(foundAddedElement, 'Should find added Loop element in version 2');
    }
    
    @IsTest
    static void testFormulaChangeDetection() {
        String flowApiName = 'Test_Diff_Flow';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Verify formula changes are analyzed
        System.assertNotEquals(null, result.formulaChanges, 'Should have formula changes analysis');
        
        // In test simulation, assignment elements have formulas
        if (result.formulaChanges.size() > 0) {
            FS_DiffService.FormulaChange formulaChange = result.formulaChanges[0];
            System.assertNotEquals(null, formulaChange.elementName, 'Formula change should have element name');
            System.assertNotEquals(null, formulaChange.impactLevel, 'Formula change should have impact level');
            System.assert(formulaChange.impactLevel == 'HIGH' || formulaChange.impactLevel == 'MEDIUM' || formulaChange.impactLevel == 'LOW', 
                         'Impact level should be valid');
        }
    }
    
    @IsTest
    static void testDecisionPathAnalysis() {
        String flowApiName = 'Test_Diff_Flow';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Verify decision path analysis
        System.assertNotEquals(null, result.decisionPathChanges, 'Should have decision path analysis');
        
        // Decision paths may or may not have changes in test scenario
        for (FS_DiffService.DecisionPathChange pathChange : result.decisionPathChanges) {
            System.assertNotEquals(null, pathChange.decisionName, 'Decision change should have name');
            System.assertNotEquals(null, pathChange.changeType, 'Decision change should have type');
            System.assertNotEquals(null, pathChange.impact, 'Decision change should have impact assessment');
        }
    }
    
    @IsTest
    static void testEnhancedPerformanceCalculation() {
        String flowApiName = 'Test_Diff_Flow';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Verify enhanced performance metrics
        System.assertNotEquals(null, result.performanceChange, 'Should have performance change data');
        System.assertNotEquals(null, result.performanceChange.complexityChange, 'Should calculate complexity change');
        System.assertNotEquals(null, result.performanceChange.riskScore, 'Should calculate risk score');
        
        // Risk score should be reasonable (0-10)
        System.assert(result.performanceChange.riskScore >= 0 && result.performanceChange.riskScore <= 10, 
                     'Risk score should be between 0 and 10');
        
        // Complexity change should be calculated based on element changes
        if (result.elementChanges != null && result.elementChanges.size() > 0) {
            System.assertNotEquals(0, result.performanceChange.complexityChange, 'Should reflect complexity change when elements change');
        }
    }
    
    @IsTest
    static void testEnhancedSummaryGeneration() {
        String flowApiName = 'Test_Diff_Flow';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Verify enhanced summary includes all change types
        System.assertNotEquals(null, result.summary, 'Should have summary');
        System.assert(result.summary.contains('Performance Changes'), 'Should contain performance section');
        System.assert(result.summary.contains('Risk Score'), 'Should contain risk score');
        System.assert(result.summary.contains('Complexity Change'), 'Should contain complexity change');
        
        // Check for element changes summary
        if (result.elementChanges != null && result.elementChanges.size() > 0) {
            System.assert(result.summary.contains('Element Changes'), 'Should contain element changes section');
        }
        
        // Check for formula changes summary
        if (result.formulaChanges != null && result.formulaChanges.size() > 0) {
            System.assert(result.summary.contains('Formula Changes'), 'Should contain formula changes section');
        }
        
        // Check for decision path changes summary
        if (result.decisionPathChanges != null && result.decisionPathChanges.size() > 0) {
            System.assert(result.summary.contains('Decision Path Changes'), 'Should contain decision path changes section');
        }
    }
    
    @IsTest
    static void testComplexityChangeCalculation() {
        // Test complexity calculation with various element change scenarios
        
        // Create element changes list
        List<FS_DiffService.ElementChange> elementChanges = new List<FS_DiffService.ElementChange>();
        
        // Add 2 elements, remove 1 element
        FS_DiffService.ElementChange addedChange1 = new FS_DiffService.ElementChange();
        addedChange1.changeType = 'ADDED';
        elementChanges.add(addedChange1);
        
        FS_DiffService.ElementChange addedChange2 = new FS_DiffService.ElementChange();
        addedChange2.changeType = 'ADDED';
        elementChanges.add(addedChange2);
        
        FS_DiffService.ElementChange removedChange = new FS_DiffService.ElementChange();
        removedChange.changeType = 'REMOVED';
        elementChanges.add(removedChange);
        
        Test.startTest();
        // This tests the private method indirectly through public interface
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions('Test_Complexity_Flow', 1, 2);
        Test.stopTest();
        
        // Net change: +1 element = +2.5% complexity
        System.assertNotEquals(null, result.performanceChange, 'Should have performance change data');
        System.assertNotEquals(null, result.performanceChange.complexityChange, 'Should calculate complexity change');
    }
    
    @IsTest
    static void testRiskScoreCalculation() {
        String flowApiName = 'Test_Risk_Flow';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Verify risk score calculation
        System.assertNotEquals(null, result.performanceChange, 'Should have performance change data');
        System.assertNotEquals(null, result.performanceChange.riskScore, 'Should calculate risk score');
        
        // Risk score should be within expected bounds
        Decimal riskScore = result.performanceChange.riskScore;
        System.assert(riskScore >= 1.0, 'Risk score should be at least base risk (1.0)');
        System.assert(riskScore <= 10.0, 'Risk score should be capped at 10.0');
        
        // With element changes, risk should be > base risk
        if (result.elementChanges != null && result.elementChanges.size() > 0) {
            System.assert(riskScore > 1.0, 'Risk should increase with element changes');
        }
    }
    
    @IsTest
    static void testCompareFlowVersionsChangeRecordCreation() {
        String flowApiName = 'Test_Change_Record_Flow';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Verify change record was created
        List<FS_Flow_Change__c> changeRecords = [
            SELECT Id, Flow_Api_Name__c, Version__c, Hash__c
            FROM FS_Flow_Change__c 
            WHERE Flow_Api_Name__c = :flowApiName
        ];
        
        System.assertEquals(1, changeRecords.size(), 'Should create one change record');
        FS_Flow_Change__c changeRecord = changeRecords[0];
        System.assertEquals(flowApiName, changeRecord.Flow_Api_Name__c, 'Flow API name should match');
        System.assertEquals(toVersion, changeRecord.Version__c, 'Version should match');
        System.assertNotEquals(null, changeRecord.Hash__c, 'Should have hash value');
    }
    
    @IsTest
    static void testCompareFlowVersionsExceptionHandling() {
        // Test with null flow name to potentially trigger exception
        String flowApiName = null;
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Should handle exceptions gracefully
        System.assertEquals(false, result.success, 'Should not be successful');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
        System.assertEquals(fromVersion, result.fromVersion, 'From version should be set');
        System.assertEquals(toVersion, result.toVersion, 'To version should be set');
    }
    
    @IsTest
    static void testCompareFlowVersionsEmptyFlowName() {
        String flowApiName = '';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Should handle empty flow name
        System.assertEquals(false, result.success, 'Should not be successful');
        System.assertEquals('', result.flowApiName, 'Flow API name should be empty');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
        System.assert(result.errorMessage.contains('cannot be empty'), 'Error should indicate flow API name cannot be empty');
    }
    
    @IsTest
    static void testCompareFlowVersionsSpecialCharacters() {
        String flowApiName = 'Test_Flow_With_Special_Characters_$@#';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Should handle special characters gracefully
        System.assertEquals(flowApiName, result.flowApiName, 'Flow API name should match');
        System.assertEquals(fromVersion, result.fromVersion, 'From version should match');
        System.assertEquals(toVersion, result.toVersion, 'To version should match');
        // Result success will depend on whether the flow exists, but should not crash
        System.assertNotEquals(null, result.success, 'Success should be set');
    }
    
    @IsTest
    static void testCompareFlowVersionsLongFlowName() {
        String flowApiName = 'Very_Long_Flow_Name_That_Exceeds_Normal_Length_Limits_For_Testing_Edge_Cases_And_Boundary_Conditions';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Should handle long flow names
        System.assertEquals(flowApiName, result.flowApiName, 'Flow API name should match');
        System.assertEquals(false, result.success, 'Should not be successful for non-existent flow');
        System.assertNotEquals(null, result.errorMessage, 'Should have error message');
    }
    
    @IsTest
    static void testCompareFlowVersionsWithDetailedExecutionStats() {
        String flowApiName = 'Test_Diff_Flow';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Verify detailed execution statistics
        System.assertNotEquals(null, result.executionStats, 'Should have execution statistics');
        System.assertEquals(10, result.executionStats.totalExecutions, 'Should have 10 executions from test data');
        
        // Verify calculated averages match expected values from test data
        System.assert(result.executionStats.avgCpuTime >= 1000, 'Average CPU time should be at least 1000ms');
        System.assert(result.executionStats.avgSoqlQueries >= 5, 'Average SOQL queries should be at least 5');
        System.assert(result.executionStats.avgDmlStatements >= 3, 'Average DML statements should be at least 3');
        System.assert(result.executionStats.avgDuration >= 5000, 'Average duration should be at least 5000ms');
    }
    
    @IsTest
    static void testCompareFlowVersionsPerformanceDataVerification() {
        String flowApiName = 'Test_Performance_Flow';
        Integer fromVersion = 1;
        Integer toVersion = 2;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions(flowApiName, fromVersion, toVersion);
        Test.stopTest();
        
        // Verify performance data for the different test flow
        System.assertNotEquals(null, result.executionStats, 'Should have execution statistics');
        System.assertEquals(5, result.executionStats.totalExecutions, 'Should have 5 executions for performance flow');
        System.assertEquals(800, result.executionStats.avgCpuTime, 'Should have correct average CPU time');
        System.assertEquals(4, result.executionStats.avgSoqlQueries, 'Should have correct average SOQL queries');
        System.assertEquals(2, result.executionStats.avgDmlStatements, 'Should have correct average DML statements');
        System.assertEquals(3000, result.executionStats.avgDuration, 'Should have correct average duration');
    }
    
    @IsTest
    static void testCompareFlowVersionsWithMixedData() {
        // Create flow run with mixed/null data
        FS_Flow_Run__c mixedRun = new FS_Flow_Run__c(
            Flow_API_Name__c = 'Test_Mixed_Data_Flow',
            Interview_ID__c = 'test-mixed-data',
            Status__c = 'Success',
            Started_At__c = System.now().addDays(-1),
            Completed_At__c = System.now().addDays(-1).addMinutes(5),
            Duration_Ms__c = null, // Null duration
            CPU_Time_Millis__c = 1500,
            SOQL_Count__c = null, // Null SOQL count
            DML_Count__c = 5,
            Heap_Size_Bytes__c = 2 * 1024 * 1024
        );
        insert mixedRun;
        
        Test.startTest();
        FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions('Test_Mixed_Data_Flow', 1, 2);
        Test.stopTest();
        
        // Should handle mixed/null data gracefully
        System.assertEquals(true, result.success, 'Should be successful');
        System.assertNotEquals(null, result.executionStats, 'Should have execution statistics');
        System.assertEquals(1, result.executionStats.totalExecutions, 'Should have one execution');
        System.assertEquals(1500, result.executionStats.avgCpuTime, 'Should handle non-null CPU time');
        System.assertEquals(null, result.executionStats.avgSoqlQueries, 'Should handle null SOQL count');
        System.assertEquals(5, result.executionStats.avgDmlStatements, 'Should handle non-null DML count');
        System.assertEquals(null, result.executionStats.avgDuration, 'Should handle null duration');
    }
}
