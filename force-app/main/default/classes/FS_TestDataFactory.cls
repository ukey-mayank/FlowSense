/**
 * @description Test data factory for FlowSense application
 * @author FlowSense
 * @version 1.0
 */
@isTest
public class FS_TestDataFactory {
    
    /**
     * @description TEMPORARY: Commented out during CMDT migration
     * Custom Metadata Types don't support test data creation
     * Settings now use FS_SettingsUtil which provides default values in tests
     * @return null
     */
    public static void createGlobalSettings() {
        // No-op: CMDT migration - settings use default values from FS_SettingsUtil
        System.debug('createGlobalSettings() is no longer needed. FS_SettingsUtil provides defaults.');
    }
    
    /**
     * @description TEMPORARY: Commented out during CMDT migration
     * Custom Metadata Types don't support test data creation
     * @param settingsName Name for the settings record (ignored)
     */
    public static void createGlobalSettings(String settingsName) {
        // No-op: CMDT migration - settings use default values from FS_SettingsUtil
        System.debug('createGlobalSettings() is no longer needed. FS_SettingsUtil provides defaults.');
    }
    
    /**
     * @description Create test Flow Run records
     * @param flowApiName API name of the flow
     * @param count Number of records to create
     * @param insertRecords Whether to insert or just return
     * @return List of FS_Flow_Run__c records
     */
    public static List<FS_Flow_Run__c> createFlowRuns(String flowApiName, Integer count, Boolean insertRecords) {
        List<FS_Flow_Run__c> flowRuns = new List<FS_Flow_Run__c>();
        
        for (Integer i = 0; i < count; i++) {
            FS_Flow_Run__c flowRun = new FS_Flow_Run__c(
                Flow_API_Name__c = flowApiName,
                Flow_Label__c = 'Test Flow ' + i,
                Started_At__c = System.now().addMinutes(-i * 10),
                End_Time__c = System.now().addMinutes(-i * 10 + 5),
                Duration_Ms__c = 5000 + (i * 100),
                Duration_Millis__c = 5000 + (i * 100),
                CPU_Time_Millis__c = 1000 + (i * 50),
                CPU_Time__c = 1000 + (i * 50),
                SOQL_Count__c = 10 + i,
                SOQL_Queries__c = 10 + i,
                DML_Count__c = 5 + i,
                DML_Statements__c = 5 + i,
                Heap_Size_Bytes__c = 100000 + (i * 1000),
                Heap_Size__c = 100000 + (i * 1000),
                Runtime_User__c = UserInfo.getUserId(),
                Interview_Id__c = 'INT-' + String.valueOf(System.currentTimeMillis()) + '-' + String.valueOf(i).leftPad(10, '0'),
                Status__c = i == 0 ? 'Failed' : 'Success',
                Error_Message__c = i == 0 ? 'Test error message' : null,
                Error_Details__c = i == 0 ? 'Detailed error information' : null,
                Performance_Score__c = 85 - (i * 2),
                Performance_Alert__c = i == 0 ? true : false
            );
            flowRuns.add(flowRun);
        }
        
        if (insertRecords) {
            insert flowRuns;
        }
        
        return flowRuns;
    }
    
