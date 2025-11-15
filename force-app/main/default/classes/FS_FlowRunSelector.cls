/**
 * @description Selector class for FS_Flow_Run__c object following selector pattern
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_FlowRunSelector {
    
    /**
     * @description Get flow runs by IDs
     * @param runIds Set of flow run IDs
     * @return List of flow run records
     */
    public static List<FS_Flow_Run__c> selectById(Set<Id> runIds) {
        if (runIds == null || runIds.isEmpty()) {
            return new List<FS_Flow_Run__c>();
        }
        
        return [
            SELECT Id, Name, Flow_API_Name__c, Flow_Label__c, Interview_ID__c,
                   Started_At__c, Completed_At__c, Status__c, Error_Message__c,
                   CPU_Time_Millis__c, SOQL_Count__c, DML_Count__c, 
                   Heap_Size_Bytes__c, Duration_Ms__c, Performance_Score__c,
                   Runtime_User__c, Performance_Alert__c,
                   CreatedDate, CreatedById, LastModifiedDate, LastModifiedById
            FROM FS_Flow_Run__c
            WHERE Id IN :runIds
            WITH SECURITY_ENFORCED
            ORDER BY Started_At__c DESC
        ];
    }
    
    /**
     * @description Get flow runs by Flow API Name
     * @param flowApiName Flow API name
     * @param daysPast Number of days to look back
     * @param limitCount Maximum number of records to return
     * @return List of flow run records
     */
    public static List<FS_Flow_Run__c> selectByFlowApiName(
        String flowApiName, 
        Integer daysPast, 
        Integer limitCount
    ) {
        DateTime startDate = System.now().addDays(-daysPast);
        
        return [
            SELECT Id, Name, Flow_API_Name__c, Flow_Label__c, Interview_ID__c,
                   Started_At__c, Completed_At__c, Status__c, Error_Message__c,
                   CPU_Time_Millis__c, SOQL_Count__c, DML_Count__c, 
                   Heap_Size_Bytes__c, Duration_Ms__c, Performance_Score__c,
                   Runtime_User__c, Performance_Alert__c
            FROM FS_Flow_Run__c
            WHERE Flow_API_Name__c = :flowApiName
            AND Started_At__c >= :startDate
            WITH SECURITY_ENFORCED
            ORDER BY Started_At__c DESC
            LIMIT :limitCount
        ];
    }
    
    /**
     * @description Get recent flow runs across all flows
     * @param daysPast Number of days to look back
     * @param limitCount Maximum number of records to return
     * @return List of flow run records
     */
    public static List<FS_Flow_Run__c> selectRecentRuns(Integer daysPast, Integer limitCount) {
        DateTime startDate = System.now().addDays(-daysPast);
        
        return [
            SELECT Id, Name, Flow_API_Name__c, Flow_Label__c, Interview_ID__c,
                   Started_At__c, Completed_At__c, Status__c, Error_Message__c,
                   CPU_Time_Millis__c, SOQL_Count__c, DML_Count__c, 
                   Heap_Size_Bytes__c, Duration_Ms__c, Performance_Score__c,
                   Runtime_User__c, Runtime_User__r.Name, Performance_Alert__c
            FROM FS_Flow_Run__c
            WHERE Started_At__c >= :startDate
            WITH SECURITY_ENFORCED
            ORDER BY Started_At__c DESC
            LIMIT :limitCount
        ];
    }
    
    /**
     * @description Get failed flow runs
     * @param daysPast Number of days to look back
     * @param limitCount Maximum number of records to return
     * @return List of failed flow run records
     */
    public static List<FS_Flow_Run__c> selectFailedRuns(Integer daysPast, Integer limitCount) {
        DateTime startDate = System.now().addDays(-daysPast);
        
        return [
            SELECT Id, Name, Flow_API_Name__c, Flow_Label__c, Interview_ID__c,
                   Started_At__c, Completed_At__c, Status__c, Error_Message__c,
                   CPU_Time_Millis__c, SOQL_Count__c, DML_Count__c, 
                   Heap_Size_Bytes__c, Duration_Ms__c, Runtime_User__c,
                   Runtime_User__r.Name
            FROM FS_Flow_Run__c
            WHERE Status__c = 'Failed'
            AND Started_At__c >= :startDate
            WITH SECURITY_ENFORCED
            ORDER BY Started_At__c DESC
            LIMIT :limitCount
        ];
    }
    
    /**
     * @description Get flow runs for archiving (older than retention days)
     * @param retentionDays Number of days to retain
     * @param limitCount Maximum number of records to return
     * @return List of flow run records for archiving
     */
    public static List<FS_Flow_Run__c> selectForArchiving(Integer retentionDays, Integer limitCount) {
        DateTime cutoffDate = System.now().addDays(-retentionDays);
        
        return [
            SELECT Id, Name, Flow_API_Name__c, Flow_Label__c, Interview_ID__c,
                   Started_At__c, Completed_At__c, Status__c, Error_Message__c,
                   CPU_Time_Millis__c, SOQL_Count__c, DML_Count__c, 
                   Heap_Size_Bytes__c, Duration_Ms__c, Performance_Score__c,
                   Runtime_User__c
            FROM FS_Flow_Run__c
            WHERE Started_At__c < :cutoffDate
            WITH SECURITY_ENFORCED
            ORDER BY Started_At__c ASC
            LIMIT :limitCount
        ];
    }
    
    /**
     * @description Get aggregate statistics by flow
     * @param daysPast Number of days to analyze
     * @return List of aggregate results
     */
    public static List<AggregateResult> selectAggregatesByFlow(Integer daysPast) {
        DateTime startDate = System.now().addDays(-daysPast);
        
        return [
            SELECT Flow_API_Name__c, Flow_Label__c,
                   COUNT(Id) execCount,
                   AVG(Duration_Ms__c) avgDuration,
                   AVG(CPU_Time_Millis__c) avgCpu,
                   AVG(SOQL_Count__c) avgSoql,
                   AVG(DML_Count__c) avgDml,
                   AVG(Performance_Score__c) avgScore,
                   MAX(Started_At__c) lastRun
            FROM FS_Flow_Run__c
            WHERE Started_At__c >= :startDate
            WITH SECURITY_ENFORCED
            GROUP BY Flow_API_Name__c, Flow_Label__c
            ORDER BY COUNT(Id) DESC
        ];
    }
    
    /**
     * @description Get list of flows for LWC components
     * @return List of flow information
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getFlowList() {
        List<AggregateResult> flowResults = [
            SELECT Flow_API_Name__c apiName,
                   Flow_Label__c label,
                   COUNT(Id) runCount
            FROM FS_Flow_Run__c
            WHERE Started_At__c = LAST_N_DAYS:90
            WITH SECURITY_ENFORCED
            GROUP BY Flow_API_Name__c, Flow_Label__c
            ORDER BY Flow_Label__c
            LIMIT 200
        ];
        
        List<Map<String, Object>> flows = new List<Map<String, Object>>();
        for (AggregateResult result : flowResults) {
            flows.add(new Map<String, Object>{
                'Id' => (String) result.get('apiName'),
                'FlowLabel' => (String) result.get('label'),
                'RunCount' => (Integer) result.get('runCount')
            });
        }
        
        return flows;
    }
}

