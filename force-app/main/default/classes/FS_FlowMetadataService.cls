/**
 * @description Simplified service class for flow metadata retrieval
 * @author FlowSense
 * @version 1.0
 */
public without sharing class FS_FlowMetadataService {
    
    private static final String CLASS_NAME = 'FS_FlowMetadataService';
    
    /**
     * @description Get basic metadata for a flow
     * @param flowApiName API name of the flow
     * @param useCache Whether to use cached metadata (not implemented)
     * @return Flow metadata
     */
    public static FlowMetadata getFlowMetadata(String flowApiName, Boolean useCache) {
        System.debug(LoggingLevel.ERROR, 'FS_FlowMetadataService: Starting getFlowMetadata for: ' + flowApiName);
        try {
            FlowMetadata metadata = new FlowMetadata();
            metadata.apiName = flowApiName;
            
            // Get flow definition details
            List<FlowDefinitionView> flowDefs = [
                SELECT ApiName, Label, Description, DurableId, IsActive, 
                       ProcessType, TriggerType, ManageableState, LastModifiedDate
                FROM FlowDefinitionView 
                WHERE ApiName = :flowApiName 
                LIMIT 1
            ];
            
            if (!flowDefs.isEmpty()) {
                // Flow exists in the org
                FlowDefinitionView flowDef = flowDefs[0];
                metadata.exists = true;
                metadata.label = flowDef.Label;
                metadata.description = flowDef.Description;
                metadata.isActive = flowDef.IsActive;
                metadata.processType = flowDef.ProcessType;
                metadata.triggerType = flowDef.TriggerType;
                metadata.lastModifiedDate = flowDef.LastModifiedDate;
                metadata.durableId = flowDef.DurableId;
                
                // Set default values for version info
                metadata.activeVersionNumber = 1;
                metadata.totalVersions = 1;
                metadata.versionHistory = new List<FlowVersion>();
            } else {
                // Flow doesn't exist in FlowDefinitionView, but we can still check for execution data
                metadata.exists = false;
                metadata.label = flowApiName; // Use API name as label
                metadata.description = 'Flow execution data only';
                metadata.isActive = false;
                metadata.versionHistory = new List<FlowVersion>();
            }
            
            // Get flow statistics from our tracking objects regardless of whether flow definition exists
            getFlowStatistics(metadata);
            
            // If we found execution data but no flow definition, mark as having data
            if (!metadata.exists && metadata.totalExecutions > 0) {
                metadata.exists = true; // Mark as existing if we have execution data
                metadata.errorMessage = null;
            } else if (!metadata.exists && metadata.totalExecutions == 0) {
                metadata.errorMessage = 'Flow not found and no execution data: ' + flowApiName;
            }
            
            System.debug(LoggingLevel.INFO, CLASS_NAME + ': Retrieved metadata for ' + flowApiName);
            return metadata;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error getting flow metadata - ' + e.getMessage());
            
            FlowMetadata errorMetadata = new FlowMetadata();
            errorMetadata.apiName = flowApiName;
            errorMetadata.exists = false;
            errorMetadata.errorMessage = e.getMessage();
            return errorMetadata;
        }
    }
    
    /**
     * @description Get flow execution statistics
     * @param metadata Flow metadata to populate
     */
    private static void getFlowStatistics(FlowMetadata metadata) {
        try {
            // Get execution statistics from our Flow Run records
            DateTime last30Days = System.now().addDays(-30);
            
            System.debug('FS_FlowMetadataService: Querying stats for flow: ' + metadata.apiName + ' since: ' + last30Days);
            
            List<AggregateResult> stats = [
                SELECT COUNT(Id) totalRuns,
                       AVG(CPU_Time_Millis__c) avgCpuTime,
                       AVG(SOQL_Count__c) avgSoqlCount,
                       AVG(DML_Count__c) avgDmlCount,
                       AVG(Heap_Size_Bytes__c) avgHeapSize
                FROM FS_Flow_Run__c 
                WHERE Flow_API_Name__c = :metadata.apiName 
                AND Started_At__c >= :last30Days
            ];
            
            System.debug('FS_FlowMetadataService: Stats query returned: ' + stats.size() + ' results');
            if (!stats.isEmpty()) {
                System.debug('FS_FlowMetadataService: First result totalRuns: ' + stats[0].get('totalRuns'));
            }
            
            if (!stats.isEmpty()) {
                AggregateResult result = stats[0];
                Integer totalRuns = (Integer)result.get('totalRuns');
                
                if (totalRuns != null && totalRuns > 0) {
                    // Records exist - preserve null values from aggregates
                    metadata.totalExecutions = totalRuns;
                    metadata.avgCpuTime = (Decimal)result.get('avgCpuTime');
                    metadata.avgSoqlQueries = (Decimal)result.get('avgSoqlCount');
                    metadata.avgDmlStatements = (Decimal)result.get('avgDmlCount');
                    metadata.avgHeapSize = (Decimal)result.get('avgHeapSize');
                }
                // If totalRuns is 0 or null, keep the default values (0) from FlowMetadata initialization
            }
            
            // Get error statistics
            List<AggregateResult> errorStats = [
                SELECT COUNT(Id) errorCount
                FROM FS_Flow_Run__c 
                WHERE Flow_API_Name__c = :metadata.apiName 
                AND Started_At__c >= :last30Days
                AND Status__c = 'Failed'
            ];
            
            System.debug('FS_FlowMetadataService: Error stats query returned: ' + errorStats.size() + ' results');
            if (!errorStats.isEmpty()) {
                System.debug('FS_FlowMetadataService: Error count: ' + errorStats[0].get('errorCount'));
            }
            
            if (!errorStats.isEmpty() && errorStats[0].get('errorCount') != null) {
                metadata.errorCount = (Integer)errorStats[0].get('errorCount');
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, CLASS_NAME + ': Error getting flow statistics - ' + e.getMessage());
        }
    }
    
    /**
     * @description Flow metadata container class
     */
    public class FlowMetadata {
        public String apiName;
        public String label;
        public String description;
        public Boolean exists = false;
        public Boolean isActive = false;
        public String processType;
        public String triggerType;
        public String durableId;
        public String flowId;
        public Integer activeVersionNumber;
        public Integer totalVersions;
        public String status;
        public String apiVersion;
        public DateTime lastModifiedDate;
        public String lastModifiedBy;
        public List<FlowVersion> versionHistory;
        public String errorMessage;
        
        // Statistics
        public Integer totalExecutions = 0;
        public Integer errorCount = 0;
        public Decimal avgCpuTime = 0;
        public Decimal avgSoqlQueries = 0;
        public Decimal avgDmlStatements = 0;
        public Decimal avgHeapSize = 0;
        public Decimal complexityScore = 0;
    }
    
    /**
     * @description Flow version container class
     */
    public class FlowVersion {
        public Integer versionNumber;
        public String status;
        public DateTime lastModifiedDate;
        public String lastModifiedBy;
        public String description;
    }
}