    /**
     * @description Create test Flow Step records
     * @param flowRun Parent flow run record
     * @param stepCount Number of steps to create
     * @param insertRecords Whether to insert or just return
     * @return List of FS_Flow_Step__c records
     */
    public static List<FS_Flow_Step__c> createFlowSteps(FS_Flow_Run__c flowRun, Integer stepCount, Boolean insertRecords) {
        List<FS_Flow_Step__c> flowSteps = new List<FS_Flow_Step__c>();
        
        for (Integer i = 0; i < stepCount; i++) {
            FS_Flow_Step__c step = new FS_Flow_Step__c(
                Flow_Run__c = flowRun.Id,
                Element_DeveloperName__c = 'Element_' + i,
                Element_Label__c = 'Element Label ' + i,
                Element_Type__c = i == 0 ? 'Screen' : (i == stepCount - 1 ? 'Screen' : 'Assignment'),
                Entered_At__c = flowRun.Started_At__c.addSeconds(i * 30),
                Exited_At__c = flowRun.Started_At__c.addSeconds(i * 30 + 15),
                Duration_Millis__c = 15000,
                CPU_Millis__c = 500 + (i * 50),
                SOQL_Count__c = 2,
                DML_Count__c = 1,
                Sequence__c = i + 1,
                Outcome__c = Math.mod(i, 2) == 0 ? 'True' : 'False',
                Input_Variables__c = '{"var1": "input1"}',
                Output_Variables__c = '{"var2": "output2"}',
                Error_Message__c = null
            );
            flowSteps.add(step);
        }
        
        if (insertRecords) {
            insert flowSteps;
        }
        
        return flowSteps;
    }
    
    /**
     * @description Create test Flow Analysis records
     * @param flowApiName API name of the flow
     * @param count Number of records to create
     * @param insertRecords Whether to insert or just return
     * @return List of FS_Flow_Analysis__c records
     */
    public static List<FS_Flow_Analysis__c> createFlowAnalyses(String flowApiName, Integer count, Boolean insertRecords) {
        List<FS_Flow_Analysis__c> analyses = new List<FS_Flow_Analysis__c>();
        
        for (Integer i = 0; i < count; i++) {
            FS_Flow_Analysis__c analysis = new FS_Flow_Analysis__c(
                Flow_API_Name__c = flowApiName,
                Analysis_Type__c = 'Performance',
                Analysis_Date__c = System.now().addDays(-i),
                Analyzed_At__c = System.now().addDays(-i),
                Performance_Score__c = 85 - (i * 5),
                Risk_Level__c = i == 0 ? 'High' : (i == 1 ? 'Medium' : 'Low'),
                Risk_Score__c = 75 - (i * 10),
                Complexity_Score__c = 60 + (i * 5),
                Analysis_Data__c = '{"metrics": {"avgDuration": 5000, "errorRate": 0.05}}',
                Recommendations__c = 'Optimize step ' + i + ' for better performance',
                AI_Summary__c = 'AI analysis summary for flow execution ' + i
            );
            analyses.add(analysis);
        }
        
        if (insertRecords) {
            insert analyses;
        }
        
        return analyses;
    }
    
    /**
     * @description Create test Flow Change records
     * @param flowApiName API name of the flow
     * @param count Number of records to create
     * @param insertRecords Whether to insert or just return
     * @return List of FS_Flow_Change__c records
     */
    public static List<FS_Flow_Change__c> createFlowChanges(String flowApiName, Integer count, Boolean insertRecords) {
        List<FS_Flow_Change__c> changes = new List<FS_Flow_Change__c>();
        
        for (Integer i = 0; i < count; i++) {
            FS_Flow_Change__c change = new FS_Flow_Change__c(
                Flow_Api_Name__c = flowApiName,
                From_Version__c = i + 1,
                To_Version__c = i + 2,
                Version__c = i + 2,
                Change_Summary__c = 'Version ' + (i + 1) + ' to ' + (i + 2) + ' changes',
                Analyzed_At__c = System.now().addDays(-i),
                Impact_Level__c = i == 0 ? 'High' : 'Medium',
                Hash__c = 'hash' + String.valueOf(System.currentTimeMillis()) + '_' + String.valueOf(i).leftPad(10, '0')
            );
            changes.add(change);
        }
        
        if (insertRecords) {
            insert changes;
        }
        
        return changes;
    }
    
