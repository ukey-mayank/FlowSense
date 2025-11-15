/**
 * @description Invocable action to start Flow logging - simplified version
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_LogStartAction {
    
    @InvocableMethod(
        label='FlowSense: Start Flow Run Logging' 
        description='Starts logging for a Flow execution and returns a run ID'
        category='FlowSense'
    )
    public static List<LogStartResult> startLogging(List<LogStartRequest> requests) {
        List<LogStartResult> results = new List<LogStartResult>();
        
        for (LogStartRequest request : requests) {
            LogStartResult result = new LogStartResult();
            
            try {
                // Generate interview ID if not provided
                String interviewId = String.isNotBlank(request.interviewId) 
                    ? request.interviewId 
                    : generateInterviewId();
                
                // Create Flow Run record
                FS_Flow_Run__c flowRun = new FS_Flow_Run__c();
                flowRun.Flow_API_Name__c = request.flowApiName;
                flowRun.Flow_Label__c = request.flowLabel;
                flowRun.Interview_Id__c = interviewId;
                flowRun.Start_Time__c = System.now();
                flowRun.Status__c = 'Running';
                
                insert flowRun;
                
                // Also log to debug logs
                System.debug('FlowSense: Starting Flow Run');
                System.debug('Flow API Name: ' + request.flowApiName);
                System.debug('Flow Label: ' + request.flowLabel);
                System.debug('Flow Version: ' + request.flowVersion);
                System.debug('Interview ID: ' + interviewId);
                System.debug('Trigger Context: ' + request.triggerContext);
                System.debug('Entry Record ID: ' + request.entryRecordId);
                System.debug('User ID: ' + UserInfo.getUserId());
                System.debug('Start Time: ' + System.now());
                
                result.runId = flowRun.Id;
                result.interviewId = interviewId;
                result.success = true;
                result.message = 'Flow logging started successfully';
                
            } catch (Exception e) {
                result.success = false;
                result.message = 'Failed to start Flow logging: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'FS_LogStartAction error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * @description Generate a unique interview ID
     * @return String Unique interview ID
     */
    private static String generateInterviewId() {
        return 'FS_' + System.currentTimeMillis() + '_' + Math.round(Math.random() * 10000);
    }
    
    /**
     * @description Input parameters for starting Flow logging
     */
    public class LogStartRequest {
        @InvocableVariable(required=true label='Flow API Name' description='The API name of the Flow')
        public String flowApiName;
        
        @InvocableVariable(required=false label='Flow Label' description='The display label of the Flow')
        public String flowLabel;
        
        @InvocableVariable(required=false label='Flow Version' description='The version number of the Flow')
        public Decimal flowVersion;
        
        @InvocableVariable(required=false label='Interview ID' description='Unique interview ID (auto-generated if not provided)')
        public String interviewId;
        
        @InvocableVariable(required=false label='Trigger Context' description='What triggered this Flow')
        public String triggerContext;
        
        @InvocableVariable(required=false label='Entry Record ID' description='Record ID that triggered the Flow')
        public String entryRecordId;
    }
    
    /**
     * @description Output results from starting Flow logging
     */
    public class LogStartResult {
        @InvocableVariable(label='Run ID' description='The ID of the created Flow Run record')
        public String runId;
        
        @InvocableVariable(label='Interview ID' description='The unique interview ID for this Flow execution')
        public String interviewId;
        
        @InvocableVariable(label='Success' description='Whether the operation was successful')
        public Boolean success;
        
        @InvocableVariable(label='Message' description='Success or error message')
        public String message;
    }
}