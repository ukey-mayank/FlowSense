/**
 * @description Invocable action to end Flow logging
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_LogEndAction {
    
    @InvocableMethod(
        label='FlowSense: End Flow Run Logging' 
        description='Ends logging for a Flow execution and records final metrics'
        category='FlowSense'
    )
    public static List<LogEndResult> endLogging(List<LogEndRequest> requests) {
        List<LogEndResult> results = new List<LogEndResult>();
        
        for (LogEndRequest request : requests) {
            LogEndResult result = new LogEndResult();
            
            try {
                // Get current resource usage if not provided
                Integer totalCpu = request.totalCpuMillis != null 
                    ? Integer.valueOf(request.totalCpuMillis) 
                    : Limits.getCpuTime();
                Integer totalSoql = request.totalSoqlCount != null 
                    ? Integer.valueOf(request.totalSoqlCount) 
                    : Limits.getQueries();
                Integer totalDml = request.totalDmlCount != null 
                    ? Integer.valueOf(request.totalDmlCount) 
                    : Limits.getDmlStatements();
                
                // Update Flow Run record
                List<FS_Flow_Run__c> flowRuns = [SELECT Id, Start_Time__c FROM FS_Flow_Run__c WHERE Interview_Id__c = :request.interviewId LIMIT 1];
                
                if (!flowRuns.isEmpty()) {
                    FS_Flow_Run__c flowRun = flowRuns[0];
                    flowRun.End_Time__c = System.now();
                    flowRun.Status__c = String.isNotBlank(request.status) ? request.status : 'Success';
                    flowRun.Error_Details__c = request.errorMessage;
                    flowRun.CPU_Time__c = totalCpu;
                    flowRun.SOQL_Queries__c = totalSoql;
                    flowRun.DML_Statements__c = totalDml;
                    
                    // Calculate duration
                    if (flowRun.Start_Time__c != null) {
                        Long durationMs = flowRun.End_Time__c.getTime() - flowRun.Start_Time__c.getTime();
                        flowRun.Duration_Ms__c = durationMs;
                    }
                    
                    update flowRun;
                }
                
                // Also log to debug logs
                System.debug('FlowSense: Ending Flow Run');
                System.debug('Interview ID: ' + request.interviewId);
                System.debug('Status: ' + (String.isNotBlank(request.status) ? request.status : 'Success'));
                System.debug('Error Message: ' + request.errorMessage);
                System.debug('Total CPU (ms): ' + totalCpu);
                System.debug('Total SOQL: ' + totalSoql);
                System.debug('Total DML: ' + totalDml);
                System.debug('End Time: ' + System.now());
                
                result.success = true;
                result.message = 'Flow logging ended successfully';
                
            } catch (Exception e) {
                result.success = false;
                result.message = 'Failed to end Flow logging: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'FS_LogEndAction error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * @description Input parameters for ending Flow logging
     */
    public class LogEndRequest {
        @InvocableVariable(required=true label='Interview ID' description='The unique interview ID for this Flow execution')
        public String interviewId;
        
        @InvocableVariable(required=false label='Status' description='Final status of the Flow (Success, Failed, Terminated)')
        public String status;
        
        @InvocableVariable(required=false label='Error Message' description='Error message if the Flow failed')
        public String errorMessage;
        
        @InvocableVariable(required=false label='Total CPU Milliseconds' description='Total CPU time consumed')
        public Decimal totalCpuMillis;
        
        @InvocableVariable(required=false label='Total SOQL Count' description='Total SOQL queries executed')
        public Decimal totalSoqlCount;
        
        @InvocableVariable(required=false label='Total DML Count' description='Total DML operations performed')
        public Decimal totalDmlCount;
    }
    
    /**
     * @description Output results from ending Flow logging
     */
    public class LogEndResult {
        @InvocableVariable(label='Success' description='Whether the operation was successful')
        public Boolean success;
        
        @InvocableVariable(label='Message' description='Success or error message')
        public String message;
    }
}