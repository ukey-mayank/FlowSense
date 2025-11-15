// Debug the testLogFlowStepsSuccess issue
FS_Flow_Run__c flowRun = FS_LoggingService.logFlowStart('Debug_Steps_Flow', 'debug-steps-123', UserInfo.getUserId(), 'Debug Steps Flow');
System.debug('Flow Run Created: ' + flowRun);
System.debug('Flow Run ID: ' + flowRun.Id);

// Create step data
FS_LoggingService.FlowStepData stepData = new FS_LoggingService.FlowStepData();
stepData.sequenceNumber = 1;
stepData.elementDeveloperName = 'Debug_Element_1';
stepData.elementType = 'Start';

List<FS_LoggingService.FlowStepData> stepDataList = new List<FS_LoggingService.FlowStepData>();
stepDataList.add(stepData);

System.debug('Step Data List: ' + stepDataList);
FS_LoggingService.logFlowSteps(flowRun.Id, stepDataList);

List<FS_Flow_Step__c> steps = [SELECT Id FROM FS_Flow_Step__c WHERE Flow_Run__c = :flowRun.Id];
System.debug('Steps Created: ' + steps.size());
System.debug('Steps: ' + steps);