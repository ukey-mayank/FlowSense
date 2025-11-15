/**
 * @description Selector class for Flow definitions used by LWC components
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_FlowSelector {
    
    /**
     * @description Get list of flows for LWC components
     * @return List of flow information
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getFlowList() {
        // Get flow information from flow runs to show only monitored flows
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