/**
 * @description Invocable action for logging individual flow step execution details
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_LogStepAction {
    
    @InvocableMethod(label='Log Flow Step' description='Log execution details for an individual flow step' category='FlowSense')
    public static List<Result> logFlowStep(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        try {
            List<FS_Flow_Step__c> stepsToInsert = new List<FS_Flow_Step__c>();
            
            for (Request request : requests) {
                FS_Flow_Step__c step = new FS_Flow_Step__c();
                
                // Required fields
                step.Flow_Run__c = request.flowRunId;
                step.Sequence__c = request.sequence != null ? request.sequence : 0;
                step.Element_DeveloperName__c = request.elementDeveloperName;
                step.Element_Type__c = request.elementType;
                
                // Optional fields
                if (String.isNotBlank(request.elementLabel)) {
                    step.Element_Label__c = request.elementLabel;
                }
                
                // Timing information
                if (request.enteredAt != null) {
                    step.Entered_At__c = request.enteredAt;
                }
                if (request.exitedAt != null) {
                    step.Exited_At__c = request.exitedAt;
                }
                if (request.durationMs != null) {
                    step.Duration_Millis__c = request.durationMs;
                }
                
                // Performance metrics
                if (request.cpuTimeMs != null) {
                    step.CPU_Millis__c = request.cpuTimeMs;
                }
                if (request.soqlCount != null) {
                    step.SOQL_Count__c = request.soqlCount;
                }
                if (request.dmlCount != null) {
                    step.DML_Count__c = request.dmlCount;
                }
                
                // Outcome and error information
                if (String.isNotBlank(request.outcome)) {
                    step.Outcome__c = request.outcome;
                }
                if (String.isNotBlank(request.errorMessage)) {
                    step.Error_Message__c = request.errorMessage;
                }
                
                // Variable information (JSON serialized)
                if (String.isNotBlank(request.inputVariables)) {
                    step.Input_Variables__c = request.inputVariables;
                }
                if (String.isNotBlank(request.outputVariables)) {
                    step.Output_Variables__c = request.outputVariables;
                }
                
                stepsToInsert.add(step);
                
                // Debug logging if enabled
                if (isDebugEnabled()) {
                    System.debug('FlowSense Step Log: ' + request.elementDeveloperName + 
                               ' in sequence ' + request.sequence + 
                               ' took ' + request.durationMs + 'ms');
                }
            }
            
            // Insert step records
            if (!stepsToInsert.isEmpty()) {
                insert stepsToInsert;
            }
            
            // Build results
            for (Integer i = 0; i < requests.size(); i++) {
                Result result = new Result();
                result.isSuccess = true;
                result.stepId = stepsToInsert[i].Id;
                result.message = 'Step logged successfully for ' + requests[i].elementDeveloperName;
                results.add(result);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in FS_LogStepAction: ' + e.getMessage());
            
            // Return error results
            for (Request request : requests) {
                Result result = new Result();
                result.isSuccess = false;
                result.errorMessage = 'Failed to log step: ' + e.getMessage();
                results.add(result);
            }
        }
        
        return results;
    }
    
    /**
     * @description Check if debug logging is enabled
     * @return Boolean indicating if debug logging is enabled
     */
    private static Boolean isDebugEnabled() {
        try {
            return FS_SettingsUtil.isDebugLoggingEnabled();
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * @description Request wrapper for step logging
     */
    public class Request {
        @InvocableVariable(label='Flow Run ID' description='ID of the Flow Run record' required=true)
        public String flowRunId;
        
        @InvocableVariable(label='Sequence Number' description='Sequence number of this step in the flow execution' required=true)
        public Integer sequence;
        
        @InvocableVariable(label='Element Developer Name' description='Developer name of the flow element' required=true)
        public String elementDeveloperName;
        
        @InvocableVariable(label='Element Type' description='Type of flow element (Assignment, Decision, etc.)' required=true)
        public String elementType;
        
        @InvocableVariable(label='Element Label' description='User-friendly label of the flow element')
        public String elementLabel;
        
        @InvocableVariable(label='Entered At' description='Timestamp when the element was entered')
        public DateTime enteredAt;
        
        @InvocableVariable(label='Exited At' description='Timestamp when the element was exited')
        public DateTime exitedAt;
        
        @InvocableVariable(label='Duration (ms)' description='Duration of element execution in milliseconds')
        public Integer durationMs;
        
        @InvocableVariable(label='CPU Time (ms)' description='CPU time consumed by this element in milliseconds')
        public Integer cpuTimeMs;
        
        @InvocableVariable(label='SOQL Count' description='Number of SOQL queries executed in this element')
        public Integer soqlCount;
        
        @InvocableVariable(label='DML Count' description='Number of DML operations executed in this element')
        public Integer dmlCount;
        
        @InvocableVariable(label='Outcome' description='Outcome or decision result of this element')
        public String outcome;
        
        @InvocableVariable(label='Error Message' description='Error message if the element failed')
        public String errorMessage;
        
        @InvocableVariable(label='Input Variables' description='JSON representation of input variables')
        public String inputVariables;
        
        @InvocableVariable(label='Output Variables' description='JSON representation of output variables')
        public String outputVariables;
    }
    
    /**
     * @description Result wrapper for step logging
     */
    public class Result {
        @InvocableVariable(label='Success' description='Indicates if the step was logged successfully')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Step ID' description='ID of the created Flow Step record')
        public String stepId;
        
        @InvocableVariable(label='Message' description='Success or informational message')
        public String message;
        
        @InvocableVariable(label='Error Message' description='Error message if logging failed')
        public String errorMessage;
    }
}