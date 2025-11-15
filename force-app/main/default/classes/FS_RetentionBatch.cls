/**
 * @description Batch class for cleaning up old archived data based on retention policy
 * @author FlowSense
 * @version 1.0
 */
public class FS_RetentionBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private Integer archiveRetentionDays;
    private Integer totalDeleted = 0;
    private Integer totalErrors = 0;
    
    /**
     * @description Constructor with archive retention days
     * @param archiveRetentionDays Number of days to retain in archive
     */
    public FS_RetentionBatch(Integer archiveRetentionDays) {
        this.archiveRetentionDays = archiveRetentionDays;
    }
    
    /**
     * @description Default constructor - uses archive retention from CMDT settings
     */
    public FS_RetentionBatch() {
        this(FS_SettingsUtil.getArchiveRetentionDays());
    }
    
    /**
     * @description Start method to query old archive records
     * @param bc Batch context
     * @return QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime cutoffDate = System.now().addDays(-archiveRetentionDays);
        
        // Query old archived runs
        // Note: Big Object queries are limited, this is a simplified example
        return Database.getQueryLocator([
            SELECT Flow_API_Name__c, Started_At__c, Interview_ID__c
            FROM FS_Flow_Run_Archive__b
            WHERE Started_At__c < :cutoffDate
            LIMIT 10000
        ]);
    }
    
    /**
     * @description Execute method to process batch
     * @param bc Batch context
     * @param scope List of archive records to delete
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // For Big Objects, deletion would need to be handled differently
        // This is a placeholder showing the structure
        
        try {
            // Delete old archives
            // Note: In real implementation, Big Object deletions have specific requirements
            Database.DeleteResult[] results = Database.delete(scope, false);
            
            for (Database.DeleteResult result : results) {
                if (result.isSuccess()) {
                    totalDeleted++;
                } else {
                    totalErrors++;
                    System.debug(LoggingLevel.ERROR, 'FS_RetentionBatch: Error deleting - ' + 
                               result.getErrors()[0].getMessage());
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'FS_RetentionBatch: Error in execute - ' + e.getMessage());
            totalErrors++;
        }
    }
    
    /**
     * @description Finish method to send summary
     * @param bc Batch context
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('FS_RetentionBatch completed:');
        System.debug('- Total Deleted: ' + totalDeleted);
        System.debug('- Total Errors: ' + totalErrors);
    }
}

