// Create minimal demo data for Performance Heatmap testing
System.debug('=== Creating Minimal Demo Data ===');

// Create some flow runs with only essential fields
List<FS_Flow_Run__c> testRuns = new List<FS_Flow_Run__c>();

String[] flowNames = new String[]{
    'Fast_Demo_Flow',
    'Medium_Demo_Flow', 
    'Slow_Demo_Flow',
    'Critical_Demo_Flow'
};

for (Integer f = 0; f < flowNames.size(); f++) {
    for (Integer i = 0; i < 3; i++) {
        FS_Flow_Run__c run = new FS_Flow_Run__c();
        run.Flow_API_Name__c = flowNames[f];
        run.Interview_Id__c = flowNames[f] + '_' + i;
        run.Status__c = 'Success';
        run.Started_At__c = System.now().addHours(-f * 2 - i);
        
        // Set performance characteristics based on flow type
        if (f == 0) { // Fast
            run.Duration_Millis__c = 500 + i * 100;
            run.CPU_Time_Millis__c = 200 + i * 50;
        } else if (f == 1) { // Medium
            run.Duration_Millis__c = 3000 + i * 300;
            run.CPU_Time_Millis__c = 1200 + i * 150;
        } else if (f == 2) { // Slow
            run.Duration_Millis__c = 8000 + i * 800;
            run.CPU_Time_Millis__c = 3200 + i * 400;
        } else { // Critical
            run.Duration_Millis__c = 35000 + i * 3000;
            run.CPU_Time_Millis__c = 15000 + i * 1500;
        }
        
        run.SOQL_Count__c = (f + 1) * 3 + i;
        run.DML_Count__c = (f + 1) * 2 + i;
        
        testRuns.add(run);
    }
}

insert testRuns;
System.debug('Created ' + testRuns.size() + ' test flow runs');

// Test the performance query again
Map<String, Object> result = FS_FlowStepSelector.getFlowPerformanceData(7, 'all', '');
System.debug('Performance query result:');
System.debug('Flow data count: ' + ((List<Object>)result.get('flowData')).size());
System.debug('Critical: ' + result.get('criticalFlows'));
System.debug('Warning: ' + result.get('warningFlows'));
System.debug('Healthy: ' + result.get('healthyFlows'));

System.debug('=== Demo Data Creation Complete ===');