    /**
     * @description Create complete test data set for a flow
     * @param flowApiName API name of the flow
     * @return Map containing all created records
     */
    public static Map<String, List<SObject>> createCompleteFlowDataSet(String flowApiName) {
        Map<String, List<SObject>> testData = new Map<String, List<SObject>>();
        
        // TEMPORARY: Commented out during CMDT migration
        // Create and insert global settings
        // FS_Global_Settings__c settings = createGlobalSettings('Test Settings');
        // insert settings;
        
        // Create and insert flow runs
        List<FS_Flow_Run__c> flowRuns = createFlowRuns(flowApiName, 5, true);
        testData.put('FlowRuns', flowRuns);
        
        // Create and insert flow steps for each run
        List<FS_Flow_Step__c> allSteps = new List<FS_Flow_Step__c>();
        for (FS_Flow_Run__c run : flowRuns) {
            List<FS_Flow_Step__c> steps = createFlowSteps(run, 3, false);
            allSteps.addAll(steps);
        }
        insert allSteps;
        testData.put('FlowSteps', allSteps);
        
        // Create and insert flow analyses
        List<FS_Flow_Analysis__c> allAnalyses = new List<FS_Flow_Analysis__c>();
        for (FS_Flow_Run__c run : flowRuns) {
            FS_Flow_Analysis__c analysis = new FS_Flow_Analysis__c(
                Flow_Run__c = run.Id,
                Flow_API_Name__c = run.Flow_API_Name__c,
                Analysis_Type__c = 'Performance',
                Analysis_Date__c = System.now(),
                Analyzed_At__c = System.now(),
                Performance_Score__c = 85,
                Risk_Level__c = 'Medium',
                Risk_Score__c = 75,
                Complexity_Score__c = 60,
                Analysis_Data__c = '{"metrics": {"avgDuration": 5000, "errorRate": 0.05}}',
                Recommendations__c = 'Optimize for better performance',
                AI_Summary__c = 'AI analysis summary for flow execution'
            );
            allAnalyses.add(analysis);
        }
        insert allAnalyses;
        testData.put('FlowAnalyses', allAnalyses);
        
        // Create and insert flow changes
        List<FS_Flow_Change__c> changes = createFlowChanges(flowApiName, 2, true);
        testData.put('FlowChanges', changes);
        
        return testData;
    }
    
    /**
     * @description Create test user with specific profile
     * @param firstName First name
     * @param lastName Last name
     * @param email Email address
     * @return User record (not inserted)
     */
    public static User createTestUser(String firstName, String lastName, String email) {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User testUser = new User(
            FirstName = firstName,
            LastName = lastName,
            Email = email,
            Username = email + '.test',
            Alias = firstName.substring(0, 1) + lastName.substring(0, 1),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id
        );
        
        return testUser;
    }
    
    /**
     * @description Mock Flow Metadata for testing
     * @param flowApiName API name of the flow
     * @return FlowMetadata mock object
     */
    public static FS_FlowMetadataService.FlowMetadata createMockFlowMetadata(String flowApiName) {
        FS_FlowMetadataService.FlowMetadata metadata = new FS_FlowMetadataService.FlowMetadata();
        metadata.apiName = flowApiName;
        metadata.label = 'Test Flow Label';
        metadata.isActive = true;
        metadata.totalVersions = 3;
        metadata.activeVersionNumber = 3;
        metadata.complexityScore = 75;
        metadata.lastModifiedDate = System.now().addDays(-5);
        metadata.lastModifiedBy = UserInfo.getName();
        metadata.description = 'Test flow description';
        metadata.apiVersion = '65.0';
        metadata.exists = true;
        metadata.processType = 'Flow';
        metadata.status = 'Active';
        
        return metadata;
    }
    
    /**
     * @description Generate a fake ID for testing purposes
     * @param sObjectType The SObject type to generate an ID for
     * @return Fake ID string
     */
    public static Id generateId(Schema.SObjectType sObjectType) {
        String keyPrefix = sObjectType.getDescribe().getKeyPrefix();
        String fakeId = keyPrefix + '0'.repeat(15 - keyPrefix.length());
        return (Id)fakeId;
    }
}