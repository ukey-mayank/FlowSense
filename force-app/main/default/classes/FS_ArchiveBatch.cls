/**
 * @description Batch class for archiving old flow run data to Big Objects
 * @author FlowSense
 * @version 1.0
 */
public class FS_ArchiveBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private Integer retentionDays;
    private Integer totalProcessed = 0;
    private Integer totalArchived = 0;
    private Integer totalErrors = 0;
    
    /**
     * @description Constructor with retention days
     * @param retentionDays Number of days to retain in main objects
     */
    public FS_ArchiveBatch(Integer retentionDays) {
        this.retentionDays = retentionDays;
    }
    
    /**
     * @description Default constructor - uses retention from CMDT settings
     */
    public FS_ArchiveBatch() {
        this(FS_SettingsUtil.getRetentionDays());
    }
    
    /**
     * @description Start method to query old flow runs
     * @param bc Batch context
     * @return QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime cutoffDate = System.now().addDays(-retentionDays);
        
        return Database.getQueryLocator([
            SELECT Id, Name, Flow_API_Name__c, Flow_Label__c, Interview_ID__c,
                   Started_At__c, Completed_At__c, Status__c, Error_Message__c,
                   CPU_Time_Millis__c, SOQL_Count__c, DML_Count__c,
                   Heap_Size_Bytes__c, Duration_Ms__c, Performance_Score__c,
                   Runtime_User__c
            FROM FS_Flow_Run__c
            WHERE Started_At__c < :cutoffDate
            ORDER BY Started_At__c ASC
            LIMIT 50000
        ]);
    }
    
    /**
     * @description Execute method to process batch
     * @param bc Batch context
     * @param scope List of flow runs to archive
     */
    public void execute(Database.BatchableContext bc, List<FS_Flow_Run__c> scope) {
        List<FS_Flow_Run_Archive__b> archiveRecords = new List<FS_Flow_Run_Archive__b>();
        Set<Id> runIdsToDelete = new Set<Id>();
        Map<Id, String> runIdToInterviewId = new Map<Id, String>();
        
        // Create archive records
        for (FS_Flow_Run__c run : scope) {
            try {
                FS_Flow_Run_Archive__b archive = new FS_Flow_Run_Archive__b();
                archive.Flow_API_Name__c = truncate(run.Flow_API_Name__c, 40);
                archive.Started_At__c = run.Started_At__c;
                archive.Interview_ID__c = truncate(run.Interview_ID__c != null ? run.Interview_ID__c : 'unknown-' + run.Id, 40);
                archive.Flow_Label__c = truncate(run.Flow_Label__c, 255);
                archive.Completed_At__c = run.Completed_At__c;
                archive.Status__c = truncate(run.Status__c, 50);
                archive.Error_Message__c = truncate(run.Error_Message__c, 255);
                archive.CPU_Time_Millis__c = run.CPU_Time_Millis__c;
                archive.SOQL_Count__c = run.SOQL_Count__c;
                archive.DML_Count__c = run.DML_Count__c;
                archive.Heap_Size_Bytes__c = run.Heap_Size_Bytes__c;
                archive.Duration_Ms__c = run.Duration_Ms__c;
                archive.Performance_Score__c = run.Performance_Score__c;
                archive.Runtime_User_Id__c = run.Runtime_User__c;
                archive.Original_Record_Id__c = run.Id;
                archive.Archived_At__c = System.now();
                
                archiveRecords.add(archive);
                runIdsToDelete.add(run.Id);
                runIdToInterviewId.put(run.Id, run.Interview_ID__c);
                
                totalProcessed++;
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'FS_ArchiveBatch: Error creating archive record - ' + e.getMessage());
                totalErrors++;
            }
        }
        
        // Insert archive records
        if (!archiveRecords.isEmpty()) {
            List<Database.SaveResult> results = Database.insertImmediate(archiveRecords);
            
            Set<Id> successfulArchives = new Set<Id>();
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess()) {
                    successfulArchives.add(scope[i].Id);
                    totalArchived++;
                } else {
                    System.debug(LoggingLevel.ERROR, 'FS_ArchiveBatch: Error archiving run - ' + 
                               results[i].getErrors()[0].getMessage());
                    totalErrors++;
                }
            }
            
            // Archive related steps
            if (!successfulArchives.isEmpty()) {
                archiveSteps(successfulArchives, runIdToInterviewId);
                
                // Delete original records
                List<FS_Flow_Run__c> toDelete = [
                    SELECT Id 
                    FROM FS_Flow_Run__c 
                    WHERE Id IN :successfulArchives
                ];
                
                Database.delete(toDelete, false);
            }
        }
    }
    
    /**
     * @description Archive related flow steps
     * @param runIds Set of archived run IDs
     * @param runIdToInterviewId Map of run ID to interview ID
     */
    private void archiveSteps(Set<Id> runIds, Map<Id, String> runIdToInterviewId) {
        List<FS_Flow_Step__c> steps = [
            SELECT Id, Flow_Run__c, Sequence_Number__c,
                   Element_Developer_Name__c, Element_Label__c, Element_Type__c,
                   Entered_At__c, Exited_At__c, Duration_Millis__c,
                   CPU_Millis__c, SOQL_Count__c, DML_Count__c,
                   Outcome__c, Error_Message__c
            FROM FS_Flow_Step__c
            WHERE Flow_Run__c IN :runIds
            LIMIT 10000
        ];
        
        if (steps.isEmpty()) {
            return;
        }
        
        List<FS_Flow_Step_Archive__b> stepArchives = new List<FS_Flow_Step_Archive__b>();
        
        for (FS_Flow_Step__c step : steps) {
            FS_Flow_Step_Archive__b archive = new FS_Flow_Step_Archive__b();
            String interviewId = runIdToInterviewId.get(step.Flow_Run__c);
            archive.Interview_ID__c = truncate(interviewId != null ? interviewId : 'unknown-' + step.Flow_Run__c, 40);
            archive.Sequence_Number__c = step.Sequence_Number__c != null ? step.Sequence_Number__c : 0;
            archive.Entered_At__c = step.Entered_At__c != null ? step.Entered_At__c : System.now();
            archive.Flow_Run_Id__c = step.Flow_Run__c;
            archive.Element_Developer_Name__c = truncate(step.Element_Developer_Name__c, 255);
            archive.Element_Label__c = truncate(step.Element_Label__c, 255);
            archive.Element_Type__c = truncate(step.Element_Type__c, 100);
            archive.Exited_At__c = step.Exited_At__c;
            archive.Duration_Millis__c = step.Duration_Millis__c;
            archive.CPU_Millis__c = step.CPU_Millis__c;
            archive.SOQL_Count__c = step.SOQL_Count__c;
            archive.DML_Count__c = step.DML_Count__c;
            archive.Outcome__c = truncate(step.Outcome__c, 255);
            archive.Error_Message__c = truncate(step.Error_Message__c, 255);
            archive.Original_Record_Id__c = step.Id;
            archive.Archived_At__c = System.now();
            
            stepArchives.add(archive);
        }
        
        if (!stepArchives.isEmpty()) {
            Database.insertImmediate(stepArchives);
        }
    }
    
    /**
     * @description Truncate string to max length
     * @param text Text to truncate
     * @param maxLength Maximum length
     * @return Truncated text
     */
    private String truncate(String text, Integer maxLength) {
        if (String.isBlank(text)) {
            return text;
        }
        
        if (text.length() <= maxLength) {
            return text;
        }
        
        return text.substring(0, maxLength);
    }
    
    /**
     * @description Finish method to send summary
     * @param bc Batch context
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('FS_ArchiveBatch completed:');
        System.debug('- Total Processed: ' + totalProcessed);
        System.debug('- Total Archived: ' + totalArchived);
        System.debug('- Total Errors: ' + totalErrors);
        
        // Could send summary email here if needed
    }
}

