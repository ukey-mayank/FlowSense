// Create demo data for Performance Heatmap testing
System.debug('=== Creating Performance Heatmap Demo Data ===');

List<String> flowNames = new List<String>{
    'Account_Creation_Flow',
    'Lead_Qualification_Flow', 
    'Opportunity_Pipeline_Flow',
    'Contact_Enrichment_Flow',
    'Case_Resolution_Flow',
    'Email_Campaign_Flow',
    'Data_Validation_Flow',
    'Report_Generation_Flow',
    'Approval_Process_Flow',
    'Integration_Sync_Flow'
};

// Create comprehensive test data sets for each flow
for (String flowName : flowNames) {
    try {
        System.debug('Creating test data for: ' + flowName);
        
        // Create complete data set using the factory
        Map<String, List<SObject>> testData = FS_TestDataFactory.createCompleteFlowDataSet(flowName);
        
        System.debug('Created data for ' + flowName + ':');
        for (String objectType : testData.keySet()) {
            System.debug('  ' + objectType + ': ' + testData.get(objectType).size() + ' records');
        }
        
    } catch (Exception e) {
        System.debug('Error creating data for ' + flowName + ': ' + e.getMessage());
    }
}

// Create some additional Flow Runs with varied performance characteristics
List<FS_Flow_Run__c> performanceVariantRuns = new List<FS_Flow_Run__c>();

// Excellent performance flows
for (Integer i = 0; i < 5; i++) {
    FS_Flow_Run__c run = new FS_Flow_Run__c(
        Flow_API_Name__c = 'Fast_Processing_Flow',
        Interview_Id__c = 'fast-' + i,
        Runtime_User__c = UserInfo.getUserId(),
        Status__c = 'Success',
        Started_At__c = System.now().addHours(-i * 2),
        Duration_Millis__c = 800 + i * 50,
        CPU_Time_Millis__c = 300 + i * 20,
        SOQL_Count__c = 2 + Math.mod(i, 2),
        DML_Count__c = 1,
        Heap_Size_Bytes__c = 512 * 1024
    );
    performanceVariantRuns.add(run);
}

// Medium performance flows  
for (Integer i = 0; i < 5; i++) {
    FS_Flow_Run__c run = new FS_Flow_Run__c(
        Flow_API_Name__c = 'Standard_Processing_Flow',
        Interview_Id__c = 'standard-' + i,
        Runtime_User__c = UserInfo.getUserId(),
        Status__c = 'Success',
        Started_At__c = System.now().addHours(-i * 3),
        Duration_Millis__c = 3500 + i * 200,
        CPU_Time_Millis__c = 1200 + i * 100,
        SOQL_Count__c = 5 + Math.mod(i, 3),
        DML_Count__c = 3 + Math.mod(i, 2),
        Heap_Size_Bytes__c = 1024 * 1024 * (1 + Math.mod(i, 2))
    );
    performanceVariantRuns.add(run);
}

// Poor performance flows
for (Integer i = 0; i < 5; i++) {
    FS_Flow_Run__c run = new FS_Flow_Run__c(
        Flow_API_Name__c = 'Complex_Processing_Flow',
        Interview_Id__c = 'complex-' + i,
        Runtime_User__c = UserInfo.getUserId(),
        Status__c = i < 4 ? 'Success' : 'Failed',
        Started_At__c = System.now().addHours(-i * 4),
        Duration_Millis__c = 12000 + i * 1000,
        CPU_Time_Millis__c = 5000 + i * 500,
        SOQL_Count__c = 15 + Math.mod(i, 5),
        DML_Count__c = 8 + Math.mod(i, 3),
        Heap_Size_Bytes__c = 3 * 1024 * 1024,
        Error_Message__c = i >= 4 ? 'Test performance issue' : null
    );
    performanceVariantRuns.add(run);
}

// Critical performance flows
for (Integer i = 0; i < 3; i++) {
    FS_Flow_Run__c run = new FS_Flow_Run__c(
        Flow_API_Name__c = 'Heavy_Processing_Flow',
        Interview_Id__c = 'heavy-' + i,
        Runtime_User__c = UserInfo.getUserId(),
        Status__c = i < 2 ? 'Success' : 'Failed',
        Started_At__c = System.now().addHours(-i * 6),
        Duration_Millis__c = 45000 + i * 5000,
        CPU_Time_Millis__c = 15000 + i * 2000,
        SOQL_Count__c = 30 + i * 5,
        DML_Count__c = 20 + i * 3,
        Heap_Size_Bytes__c = 6 * 1024 * 1024,
        Error_Message__c = i >= 2 ? 'Critical performance bottleneck detected' : null
    );
    performanceVariantRuns.add(run);
}

insert performanceVariantRuns;
System.debug('Created ' + performanceVariantRuns.size() + ' performance variant flow runs');

// Create corresponding flow steps for better analysis
List<FS_Flow_Step__c> allSteps = new List<FS_Flow_Step__c>();

for (FS_Flow_Run__c run : performanceVariantRuns) {
    Integer stepCount = 3; // Standard number of steps
    
    for (Integer i = 1; i <= stepCount; i++) {
        FS_Flow_Step__c step = new FS_Flow_Step__c(
            Flow_Run__c = run.Id,
            Sequence_Number__c = i,
            Element_Developer_Name__c = 'Element_' + i,
            Element_Label__c = 'Processing Step ' + i,
            Element_Type__c = i == 1 ? 'Start' : (i == stepCount ? 'Screen' : 'Assignment'),
            Entered_At__c = run.Started_At__c.addMilliseconds((i-1) * (run.Duration_Millis__c.intValue() / stepCount)),
            Exited_At__c = run.Started_At__c.addMilliseconds(i * (run.Duration_Millis__c.intValue() / stepCount)),
            Duration_Millis__c = run.Duration_Millis__c / stepCount,
            CPU_Millis__c = run.CPU_Time_Millis__c != null ? (run.CPU_Time_Millis__c / stepCount) : 100,
            SOQL_Count__c = i == 2 ? run.SOQL_Count__c : 0, // Most queries in middle step
            DML_Count__c = i == stepCount ? run.DML_Count__c : 0, // DML in final step
            Outcome__c = 'Completed'
        );
        allSteps.add(step);
    }
}

insert allSteps;
System.debug('Created ' + allSteps.size() + ' flow steps');

System.debug('=== Demo Data Creation Complete ===');
System.debug('Total Flow Runs: ' + [SELECT COUNT() FROM FS_Flow_Run__c]);
System.debug('Total Flow Steps: ' + [SELECT COUNT() FROM FS_Flow_Step__c]);
System.debug('');
System.debug('You can now test the Performance Heatmap with this data!');