/**
 * @description Schedulable class for running data cleanup jobs
 * @author FlowSense
 * @version 1.0
 */
public class FS_DataCleanupSchedulable implements Schedulable {
    
    private String jobType;
    private Integer retentionDays;
    
    /**
     * @description Constructor
     * @param jobType Type of cleanup job ('ARCHIVE' or 'RETENTION')
     * @param retentionDays Number of days for retention
     */
    public FS_DataCleanupSchedulable(String jobType, Integer retentionDays) {
        this.jobType = jobType;
        this.retentionDays = retentionDays;
    }
    
    /**
     * @description Default constructor for archive job - uses CMDT settings
     */
    public FS_DataCleanupSchedulable() {
        this('ARCHIVE', FS_SettingsUtil.getRetentionDays());
    }
    
    /**
     * @description Execute method called by scheduler
     * @param sc Schedulable context
     */
    public void execute(SchedulableContext sc) {
        if (jobType == 'ARCHIVE') {
            // Run archive batch
            FS_ArchiveBatch batch = new FS_ArchiveBatch(retentionDays);
            Database.executeBatch(batch, 200);
        } else if (jobType == 'RETENTION') {
            // Run retention cleanup batch
            FS_RetentionBatch batch = new FS_RetentionBatch(retentionDays);
            Database.executeBatch(batch, 200);
        }
    }
    
    /**
     * @description Schedule archive job to run daily
     * @param retentionDays Days to retain in main objects (optional, uses CMDT if null)
     * @return Scheduled job ID
     */
    public static String scheduleArchiveJob(Integer retentionDays) {
        Integer days = retentionDays != null ? retentionDays : FS_SettingsUtil.getRetentionDays();
        FS_DataCleanupSchedulable job = new FS_DataCleanupSchedulable('ARCHIVE', days);
        // Run daily at 2 AM
        String cronExp = '0 0 2 * * ?';
        return System.schedule('FlowSense Archive Job', cronExp, job);
    }
    
    /**
     * @description Schedule archive job with default CMDT settings
     * @return Scheduled job ID
     */
    public static String scheduleArchiveJob() {
        return scheduleArchiveJob(null);
    }
    
    /**
     * @description Schedule retention cleanup job to run weekly
     * @param archiveRetentionDays Days to retain in archive (optional, uses CMDT if null)
     * @return Scheduled job ID
     */
    public static String scheduleRetentionJob(Integer archiveRetentionDays) {
        Integer days = archiveRetentionDays != null ? archiveRetentionDays : FS_SettingsUtil.getArchiveRetentionDays();
        FS_DataCleanupSchedulable job = new FS_DataCleanupSchedulable('RETENTION', days);
        // Run weekly on Sunday at 3 AM
        String cronExp = '0 0 3 ? * SUN';
        return System.schedule('FlowSense Retention Cleanup Job', cronExp, job);
    }
    
    /**
     * @description Schedule retention job with default CMDT settings
     * @return Scheduled job ID
     */
    public static String scheduleRetentionJob() {
        return scheduleRetentionJob(null);
    }
    
    /**
     * @description Abort all scheduled cleanup jobs
     */
    public static void abortAllCleanupJobs() {
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE 'FlowSense%Job'
        ];
        
        for (CronTrigger job : jobs) {
            System.abortJob(job.Id);
        }
    }
}

