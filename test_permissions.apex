// Simple test to verify Performance Heatmap permissions
System.debug('=== Testing Performance Heatmap Permissions ===');

// Test the Performance Heatmap query directly
try {
    Map<String, Object> result = FS_FlowStepSelector.getFlowPerformanceData(7, 'all', '');
    System.debug('✅ Performance data query successful!');
    System.debug('Result keys: ' + result.keySet());
    System.debug('Flow data count: ' + ((List<Object>)result.get('flowData')).size());
    System.debug('Critical flows: ' + result.get('criticalFlows'));
    System.debug('Warning flows: ' + result.get('warningFlows'));
    System.debug('Healthy flows: ' + result.get('healthyFlows'));
} catch (Exception e) {
    System.debug('❌ Performance data query failed: ' + e.getMessage());
    System.debug('Exception type: ' + e.getTypeName());
}

// Check if we have any existing data
List<FS_Flow_Run__c> existingRuns = [SELECT Id, Flow_API_Name__c FROM FS_Flow_Run__c LIMIT 5];
System.debug('Existing Flow Runs: ' + existingRuns.size());

List<FS_Flow_Step__c> existingSteps = [SELECT Id FROM FS_Flow_Step__c LIMIT 5];
System.debug('Existing Flow Steps: ' + existingSteps.size());

System.debug('=== Test Complete ===');