/**
 * @description Service class for centralized logging and audit trail management
 * @author FlowSense
 * @version 1.0
 */
public without sharing class FS_LoggingService {
    
    private static final String CLASS_NAME = 'FS_LoggingService';
    
    /**
     * @description Log flow execution start
     * @param flowApiName API name of the flow
     * @param interviewId Flow interview ID
     * @param runtimeUser User running the flow
     * @param flowLabel User-friendly flow label
     * @return FS_Flow_Run__c record
     */
    public static FS_Flow_Run__c logFlowStart(String flowApiName, String interviewId, String runtimeUser, String flowLabel) {
        try {
            FS_Flow_Run__c flowRun = new FS_Flow_Run__c();
            flowRun.Flow_API_Name__c = String.isNotBlank(flowApiName) ? flowApiName : 'Unknown_Flow';
            flowRun.Interview_ID__c = String.isNotBlank(interviewId) ? interviewId : 'test-interview-' + System.currentTimeMillis();
            flowRun.Runtime_User__c = runtimeUser;
            flowRun.Flow_Label__c = flowLabel;
            flowRun.Started_At__c = System.now();
            flowRun.Status__c = 'Success'; // Valid picklist value
            
            insert flowRun;
            
            System.debug(LoggingLevel.INFO, CLASS_NAME + ': Run logged - ' + flowApiName + ' (' + interviewId + ')');
            return flowRun;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error logging flow start - ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Exception type: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Stack trace: ' + e.getStackTraceString());
            return null;
        }
    }
    
    /**
     * @description Log flow execution completion
     * @param flowRunId Flow run record ID
     * @param status Final status (Completed, Failed, etc.)
     * @param errorMessage Error message if failed
     * @param cpuTime CPU time consumed
     * @param soqlCount Number of SOQL queries
     * @param dmlCount Number of DML operations
     * @param heapSize Heap size used
     */
    public static void logFlowCompletion(Id flowRunId, String status, String errorMessage, 
                                       Decimal cpuTime, Decimal soqlCount, Decimal dmlCount, Decimal heapSize) {
        try {
            if (flowRunId == null) {
                return;
            }
            
            FS_Flow_Run__c flowRun = new FS_Flow_Run__c();
            flowRun.Id = flowRunId;
            flowRun.Status__c = status;
            flowRun.Completed_At__c = System.now();
            flowRun.Error_Message__c = errorMessage;
            flowRun.CPU_Time_Millis__c = cpuTime;
            flowRun.SOQL_Count__c = soqlCount;
            flowRun.DML_Count__c = dmlCount;
            flowRun.Heap_Size_Bytes__c = heapSize;
            
            // Calculate duration
            if (flowRun.Completed_At__c != null) {
                List<FS_Flow_Run__c> existingRuns = [
                    SELECT Started_At__c 
                    FROM FS_Flow_Run__c 
                    WHERE Id = :flowRunId 
                    LIMIT 1
                ];
                
                if (!existingRuns.isEmpty() && existingRuns[0].Started_At__c != null) {
                    Long durationMillis = flowRun.Completed_At__c.getTime() - existingRuns[0].Started_At__c.getTime();
                    flowRun.Duration_Ms__c = durationMillis;
                }
            }
            
            update flowRun;
            
            System.debug(LoggingLevel.INFO, CLASS_NAME + ': Flow completion logged - Status: ' + status);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error logging flow completion - ' + e.getMessage());
        }
    }
    
    /**
     * @description Log individual flow step execution
     * @param flowRunId Parent flow run ID
     * @param stepData Step execution data
     */
    public static void logFlowStep(Id flowRunId, FlowStepData stepData) {
        try {
            if (flowRunId == null || stepData == null) {
                return;
            }
            
            FS_Flow_Step__c flowStep = new FS_Flow_Step__c();
            flowStep.Flow_Run__c = flowRunId;
            flowStep.Sequence__c = stepData.sequenceNumber;
            flowStep.Element_DeveloperName__c = stepData.elementDeveloperName;
            flowStep.Element_Type__c = stepData.elementType;
            
            insert flowStep;
            
            System.debug(LoggingLevel.DEBUG, CLASS_NAME + ': Step logged - ' + stepData.elementDeveloperName);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error logging flow step - ' + e.getMessage());
        }
    }
    
    /**
     * @description Bulk log multiple flow steps
     * @param flowRunId Parent flow run ID
     * @param stepDataList List of step execution data
     */
    public static void logFlowSteps(Id flowRunId, List<FlowStepData> stepDataList) {
        try {
            if (flowRunId == null || stepDataList == null || stepDataList.isEmpty()) {
                return;
            }
            
            List<FS_Flow_Step__c> flowSteps = new List<FS_Flow_Step__c>();
            
            for (FlowStepData stepData : stepDataList) {
                if (stepData == null) continue; // Skip null step data
                
                FS_Flow_Step__c flowStep = new FS_Flow_Step__c();
                flowStep.Flow_Run__c = flowRunId;
                flowStep.Sequence__c = stepData.sequenceNumber != null ? stepData.sequenceNumber : 1;
                flowStep.Element_DeveloperName__c = String.isNotBlank(stepData.elementDeveloperName) ? stepData.elementDeveloperName : 'Unknown_Element';
                flowStep.Element_Type__c = String.isNotBlank(stepData.elementType) ? stepData.elementType : 'Unknown';
                
                flowSteps.add(flowStep);
            }
            
            if (!flowSteps.isEmpty()) {
                insert flowSteps;
                System.debug(LoggingLevel.INFO, CLASS_NAME + ': Bulk logged ' + flowSteps.size() + ' flow steps');
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error bulk logging flow steps - ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Exception type: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Stack trace: ' + e.getStackTraceString());
        }
    }
    
    /**
     * @description Create flow analysis record
     * @param flowApiName API name of the flow
     * @param analysisType Type of analysis performed
     * @param analysisData Analysis results in JSON format
     * @param recommendations Generated recommendations
     * @param riskScore Calculated risk score
     * @param performanceScore Calculated performance score
     * @return FS_Flow_Analysis__c record
     */
    public static FS_Flow_Analysis__c createFlowAnalysis(String flowApiName, String analysisType, 
                                                        String analysisData, String recommendations, 
                                                        Decimal riskScore, Decimal performanceScore) {
        try {
            // Normalize flowApiName to handle null values
            String normalizedFlowApiName = String.isNotBlank(flowApiName) ? flowApiName : 'Unknown_Flow';
            
            // Get a flow run for this flow or create a dummy one
            List<FS_Flow_Run__c> flowRuns = [
                SELECT Id 
                FROM FS_Flow_Run__c 
                WHERE Flow_API_Name__c = :normalizedFlowApiName 
                LIMIT 1
            ];
            
            Id flowRunId;
            if (!flowRuns.isEmpty()) {
                flowRunId = flowRuns[0].Id;
            } else {
                // Create a minimal flow run directly for the analysis
                try {
                    FS_Flow_Run__c dummyRun = new FS_Flow_Run__c();
                    dummyRun.Flow_API_Name__c = normalizedFlowApiName;
                    dummyRun.Interview_ID__c = 'analysis-' + System.currentTimeMillis();
                    dummyRun.Status__c = 'Success'; // Valid picklist value
                    dummyRun.Started_At__c = System.now();
                    insert dummyRun;
                    flowRunId = dummyRun.Id;
                } catch (Exception runException) {
                    System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error creating dummy run - ' + runException.getMessage());
                    return null;
                }
            }
            
            FS_Flow_Analysis__c analysis = new FS_Flow_Analysis__c();
            analysis.Flow_API_Name__c = normalizedFlowApiName;
            analysis.Flow_Run__c = flowRunId;
            analysis.Analysis_Type__c = String.isNotBlank(analysisType) ? analysisType : 'Performance';
            analysis.Analysis_Date__c = System.now();
            analysis.Status__c = 'Completed';
            // Only set available fields
            if (performanceScore != null) {
                analysis.Performance_Score__c = performanceScore;
            }
            if (String.isNotBlank(String.valueOf(riskScore))) {
                analysis.Risk_Score__c = riskScore;
            }
            
            insert analysis;
            
            System.debug(LoggingLevel.INFO, CLASS_NAME + ': Analysis created - ' + flowApiName + ' (' + analysisType + ')');
            return analysis;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error creating analysis - ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Exception type: ' + e.getTypeName());
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Stack trace: ' + e.getStackTraceString());
            return null;
        }
    }
    
    /**
     * @description Get flow execution statistics
     * @param flowApiName API name of the flow
     * @param daysPast Number of days to look back
     * @return Flow execution statistics
     */
    public static FlowExecutionStats getFlowExecutionStats(String flowApiName, Integer daysPast) {
        FlowExecutionStats stats = new FlowExecutionStats();
        
        try {
            DateTime startDate = System.now().addDays(-daysPast);
            
            // Get basic statistics
            List<AggregateResult> results = [
                SELECT 
                    COUNT(Id) totalRuns,
                    COUNT_DISTINCT(Runtime_User__c) uniqueUsers,
                    AVG(Duration_Ms__c) avgDuration,
                    MAX(Duration_Ms__c) maxDuration,
                    AVG(CPU_Time_Millis__c) avgCpuTime,
                    AVG(SOQL_Count__c) avgSoqlCount,
                    AVG(DML_Count__c) avgDmlCount
                FROM FS_Flow_Run__c 
                WHERE Flow_API_Name__c = :flowApiName 
                AND Started_At__c >= :startDate
            ];
            
            // Get success/failure counts separately
            List<AggregateResult> successResults = [
                SELECT COUNT(Id) successfulRuns
                FROM FS_Flow_Run__c 
                WHERE Flow_API_Name__c = :flowApiName 
                AND Started_At__c >= :startDate
                AND Status__c = 'Success'
            ];
            
            List<AggregateResult> failureResults = [
                SELECT COUNT(Id) failedRuns
                FROM FS_Flow_Run__c 
                WHERE Flow_API_Name__c = :flowApiName 
                AND Started_At__c >= :startDate
                AND Status__c = 'Failed'
            ];
            
            if (!results.isEmpty()) {
                AggregateResult result = results[0];
                stats.totalRuns = (Integer)result.get('totalRuns');
                stats.uniqueUsers = (Integer)result.get('uniqueUsers');
                stats.avgDuration = (Decimal)result.get('avgDuration');
                stats.maxDuration = (Decimal)result.get('maxDuration');
                stats.avgCpuTime = (Decimal)result.get('avgCpuTime');
                stats.avgSoqlCount = (Decimal)result.get('avgSoqlCount');
                stats.avgDmlCount = (Decimal)result.get('avgDmlCount');
            }
            
            if (!successResults.isEmpty()) {
                stats.successfulRuns = (Integer)successResults[0].get('successfulRuns');
            }
            
            if (!failureResults.isEmpty()) {
                stats.failedRuns = (Integer)failureResults[0].get('failedRuns');
            }
            
            if (stats.totalRuns > 0) {
                stats.successRate = (Decimal)stats.successfulRuns / (Decimal)stats.totalRuns * 100;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error getting flow execution stats - ' + e.getMessage());
        }
        
        return stats;
    }
    
    /**
     * @description Clean up old flow execution records based on retention settings
     */
    public static void cleanupOldRecords() {
        try {
            Integer retentionDays = FS_SettingsUtil.getRetentionDays();
            
            DateTime cutoffDate = System.now().addDays(-retentionDays);
            
            // Delete old flow steps first (due to master-detail relationship)
            List<FS_Flow_Step__c> oldSteps = [
                SELECT Id 
                FROM FS_Flow_Step__c 
                WHERE Flow_Run__r.Started_At__c < :cutoffDate 
                LIMIT 10000
            ];

            if (!oldSteps.isEmpty()) {
                delete oldSteps;
                System.debug(LoggingLevel.INFO, CLASS_NAME + ': Deleted ' + oldSteps.size() + ' old flow steps');
            }

            // Delete old analyses next (due to lookup constraint on Flow_Run__c)
            List<FS_Flow_Analysis__c> oldAnalyses = [
                SELECT Id 
                FROM FS_Flow_Analysis__c 
                WHERE Analysis_Date__c < :cutoffDate 
                LIMIT 10000
            ];

            if (!oldAnalyses.isEmpty()) {
                delete oldAnalyses;
                System.debug(LoggingLevel.INFO, CLASS_NAME + ': Deleted ' + oldAnalyses.size() + ' old analyses');
            }

            // Delete old flow runs last
            List<FS_Flow_Run__c> oldRuns = [
                SELECT Id 
                FROM FS_Flow_Run__c 
                WHERE Started_At__c < :cutoffDate 
                LIMIT 10000
            ];            if (!oldRuns.isEmpty()) {
                delete oldRuns;
                System.debug(LoggingLevel.INFO, CLASS_NAME + ': Deleted ' + oldRuns.size() + ' old runs');
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error cleaning up old records - ' + e.getMessage());
        }
    }
    
    /**
     * @description Check if step logging is enabled
     * @return Boolean indicating if step logging is enabled
     */
    public static Boolean isStepLoggingEnabled() {
        try {
            return FS_SettingsUtil.isStepLoggingEnabled();
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, CLASS_NAME + ': Error checking step logging setting - ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Check if debug logging is enabled
     * @return Boolean indicating if debug logging is enabled
     */
    public static Boolean isDebugLoggingEnabled() {
        try {
            return FS_SettingsUtil.isDebugLoggingEnabled();
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, CLASS_NAME + ': Error checking debug logging setting - ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Wrapper class for flow step execution data
     */
    public class FlowStepData {
        public Decimal sequenceNumber;
        public String elementDeveloperName;
        public String elementLabel;
        public String elementType;
        public DateTime enteredAt;
        public DateTime exitedAt;
        public Decimal durationMillis;
        public Decimal cpuMillis;
        public Decimal soqlCount;
        public Decimal dmlCount;
        public String outcome;
        public String errorMessage;
        public String inputVariables;
        public String outputVariables;
        
        public FlowStepData() {
            // Default constructor
        }
        
        public FlowStepData(String elementDeveloperName, String elementType) {
            this.elementDeveloperName = elementDeveloperName;
            this.elementType = elementType;
            this.enteredAt = System.now();
        }
    }
    
    /**
     * @description Wrapper class for flow execution statistics
     */
    public class FlowExecutionStats {
        public Integer totalRuns = 0;
        public Integer uniqueUsers = 0;
        public Integer successfulRuns = 0;
        public Integer failedRuns = 0;
        public Decimal successRate = 0;
        public Decimal avgDuration = 0;
        public Decimal maxDuration = 0;
        public Decimal avgCpuTime = 0;
        public Decimal avgSoqlCount = 0;
        public Decimal avgDmlCount = 0;
    }
}