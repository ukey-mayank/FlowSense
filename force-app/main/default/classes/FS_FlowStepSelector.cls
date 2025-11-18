/**
 * @description Selector class for FS_Flow_Step__c object following selector pattern
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_FlowStepSelector {
    
    /**
     * @description Get flow steps by Flow Run IDs
     * @param flowRunIds Set of flow run IDs
     * @return List of flow step records
     */
    public static List<FS_Flow_Step__c> selectByFlowRunId(Set<Id> flowRunIds) {
        if (flowRunIds == null || flowRunIds.isEmpty()) {
            return new List<FS_Flow_Step__c>();
        }
        
        return [
            SELECT Id, Name, Flow_Run__c, Sequence_Number__c,
                   Element_Developer_Name__c, Element_Label__c, Element_Type__c,
                   Entered_At__c, Exited_At__c, Duration_Millis__c,
                   CPU_Millis__c, SOQL_Count__c, DML_Count__c,
                   Outcome__c, Error_Message__c,
                   Input_Variables__c, Output_Variables__c
            FROM FS_Flow_Step__c
            WHERE Flow_Run__c IN :flowRunIds
            WITH SECURITY_ENFORCED
            ORDER BY Flow_Run__c, Sequence_Number__c ASC
        ];
    }
    
    /**
     * @description Get flow steps by single Flow Run ID
     * @param flowRunId Flow run ID
     * @return List of flow step records
     */
    public static List<FS_Flow_Step__c> selectByFlowRun(Id flowRunId) {
        return selectByFlowRunId(new Set<Id>{ flowRunId });
    }
    
    /**
     * @description Get slowest steps across all flows
     * @param daysPast Number of days to analyze
     * @param limitCount Maximum number of records to return
     * @return List of slowest flow step records
     */
    public static List<FS_Flow_Step__c> selectSlowestSteps(Integer daysPast, Integer limitCount) {
        DateTime startDate = System.now().addDays(-daysPast);
        
        return [
            SELECT Id, Name, Flow_Run__c, Flow_Run__r.Flow_API_Name__c,
                   Flow_Run__r.Flow_Label__c, Sequence_Number__c,
                   Element_Developer_Name__c, Element_Label__c, Element_Type__c,
                   Entered_At__c, Exited_At__c, Duration_Millis__c,
                   CPU_Millis__c, SOQL_Count__c, DML_Count__c
            FROM FS_Flow_Step__c
            WHERE Flow_Run__r.Started_At__c >= :startDate
            AND Duration_Millis__c != null
            WITH SECURITY_ENFORCED
            ORDER BY Duration_Millis__c DESC
            LIMIT :limitCount
        ];
    }
    
    /**
     * @description Get steps with errors
     * @param daysPast Number of days to analyze
     * @param limitCount Maximum number of records to return
     * @return List of error step records
     */
    public static List<FS_Flow_Step__c> selectStepsWithErrors(Integer daysPast, Integer limitCount) {
        DateTime startDate = System.now().addDays(-daysPast);
        
        // Note: Error_Message__c is LongTextArea and cannot be filtered in WHERE clause
        // Filter in Apex instead
        List<FS_Flow_Step__c> allSteps = [
            SELECT Id, Name, Flow_Run__c, Flow_Run__r.Flow_API_Name__c,
                   Flow_Run__r.Flow_Label__c, Sequence_Number__c,
                   Element_Developer_Name__c, Element_Label__c, Element_Type__c,
                   Entered_At__c, Error_Message__c
            FROM FS_Flow_Step__c
            WHERE Flow_Run__r.Started_At__c >= :startDate
            WITH SECURITY_ENFORCED
            ORDER BY Entered_At__c DESC
            LIMIT 10000
        ];
        
        // Filter for steps with errors
        List<FS_Flow_Step__c> stepsWithErrors = new List<FS_Flow_Step__c>();
        for (FS_Flow_Step__c step : allSteps) {
            if (String.isNotBlank(step.Error_Message__c)) {
                stepsWithErrors.add(step);
                if (stepsWithErrors.size() >= limitCount) {
                    break;
                }
            }
        }
        
        return stepsWithErrors;
    }
    
    /**
     * @description Get aggregate statistics by element type
     * @param flowRunIds Set of flow run IDs to analyze
     * @return List of aggregate results
     */
    public static List<AggregateResult> selectAggregatesByElementType(Set<Id> flowRunIds) {
        if (flowRunIds == null || flowRunIds.isEmpty()) {
            return new List<AggregateResult>();
        }
        
        return [
            SELECT Element_Type__c,
                   COUNT(Id) stepCount,
                   AVG(Duration_Millis__c) avgDuration,
                   MAX(Duration_Millis__c) maxDuration,
                   AVG(CPU_Millis__c) avgCpu,
                   SUM(SOQL_Count__c) totalSoql,
                   SUM(DML_Count__c) totalDml
            FROM FS_Flow_Step__c
            WHERE Flow_Run__c IN :flowRunIds
            WITH SECURITY_ENFORCED
            GROUP BY Element_Type__c
            ORDER BY AVG(Duration_Millis__c) DESC
        ];
    }
    
    /**
     * @description Get flow steps by single Flow Run ID for LWC wire services
     * @param flowRunId Single flow run ID
     * @return List of flow step records
     */
    @AuraEnabled(cacheable=true)
    public static List<FS_Flow_Step__c> selectByFlowRunId(Id flowRunId) {
        if (flowRunId == null) {
            return new List<FS_Flow_Step__c>();
        }
        
        return selectByFlowRunId(new Set<Id>{flowRunId});
    }
    
    /**
     * @description Get flow performance data for heatmap visualization
     * @param days Number of days to analyze
     * @param flowType Flow type filter
     * @param searchTerm Search term for flow names
     * @return Performance data wrapper
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFlowPerformanceData(Integer days, String flowType, String searchTerm) {
        DateTime startDate = System.now().addDays(-days);
        
        try {
            // Use a simpler approach that aggregates from Flow Runs directly
            // since relationship queries in dynamic SOQL can cause permission issues
            List<AggregateResult> perfResults;
            
            if (String.isNotBlank(searchTerm)) {
                String searchPattern = '%' + searchTerm + '%';
                perfResults = [
                    SELECT Flow_API_Name__c flowName, 
                           COUNT(Id) totalRuns,
                           AVG(Duration_Millis__c) avgDuration,
                           AVG(CPU_Time_Millis__c) avgCpu,
                           AVG(SOQL_Count__c) avgSoql,
                           AVG(DML_Count__c) avgDml
                    FROM FS_Flow_Run__c 
                    WHERE Started_At__c >= :startDate
                    AND Flow_API_Name__c LIKE :searchPattern
                    AND Duration_Millis__c != null
                    WITH SECURITY_ENFORCED
                    GROUP BY Flow_API_Name__c 
                    ORDER BY AVG(Duration_Millis__c) DESC 
                    LIMIT 100
                ];
            } else {
                perfResults = [
                    SELECT Flow_API_Name__c flowName, 
                           COUNT(Id) totalRuns,
                           AVG(Duration_Millis__c) avgDuration,
                           AVG(CPU_Time_Millis__c) avgCpu,
                           AVG(SOQL_Count__c) avgSoql,
                           AVG(DML_Count__c) avgDml
                    FROM FS_Flow_Run__c 
                    WHERE Started_At__c >= :startDate
                    AND Duration_Millis__c != null
                    WITH SECURITY_ENFORCED
                    GROUP BY Flow_API_Name__c 
                    ORDER BY AVG(Duration_Millis__c) DESC 
                    LIMIT 100
                ];
            }
            
            List<Map<String, Object>> flowData = new List<Map<String, Object>>();
            Integer criticalFlows = 0, warningFlows = 0, healthyFlows = 0;
            Decimal totalPerf = 0;
            
            for (AggregateResult result : perfResults) {
                Decimal avgDuration = (Decimal) result.get('avgDuration');
                if (avgDuration == null) continue;
                
                Map<String, Object> flowInfo = new Map<String, Object>{
                    'Id' => (String) result.get('flowName'),
                    'FlowName' => (String) result.get('flowName'), // Use API name since Flow_Label__c might not be accessible
                    'AverageDuration' => avgDuration.intValue(),
                    'TotalRuns' => (Integer) result.get('totalRuns'),
                    'AverageCpuTime' => ((Decimal) result.get('avgCpu'))?.intValue(),
                    'AverageSoqlQueries' => ((Decimal) result.get('avgSoql'))?.intValue(),
                    'AverageDmlStatements' => ((Decimal) result.get('avgDml'))?.intValue(),
                    'ErrorRate' => 0.0
                };
                
                if (avgDuration > 30000) criticalFlows++;
                else if (avgDuration > 5000) warningFlows++;
                else healthyFlows++;
                
                totalPerf += avgDuration;
                flowData.add(flowInfo);
            }
            
            return new Map<String, Object>{
                'flowData' => flowData,
                'criticalFlows' => criticalFlows,
                'warningFlows' => warningFlows,
                'healthyFlows' => healthyFlows,
                'averagePerformance' => perfResults.isEmpty() ? 0 : (totalPerf / perfResults.size()).intValue()
            };
            
        } catch (Exception e) {
            System.debug('Error in getFlowPerformanceData: ' + e.getMessage());
            // Return empty but valid structure
            return new Map<String, Object>{
                'flowData' => new List<Map<String, Object>>(),
                'criticalFlows' => 0,
                'warningFlows' => 0,
                'healthyFlows' => 0,
                'averagePerformance' => 0
            };
        }
    }
    
    /**
     * @description Get flow trend data for performance charts
     * @param flowId Flow identifier
     * @param days Number of days to analyze
     * @return List of trend data points
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getFlowTrendData(String flowId, Integer days) {
        DateTime startDate = System.now().addDays(-days);
        
        List<AggregateResult> trendResults = [
            SELECT DAY_ONLY(Flow_Run__r.Started_At__c) runDate,
                   AVG(Duration_Millis__c) avgDuration
            FROM FS_Flow_Step__c
            WHERE Flow_Run__r.Flow_API_Name__c = :flowId
            AND Flow_Run__r.Started_At__c >= :startDate
            AND Duration_Millis__c != null
            WITH SECURITY_ENFORCED
            GROUP BY DAY_ONLY(Flow_Run__r.Started_At__c)
            ORDER BY DAY_ONLY(Flow_Run__r.Started_At__c)
        ];
        
        List<Map<String, Object>> trendData = new List<Map<String, Object>>();
        for (AggregateResult result : trendResults) {
            trendData.add(new Map<String, Object>{
                'date' => String.valueOf(result.get('runDate')),
                'averageDuration' => ((Decimal) result.get('avgDuration')).intValue()
            });
        }
        
        return trendData;
    }
}

