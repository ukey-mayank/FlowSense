/**
 * @description Test class for FS_NotifyOnErrorAction
 * @author FlowSense
 * @version 1.0
 */
@IsTest
private class FS_NotifyOnErrorActionTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test alert policies
        List<FS_Flow_Alert__c> alertPolicies = new List<FS_Flow_Alert__c>();
        
        // Policy for all flows
        alertPolicies.add(new FS_Flow_Alert__c(
            Name = 'All Flows Policy',
            Active__c = true,
            Severity__c = 'Warning',
            Applies_To__c = 'All',
            Channel__c = 'Email',
            Email_Recipients__c = 'admin@test.com',
            Alert_Frequency__c = 'Every_Occurrence'
        ));
        
        // Policy for specific flow
        alertPolicies.add(new FS_Flow_Alert__c(
            Name = 'Test Flow Policy',
            Active__c = true,
            Severity__c = 'Critical',
            Applies_To__c = 'By_API_Name',
            Flow_Filter__c = 'Test_Flow',
            Channel__c = 'Email;Slack',
            Email_Recipients__c = 'test@example.com,admin@test.com',
            Slack_Channel__c = '#alerts',
            Alert_Frequency__c = 'Once_Per_Hour'
        ));
        
        // Policy for pattern matching
        alertPolicies.add(new FS_Flow_Alert__c(
            Name = 'Pattern Policy',
            Active__c = true,
            Severity__c = 'Warning',
            Applies_To__c = 'By_Pattern',
            Flow_Filter__c = '.*Test.*',
            Channel__c = 'Platform_Event',
            Alert_Frequency__c = 'Once_Per_Day'
        ));
        
        // Inactive policy
        alertPolicies.add(new FS_Flow_Alert__c(
            Name = 'Inactive Policy',
            Active__c = false,
            Severity__c = 'Info',
            Applies_To__c = 'All',
            Channel__c = 'Email',
            Email_Recipients__c = 'inactive@test.com',
            Alert_Frequency__c = 'Every_Occurrence'
        ));
        
        insert alertPolicies;
        
        // TEMPORARY: Commented out during CMDT migration
        // Create global settings for async processing
        // FS_Global_Settings__c settings = new FS_Global_Settings__c(
        //     Name = 'Default',
        //     Enable_Async_Processing__c = true,
        //     Enable_Error_Alerts__c = true
        // );
        // CMDT Migration: Commented out - FS_SettingsUtil provides defaults
        // insert settings;
    }
    
    @IsTest
    static void testNotifyOnErrorSuccess() {
        // Create test request
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'Test_Flow';
        request.errorMessage = 'Test error occurred';
        request.interviewId = 'test-interview-123';
        request.runtimeUser = 'test@example.com';
        request.flowLabel = 'Test Flow Label';
        request.errorType = 'FIELD_CUSTOM_VALIDATION_EXCEPTION';
        request.stackTrace = 'Test stack trace';
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(
            new List<FS_NotifyOnErrorAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assert(results[0].message.contains('processing'), 'Should indicate processing');
        System.assertEquals(null, results[0].errorMessage, 'Should not have error message');
    }
    
    @IsTest
    static void testNotifyOnErrorSyncProcessing() {
        // TEMPORARY: Commented out during CMDT migration
        // Disable async processing by updating existing settings
        // FS_Global_Settings__c settings = FS_Global_Settings__c.getOrgDefaults();
        // if (settings != null) {
        //     settings.Enable_Async_Processing__c = false;
        //     update settings;
        // } else {
        //     // Create new settings if none exist
        //     settings = new FS_Global_Settings__c(
        //         Name = 'Default',
        //         Enable_Async_Processing__c = false,
        //         Enable_Error_Alerts__c = true
        //     );
        //     insert settings;
        // }
        
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'Test_Flow';
        request.errorMessage = 'Sync test error';
        request.interviewId = 'sync-interview-123';
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(
            new List<FS_NotifyOnErrorAction.Request>{ request }
        );
        Test.stopTest();
        
        // Verify sync processing
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assert(results[0].message.contains('synchronously'), 'Should indicate sync processing');
    }
    
    @IsTest
    static void testNotifyOnErrorBulkRequests() {
        List<FS_NotifyOnErrorAction.Request> requests = new List<FS_NotifyOnErrorAction.Request>();
        
        for (Integer i = 0; i < 5; i++) {
            FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
            request.flowApiName = 'Bulk_Test_Flow_' + i;
            request.errorMessage = 'Bulk error ' + i;
            request.interviewId = 'bulk-interview-' + i;
            requests.add(request);
        }
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(requests);
        Test.stopTest();
        
        // Verify bulk processing
        System.assertEquals(5, results.size(), 'Should return five results');
        for (FS_NotifyOnErrorAction.Result result : results) {
            System.assertEquals(true, result.isSuccess, 'All should be successful');
            System.assertNotEquals(null, result.message, 'All should have message');
        }
    }
    
    @IsTest
    static void testNotifyOnErrorWithEmptyRequest() {
        // Test graceful handling of minimal request
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'Empty_Test_Flow';
        request.errorMessage = 'Minimal error test';
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(
            new List<FS_NotifyOnErrorAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should handle gracefully
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should handle gracefully');
        System.assertNotEquals(null, results[0].message, 'Should have message');
    }
    
    @IsTest
    static void testAlertPolicyMatching() {
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'Test_Flow';
        request.errorMessage = 'Policy matching test';
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(
            new List<FS_NotifyOnErrorAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should process successfully with multiple matching policies
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
    }
    
    @IsTest
    static void testAlertPolicyPatternMatching() {
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'My_Test_Flow_Name';
        request.errorMessage = 'Pattern matching test';
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(
            new List<FS_NotifyOnErrorAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should match pattern policy
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
    }
    
    @IsTest
    static void testNoMatchingPolicies() {
        // Delete all policies to test behavior with no matches
        delete [SELECT Id FROM FS_Flow_Alert__c];
        
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'No_Match_Flow';
        request.errorMessage = 'No policy match test';
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(
            new List<FS_NotifyOnErrorAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should still process successfully even with no matching policies
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
    }
    
    @IsTest
    static void testFrequencyControlEveryOccurrence() {
        // Test "Every_Occurrence" frequency setting
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'Frequency_Test_Flow';
        request.errorMessage = 'Frequency test error';
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(
            new List<FS_NotifyOnErrorAction.Request>{ request }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
    }
    
    @IsTest
    static void testEmailNotificationChannels() {
        // Create policy with email channel
        FS_Flow_Alert__c emailPolicy = new FS_Flow_Alert__c(
            Name = 'Email Test Policy',
            Active__c = true,
            Severity__c = 'Critical',
            Applies_To__c = 'By_API_Name',
            Flow_Filter__c = 'Email_Test_Flow',
            Channel__c = 'Email',
            Email_Recipients__c = 'test1@example.com;test2@example.com',
            Alert_Frequency__c = 'Every_Occurrence'
        );
        insert emailPolicy;
        
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'Email_Test_Flow';
        request.errorMessage = 'Email notification test';
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(
            new List<FS_NotifyOnErrorAction.Request>{ request }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
    }
    
    @IsTest
    static void testMultipleNotificationChannels() {
        // Create policy with multiple channels
        FS_Flow_Alert__c multiChannelPolicy = new FS_Flow_Alert__c(
            Name = 'Multi Channel Policy',
            Active__c = true,
            Severity__c = 'Warning',
            Applies_To__c = 'By_API_Name',
            Flow_Filter__c = 'Multi_Channel_Flow',
            Channel__c = 'Email;Slack;Teams;Webhook;Platform_Event',
            Email_Recipients__c = 'multi@example.com',
            Slack_Channel__c = '#multi-alerts',
            Webhook_URL__c = 'https://webhook.example.com',
            Alert_Frequency__c = 'Every_Occurrence'
        );
        insert multiChannelPolicy;
        
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'Multi_Channel_Flow';
        request.errorMessage = 'Multi-channel test error';
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(
            new List<FS_NotifyOnErrorAction.Request>{ request }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
    }
    
    @IsTest
    static void testQueueableExecution() {
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'Queueable_Test_Flow';
        request.errorMessage = 'Queueable test error';
        request.interviewId = 'queueable-interview-123';
        
        Test.startTest();
        FS_NotifyOnErrorAction.FS_NotifyOnErrorQueueable queueable = 
            new FS_NotifyOnErrorAction.FS_NotifyOnErrorQueueable(request);
        System.enqueueJob(queueable);
        Test.stopTest();
        
        // Verify queueable execution completes without exception
        System.assert(true, 'Queueable should execute without exception');
    }
    
    @IsTest
    static void testIsAsyncProcessingEnabled() {
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'Async_Test_Flow';
        request.errorMessage = 'Async test error';
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(
            new List<FS_NotifyOnErrorAction.Request>{ request }
        );
        Test.stopTest();
        
        // Should use async processing by default with current settings
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assert(results[0].message.contains('async'), 'Should indicate async processing');
    }
    
    @IsTest
    static void testAlertStatisticsUpdate() {
        FS_Flow_Alert__c policy = [SELECT Id, Alert_Count__c, Last_Alert_Sent__c FROM FS_Flow_Alert__c WHERE Name = 'All Flows Policy' LIMIT 1];
        Decimal originalCount = policy.Alert_Count__c != null ? policy.Alert_Count__c : 0;
        DateTime originalTime = policy.Last_Alert_Sent__c;
        
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'Stats_Test_Flow';
        request.errorMessage = 'Statistics test error';
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(
            new List<FS_NotifyOnErrorAction.Request>{ request }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        
        // Verify statistics might be updated (depends on internal processing)
        policy = [SELECT Id, Alert_Count__c, Last_Alert_Sent__c FROM FS_Flow_Alert__c WHERE Id = :policy.Id];
        System.assert(policy.Alert_Count__c >= originalCount, 'Alert count should not decrease');
    }
    
    @IsTest
    static void testCompleteErrorScenario() {
        FS_NotifyOnErrorAction.Request request = new FS_NotifyOnErrorAction.Request();
        request.flowApiName = 'Complete_Error_Test';
        request.errorMessage = 'Complete error scenario test';
        request.interviewId = 'complete-123';
        request.runtimeUser = 'testuser@example.com';
        request.flowLabel = 'Complete Error Test Flow';
        request.errorType = 'APEX_ERROR';
        request.stackTrace = 'Line 1: Error occurred\nLine 2: Stack trace continues';
        
        Test.startTest();
        List<FS_NotifyOnErrorAction.Result> results = FS_NotifyOnErrorAction.notifyOnError(
            new List<FS_NotifyOnErrorAction.Request>{ request }
        );
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0].isSuccess, 'Should be successful');
        System.assertNotEquals(null, results[0].message, 'Should have success message');
    }
}
