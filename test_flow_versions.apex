// Test the enhanced getFlowVersions method with the multi-version flow
List<Integer> versions = FS_DiffService.getFlowVersions('Sample_Account_Processing_Flow');
System.debug('Versions for Sample_Account_Processing_Flow: ' + versions);

// Test with a single-version flow  
List<Integer> singleVersions = FS_DiffService.getFlowVersions('FlowSense_Demo_Flow');
System.debug('Versions for FlowSense_Demo_Flow: ' + singleVersions);