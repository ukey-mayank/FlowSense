/**
 * @description Utility class for accessing FlowSense Settings from Custom Metadata
 * @author FlowSense
 * @version 2.0
 */
public with sharing class FS_SettingsUtil {
    
    private static FS_Global_Settings__mdt cachedSettings;
    private static Map<String, FS_Integration_Channel__mdt> cachedChannels;
    private static Map<String, FS_AI_Settings__mdt> cachedAISettings;
    
    /**
     * @description Get global settings (cached)
     * @return Global settings Custom Metadata record
     */
    public static FS_Global_Settings__mdt getGlobalSettings() {
        if (cachedSettings == null) {
            List<FS_Global_Settings__mdt> settings = [
                SELECT Id, DeveloperName, Label,
                       Retention_Days__c, Archive_Retention_Days__c,
                       CPU_Warning_Threshold_Ms__c, CPU_Critical_Threshold_Ms__c,
                       SOQL_Warning_Threshold__c, SOQL_Critical_Threshold__c,
                       DML_Warning_Threshold__c, DML_Critical_Threshold__c,
                       Enable_Error_Alerts__c, Enable_Step_Logging__c,
                       Enable_Debug_Logging__c, Enable_CPU_Monitoring__c,
                       Enable_Async_Processing__c, Batch_Size__c,
                       Max_Runs_To_Retain__c, Step_Logging_Sample_Rate__c,
                       Auto_Generate_Documentation__c, Documentation_Template__c
                FROM FS_Global_Settings__mdt
                WHERE DeveloperName = 'Default'
                LIMIT 1
            ];
            cachedSettings = settings.isEmpty() ? null : settings[0];
        }
        return cachedSettings;
    }
    
    /**
     * @description Get integration channel settings by type
     * @param channelType Type of channel (Email, Slack, Teams, etc.)
     * @return Integration channel Custom Metadata record
     */
    public static FS_Integration_Channel__mdt getIntegrationChannel(String channelType) {
        if (cachedChannels == null) {
            cachedChannels = new Map<String, FS_Integration_Channel__mdt>();
            List<FS_Integration_Channel__mdt> channels = [
                SELECT Id, DeveloperName, Label, Channel_Type__c,
                       Active__c, Auth_Type__c, Named_Credential__c,
                       Webhook_URL__c, Timeout_Seconds__c, Max_Retry_Attempts__c,
                       Slack_Channel__c, Slack_Token__c,
                       Teams_Webhook__c,
                       WhatsApp_Endpoint__c, WhatsApp_Phone_Number__c
                FROM FS_Integration_Channel__mdt
                WHERE Active__c = true
            ];
            for (FS_Integration_Channel__mdt channel : channels) {
                cachedChannels.put(channel.Channel_Type__c, channel);
            }
        }
        return cachedChannels.get(channelType);
    }
    
    /**
     * @description Get AI settings
     * @return AI settings Custom Metadata record
     */
    public static FS_AI_Settings__mdt getAISettings() {
        if (cachedAISettings == null || cachedAISettings.isEmpty()) {
            cachedAISettings = new Map<String, FS_AI_Settings__mdt>();
            List<FS_AI_Settings__mdt> aiSettings = [
                SELECT Id, DeveloperName, Label, Provider__c,
                       Model__c, Named_Credential__c, Active__c,
                       Max_Tokens__c, Temperature__c,
                       Enable_Flow_Explanation__c, Enable_Formula_Generation__c,
                       Enable_Test_Generation__c, Enable_Optimization_Hints__c
                FROM FS_AI_Settings__mdt
                WHERE Active__c = true
                LIMIT 1
            ];
            for (FS_AI_Settings__mdt aiSetting : aiSettings) {
                cachedAISettings.put(aiSetting.DeveloperName, aiSetting);
            }
        }
        return cachedAISettings.isEmpty() ? null : cachedAISettings.values()[0];
    }
    
    // Convenience getter methods
    
    public static Integer getRetentionDays() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.Retention_Days__c != null 
            ? Integer.valueOf(settings.Retention_Days__c) 
            : 90;
    }
    
    public static Integer getArchiveRetentionDays() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.Archive_Retention_Days__c != null 
            ? Integer.valueOf(settings.Archive_Retention_Days__c) 
            : 365;
    }
    
    public static Integer getCPUWarningThreshold() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.CPU_Warning_Threshold_Ms__c != null 
            ? Integer.valueOf(settings.CPU_Warning_Threshold_Ms__c) 
            : 5000;
    }
    
    public static Integer getCPUCriticalThreshold() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.CPU_Critical_Threshold_Ms__c != null 
            ? Integer.valueOf(settings.CPU_Critical_Threshold_Ms__c) 
            : 10000;
    }
    
    public static Integer getSOQLWarningThreshold() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.SOQL_Warning_Threshold__c != null 
            ? Integer.valueOf(settings.SOQL_Warning_Threshold__c) 
            : 50;
    }
    
    public static Integer getSOQLCriticalThreshold() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.SOQL_Critical_Threshold__c != null 
            ? Integer.valueOf(settings.SOQL_Critical_Threshold__c) 
            : 90;
    }
    
    public static Integer getDMLWarningThreshold() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.DML_Warning_Threshold__c != null 
            ? Integer.valueOf(settings.DML_Warning_Threshold__c) 
            : 100;
    }
    
    public static Integer getDMLCriticalThreshold() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.DML_Critical_Threshold__c != null 
            ? Integer.valueOf(settings.DML_Critical_Threshold__c) 
            : 140;
    }
    
    public static Boolean isErrorAlertsEnabled() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.Enable_Error_Alerts__c != null 
            ? settings.Enable_Error_Alerts__c 
            : true;
    }
    
    public static Boolean isStepLoggingEnabled() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.Enable_Step_Logging__c != null 
            ? settings.Enable_Step_Logging__c 
            : false;
    }
    
    public static Boolean isDebugLoggingEnabled() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.Enable_Debug_Logging__c != null 
            ? settings.Enable_Debug_Logging__c 
            : false;
    }
    
    public static Boolean isCPUMonitoringEnabled() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.Enable_CPU_Monitoring__c != null 
            ? settings.Enable_CPU_Monitoring__c 
            : true;
    }
    
    public static Boolean isAsyncProcessingEnabled() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.Enable_Async_Processing__c != null 
            ? settings.Enable_Async_Processing__c 
            : true;
    }
    
    public static Integer getBatchSize() {
        FS_Global_Settings__mdt settings = getGlobalSettings();
        return settings != null && settings.Batch_Size__c != null 
            ? Integer.valueOf(settings.Batch_Size__c) 
            : 200;
    }
    
    /**
     * @description Clear cached settings (for testing)
     */
    @TestVisible
    private static void clearCache() {
        cachedSettings = null;
        cachedChannels = null;
        cachedAISettings = null;
    }
}
