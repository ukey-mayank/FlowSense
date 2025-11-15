/**
 * @description Test class for FS_SettingsUtil
 * @author FlowSense
 * @version 1.0
 * TEMPORARY VERSION - Simplified tests during CMDT migration
 */
@isTest
private class FS_SettingsUtilTest {
    
    @isTest
    static void testGetRetentionDays() {
        Test.startTest();
        Integer retentionDays = FS_SettingsUtil.getRetentionDays();
        Test.stopTest();
        
        System.assertEquals(90, retentionDays, 'Should return default retention days');
    }
    
    @isTest
    static void testGetArchiveRetentionDays() {
        Test.startTest();
        Integer archiveDays = FS_SettingsUtil.getArchiveRetentionDays();
        Test.stopTest();
        
        System.assertEquals(365, archiveDays, 'Should return default archive retention days');
    }
    
    @isTest
    static void testGetCPUWarningThreshold() {
        Test.startTest();
        Integer cpuWarning = FS_SettingsUtil.getCPUWarningThreshold();
        Test.stopTest();
        
        System.assertEquals(5000, cpuWarning, 'Should return default CPU warning threshold');
    }
    
    @isTest
    static void testGetCPUCriticalThreshold() {
        Test.startTest();
        Integer cpuCritical = FS_SettingsUtil.getCPUCriticalThreshold();
        Test.stopTest();
        
        System.assertEquals(10000, cpuCritical, 'Should return default CPU critical threshold');
    }
    
    @isTest
    static void testGetBatchSize() {
        Test.startTest();
        Integer batchSize = FS_SettingsUtil.getBatchSize();
        Test.stopTest();
        
        System.assertEquals(200, batchSize, 'Should return default batch size');
    }
    
    @isTest
    static void testIsErrorAlertsEnabled() {
        Test.startTest();
        Boolean isEnabled = FS_SettingsUtil.isErrorAlertsEnabled();
        Test.stopTest();
        
        System.assertEquals(true, isEnabled, 'Error alerts should be enabled by default');
    }
    
    @isTest
    static void testClearCache() {
        Test.startTest();
        FS_SettingsUtil.clearCache();
        Test.stopTest();
        
        // No assertions needed - just verify method doesn't throw exception
    }
}
