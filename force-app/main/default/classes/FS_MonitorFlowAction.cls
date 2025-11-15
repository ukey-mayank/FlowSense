/**
 * @description Simple Flow Monitoring Action - Logs monitoring data
 * @author FlowSense
 * @date 2024
 */
public with sharing class FS_MonitorFlowAction {
    
    @InvocableMethod(label='Monitor Flow Execution' description='Records flow execution data for monitoring')
    public static List<Result> monitorFlow(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        for (Request request : requests) {
            try {
                DateTime startTime = request.startTime != null ? request.startTime : System.now();
                DateTime endTime = request.endTime;
                String status = request.status != null ? request.status : 'Running';
                
                // Calculate duration if both times are provided
                Double durationSeconds = null;
                if (startTime != null && endTime != null) {
                    Long durationMs = endTime.getTime() - startTime.getTime();
                    durationSeconds = durationMs / 1000.0;
                }
                
                // Calculate performance score
                Double performanceScore = null;
                if (durationSeconds != null) {
                    performanceScore = calculatePerformanceScore(durationSeconds);
                }
                
                // Log the monitoring data
                System.debug('FlowSense Monitor for ' + request.flowApiName);
                System.debug('Flow Label: ' + request.flowLabel);
                System.debug('Status: ' + status);
                System.debug('Start Time: ' + startTime);
                System.debug('End Time: ' + endTime);
                System.debug('Duration: ' + durationSeconds + ' seconds');
                System.debug('Performance Score: ' + performanceScore);
                
                Result result = new Result();
                result.isSuccess = true;
                result.performanceScore = performanceScore;
                result.durationSeconds = durationSeconds;
                result.status = status;
                result.message = 'Monitoring completed for ' + request.flowApiName;
                results.add(result);
                
            } catch (Exception e) {
                Result result = new Result();
                result.isSuccess = false;
                result.errorMessage = e.getMessage();
                results.add(result);
            }
        }
        
        return results;
    }
    
    private static Double calculatePerformanceScore(Double durationSeconds) {
        if (durationSeconds == null) return null;
        
        // Simple performance scoring
        if (durationSeconds <= 1) return 100.0;
        if (durationSeconds <= 3) return 90.0;
        if (durationSeconds <= 5) return 80.0;
        if (durationSeconds <= 10) return 70.0;
        if (durationSeconds <= 20) return 60.0;
        if (durationSeconds <= 30) return 50.0;
        return 25.0; // Very slow
    }
    
    public class Request {
        @InvocableVariable(label='Flow API Name' required=true)
        public String flowApiName;
        
        @InvocableVariable(label='Flow Label')
        public String flowLabel;
        
        @InvocableVariable(label='Start Time')
        public DateTime startTime;
        
        @InvocableVariable(label='End Time')
        public DateTime endTime;
        
        @InvocableVariable(label='Status')
        public String status;
    }
    
    public class Result {
        @InvocableVariable(label='Success')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Performance Score')
        public Double performanceScore;
        
        @InvocableVariable(label='Duration (Seconds)')
        public Double durationSeconds;
        
        @InvocableVariable(label='Status')
        public String status;
        
        @InvocableVariable(label='Message')
        public String message;
        
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
}