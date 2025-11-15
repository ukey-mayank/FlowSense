/**
 * @description Domain class for FS_Flow_Run__c business logic
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_FlowRunDomain {
    
    /**
     * @description Validate flow run records before insert
     * @param flowRuns List of flow run records
     */
    public static void validateBeforeInsert(List<FS_Flow_Run__c> flowRuns) {
        for (FS_Flow_Run__c run : flowRuns) {
            // Validate required fields
            if (String.isBlank(run.Flow_API_Name__c)) {
                run.addError('Flow API Name is required');
            }
            
            if (String.isBlank(run.Interview_ID__c)) {
                run.addError('Interview ID is required');
            }
            
            if (run.Started_At__c == null) {
                run.Started_At__c = System.now();
            }
            
            if (String.isBlank(run.Status__c)) {
                run.Status__c = 'Success';
            }
        }
    }
    
    /**
     * @description Calculate performance score for flow runs
     * @param flowRuns List of flow run records
     */
    public static void calculatePerformanceScore(List<FS_Flow_Run__c> flowRuns) {
        for (FS_Flow_Run__c run : flowRuns) {
            Decimal score = 100;
            
            // CPU penalty
            if (run.CPU_Time_Millis__c != null) {
                if (run.CPU_Time_Millis__c > 10000) {
                    score -= 30;
                } else if (run.CPU_Time_Millis__c > 5000) {
                    score -= 15;
                }
            }
            
            // SOQL penalty
            if (run.SOQL_Count__c != null) {
                if (run.SOQL_Count__c > 90) {
                    score -= 25;
                } else if (run.SOQL_Count__c > 50) {
                    score -= 10;
                }
            }
            
            // DML penalty
            if (run.DML_Count__c != null) {
                if (run.DML_Count__c > 140) {
                    score -= 25;
                } else if (run.DML_Count__c > 100) {
                    score -= 10;
                }
            }
            
            // Duration penalty
            if (run.Duration_Ms__c != null) {
                if (run.Duration_Ms__c > 30000) {
                    score -= 20;
                } else if (run.Duration_Ms__c > 10000) {
                    score -= 10;
                }
            }
            
            run.Performance_Score__c = Math.max(0, score);
            
            // Set performance alert flag
            run.Performance_Alert__c = (score < 70);
        }
    }
    
    /**
     * @description Calculate duration for completed runs
     * @param flowRuns List of flow run records
     */
    public static void calculateDuration(List<FS_Flow_Run__c> flowRuns) {
        for (FS_Flow_Run__c run : flowRuns) {
            if (run.Started_At__c != null && run.Completed_At__c != null) {
                Long duration = run.Completed_At__c.getTime() - run.Started_At__c.getTime();
                run.Duration_Ms__c = duration;
            }
        }
    }
    
    /**
     * @description Archive old flow runs to Big Objects
     * @param flowRuns List of flow run records to archive
     * @return Number of successfully archived records
     */
    public static Integer archiveRuns(List<FS_Flow_Run__c> flowRuns) {
        // This will be implemented when Big Objects are created
        // For now, just return count
        return flowRuns.size();
    }
    
    /**
     * @description Enrich flow runs with additional context
     * @param flowRuns List of flow run records
     */
    public static void enrichWithContext(List<FS_Flow_Run__c> flowRuns) {
        // Get flow metadata if labels are missing
        Set<String> flowApiNames = new Set<String>();
        for (FS_Flow_Run__c run : flowRuns) {
            if (String.isBlank(run.Flow_Label__c)) {
                flowApiNames.add(run.Flow_API_Name__c);
            }
        }
        
        if (!flowApiNames.isEmpty()) {
            Map<String, String> flowLabels = getFlowLabels(flowApiNames);
            for (FS_Flow_Run__c run : flowRuns) {
                if (String.isBlank(run.Flow_Label__c) && flowLabels.containsKey(run.Flow_API_Name__c)) {
                    run.Flow_Label__c = flowLabels.get(run.Flow_API_Name__c);
                }
            }
        }
    }
    
    /**
     * @description Get flow labels from metadata
     * @param flowApiNames Set of flow API names
     * @return Map of API name to label
     */
    private static Map<String, String> getFlowLabels(Set<String> flowApiNames) {
        Map<String, String> labels = new Map<String, String>();
        
        try {
            List<FlowDefinitionView> flows = [
                SELECT ApiName, Label
                FROM FlowDefinitionView
                WHERE ApiName IN :flowApiNames
            ];
            
            for (FlowDefinitionView flow : flows) {
                labels.put(flow.ApiName, flow.Label);
            }
        } catch (Exception e) {
            System.debug('Error fetching flow labels: ' + e.getMessage());
        }
        
        return labels;
    }
}

