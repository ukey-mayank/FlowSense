/**
 * @description Selector class for FS_Flow_Change__c object following selector pattern
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_FlowChangeSelector {
    
    /**
     * @description Get flow changes by IDs
     * @param changeIds Set of flow change IDs
     * @return List of flow change records
     */
    public static List<FS_Flow_Change__c> selectById(Set<Id> changeIds) {
        if (changeIds == null || changeIds.isEmpty()) {
            return new List<FS_Flow_Change__c>();
        }
        
        return [
            SELECT Id, Name, Flow_API_Name__c, From_Version__c, To_Version__c,
                   Change_Summary__c, Snapshot_Data__c, Content_Hash__c,
                   Impact_Level__c, Analyzed_At__c,
                   CreatedDate, CreatedById, LastModifiedDate
            FROM FS_Flow_Change__c
            WHERE Id IN :changeIds
            WITH SECURITY_ENFORCED
            ORDER BY Analyzed_At__c DESC
        ];
    }
    
    /**
     * @description Get flow changes by Flow API Name
     * @param flowApiName Flow API name
     * @return List of flow change records
     */
    public static List<FS_Flow_Change__c> selectByFlowApiName(String flowApiName) {
        return [
            SELECT Id, Name, Flow_API_Name__c, From_Version__c, To_Version__c,
                   Change_Summary__c, Snapshot_Data__c, Content_Hash__c,
                   Impact_Level__c, Analyzed_At__c,
                   CreatedDate, CreatedById
            FROM FS_Flow_Change__c
            WHERE Flow_API_Name__c = :flowApiName
            WITH SECURITY_ENFORCED
            ORDER BY To_Version__c DESC, Analyzed_At__c DESC
        ];
    }
    
    /**
     * @description Get specific version comparison
     * @param flowApiName Flow API name
     * @param fromVersion Starting version
     * @param toVersion Ending version
     * @return Flow change record or null
     */
    public static FS_Flow_Change__c selectByVersions(
        String flowApiName, 
        Integer fromVersion, 
        Integer toVersion
    ) {
        List<FS_Flow_Change__c> changes = [
            SELECT Id, Name, Flow_API_Name__c, From_Version__c, To_Version__c,
                   Change_Summary__c, Snapshot_Data__c, Content_Hash__c,
                   Impact_Level__c, Analyzed_At__c
            FROM FS_Flow_Change__c
            WHERE Flow_API_Name__c = :flowApiName
            AND From_Version__c = :fromVersion
            AND To_Version__c = :toVersion
            WITH SECURITY_ENFORCED
            ORDER BY Analyzed_At__c DESC
            LIMIT 1
        ];
        
        return changes.isEmpty() ? null : changes[0];
    }
    
    /**
     * @description Get recent high-impact changes
     * @param daysPast Number of days to look back
     * @param limitCount Maximum number of records to return
     * @return List of high-impact change records
     */
    public static List<FS_Flow_Change__c> selectHighImpactChanges(
        Integer daysPast, 
        Integer limitCount
    ) {
        DateTime startDate = System.now().addDays(-daysPast);
        
        return [
            SELECT Id, Name, Flow_API_Name__c, From_Version__c, To_Version__c,
                   Change_Summary__c, Impact_Level__c, Analyzed_At__c
            FROM FS_Flow_Change__c
            WHERE Analyzed_At__c >= :startDate
            AND Impact_Level__c IN ('High', 'Critical')
            WITH SECURITY_ENFORCED
            ORDER BY Analyzed_At__c DESC
            LIMIT :limitCount
        ];
    }
    
    /**
     * @description Check if a change record exists by hash
     * @param contentHash Content hash to check
     * @return True if change record exists
     */
    public static Boolean existsByHash(String contentHash) {
        Integer count = [
            SELECT COUNT()
            FROM FS_Flow_Change__c
            WHERE Content_Hash__c = :contentHash
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        return count > 0;
    }
}

