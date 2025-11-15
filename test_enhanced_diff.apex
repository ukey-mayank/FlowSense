// Test Enhanced Flow Version Comparison
System.debug('=== Testing Enhanced Flow Diff Functionality ===');

// Test the enhanced comparison
FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions('Test_Diff_Flow', 1, 2);

System.debug('=== Basic Comparison Results ===');
System.debug('Success: ' + result.success);
System.debug('Flow: ' + result.flowApiName + ' (v' + result.fromVersion + ' → v' + result.toVersion + ')');

System.debug('=== Performance Changes ===');
if (result.performanceChange != null) {
    System.debug('CPU Improvement: ' + result.performanceChange.cpuImprovement + '%');
    System.debug('Memory Improvement: ' + result.performanceChange.memoryImprovement + '%');
    System.debug('Execution Time Improvement: ' + result.performanceChange.executionTimeImprovement + '%');
    System.debug('Complexity Change: ' + result.performanceChange.complexityChange + '%');
    System.debug('Risk Score: ' + result.performanceChange.riskScore + '/10');
}

System.debug('=== Element Changes ===');
if (result.elementChanges != null) {
    System.debug('Total Element Changes: ' + result.elementChanges.size());
    for (FS_DiffService.ElementChange change : result.elementChanges) {
        System.debug('- ' + change.changeType + ': ' + change.elementType + ' "' + change.elementName + '"');
        System.debug('  Description: ' + change.description);
    }
}

System.debug('=== Formula Changes ===');
if (result.formulaChanges != null && result.formulaChanges.size() > 0) {
    System.debug('Total Formula Changes: ' + result.formulaChanges.size());
    for (FS_DiffService.FormulaChange change : result.formulaChanges) {
        System.debug('- Element: ' + change.elementName + ' (Impact: ' + change.impactLevel + ')');
        System.debug('  Old: ' + change.oldFormula);
        System.debug('  New: ' + change.newFormula);
    }
} else {
    System.debug('No formula changes detected');
}

System.debug('=== Decision Path Changes ===');
if (result.decisionPathChanges != null && result.decisionPathChanges.size() > 0) {
    System.debug('Total Decision Changes: ' + result.decisionPathChanges.size());
    for (FS_DiffService.DecisionPathChange change : result.decisionPathChanges) {
        System.debug('- ' + change.changeType + ': ' + change.decisionName + ' (Impact: ' + change.impact + ')');
        System.debug('  Description: ' + change.description);
    }
} else {
    System.debug('No decision path changes detected');
}

System.debug('=== Full Summary ===');
System.debug(result.summary);