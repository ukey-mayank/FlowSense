// Debug exact test scenario
System.debug('=== Starting Test Scenario Debug ===');

// Create flow run exactly like test
FS_Flow_Run__c flowRun = FS_LoggingService.logFlowStart('Test_Bulk_Steps_Flow', 'test-bulk-steps-123', UserInfo.getUserId(), 'Test Bulk Steps Flow');
System.debug('Flow Run Created: ' + flowRun);

// Create multiple step data exactly like test
List<FS_LoggingService.FlowStepData> stepDataList = new List<FS_LoggingService.FlowStepData>();

for (Integer i = 1; i <= 5; i++) {
    FS_LoggingService.FlowStepData stepData = new FS_LoggingService.FlowStepData();
    stepData.sequenceNumber = i;
    stepData.elementDeveloperName = 'Test_Element_' + i;
    stepData.elementLabel = 'Test Element ' + i;
    stepData.elementType = i == 1 ? 'Start' : (i == 5 ? 'End' : 'Assignment');
    stepData.enteredAt = System.now().addSeconds(-10 + i);
    stepData.exitedAt = System.now().addSeconds(-5 + i);
    stepData.durationMillis = 1000 + (i * 100);
    stepData.cpuMillis = 50 + (i * 10);
    stepData.soqlCount = i <= 3 ? i : 0;
    stepData.dmlCount = i == 2 || i == 4 ? 1 : 0;
    stepData.outcome = 'Success';
    stepDataList.add(stepData);
}

System.debug('Step Data List Size: ' + stepDataList.size());
System.debug('Step Data Sample: ' + stepDataList[0]);

// Log the steps
FS_LoggingService.logFlowSteps(flowRun.Id, stepDataList);

// Check results
List<FS_Flow_Step__c> steps = [
    SELECT Id, Sequence__c, Element_DeveloperName__c, Element_Type__c
    FROM FS_Flow_Step__c 
    WHERE Flow_Run__c = :flowRun.Id
    ORDER BY Sequence__c
];

System.debug('Steps Created: ' + steps.size());
System.debug('Steps: ' + steps);

// Also check if there are any steps at all in the system
List<FS_Flow_Step__c> allSteps = [SELECT Id, Flow_Run__c FROM FS_Flow_Step__c LIMIT 10];
System.debug('Total steps in system: ' + allSteps.size());