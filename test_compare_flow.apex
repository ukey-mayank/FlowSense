// Test the compareFlowVersions method with the real flow from the UI
FS_DiffService.FlowDiffResult result = FS_DiffService.compareFlowVersions('Sample_Account_Processing_Flow', 4, 5);
System.debug('Result success: ' + result.success);
System.debug('Result error: ' + result.errorMessage);
System.debug('Result summary: ' + result.summary);

if (result.success) {
    System.debug('Performance Change: ' + result.performanceChange);
    System.debug('Element Changes: ' + result.elementChanges);
    System.debug('Formula Changes: ' + result.formulaChanges);
}