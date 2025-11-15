/**
 * @description Service class for FlowSense Settings used by LWC components
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_SettingsService {
    
    /**
     * @description Get FlowSense settings for LWC
     * @return Map of settings data
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFlowSenseSettings() {
        // Return default settings since custom metadata fields may not exist
        // This allows the UI component to function without the backend being fully configured
        
        Map<String, Object> settings = new Map<String, Object>{
            'enableMonitoring' => true,
            'monitoringLevel' => 'standard',
            'dataRetentionDays' => 90,
            'enablePerformanceTracking' => true,
            'batchSize' => 200,
            
            'thresholds' => new Map<String, Object>{
                'warningDuration' => 5000,
                'criticalDuration' => 30000,
                'maxCpuTime' => 10000,
                'maxSoqlQueries' => 50,
                'maxDmlStatements' => 75,
                'warningErrorRate' => 5.0,
                'criticalErrorRate' => 15.0
            },
            
            'notifications' => new Map<String, Object>{
                'enableEmail' => false,
                'emailRecipients' => '',
                'reportFrequency' => 'weekly',
                'reportDay' => 'monday',
                'alertTriggers' => new Map<String, Object>{
                    'performanceThreshold' => true,
                    'errorThreshold' => true,
                    'failedFlows' => true,
                    'resourceLimits' => false,
                    'dailyDigest' => true
                }
            },
            
            'system' => new Map<String, Object>{
                'autoArchive' => true,
                'archiveAfterDays' => 365,
                'cleanupSchedule' => 'daily',
                'analysisSchedule' => 'hourly',
                'enableDebugLogging' => false,
                'logLevel' => 'info'
            }
        };
        
        return settings;
    }
    
    /**
     * @description Save FlowSense settings
     * @param settings Map of settings to save
     * @return Success indicator
     */
    @AuraEnabled
    public static Boolean saveFlowSenseSettings(Map<String, Object> settings) {
        try {
            // Note: Custom Metadata cannot be updated via Apex in production
            // This would typically integrate with a custom settings or configuration object
            // For now, return success for UI demonstration
            
            // TODO: Implement actual settings persistence based on your org's setup
            // This might involve:
            // 1. Custom Settings instead of Custom Metadata
            // 2. A custom configuration object
            // 3. Integration with Salesforce Setup API
            
            return true;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving settings: ' + e.getMessage());
        }
    }
    
    /**
     * @description Reset settings to default values
     * @return Map of default settings
     */
    @AuraEnabled
    public static Map<String, Object> resetSettingsToDefault() {
        Map<String, Object> defaultSettings = new Map<String, Object>{
            'enableMonitoring' => true,
            'monitoringLevel' => 'standard',
            'dataRetentionDays' => 90,
            'enablePerformanceTracking' => true,
            'batchSize' => 200,
            
            'thresholds' => new Map<String, Object>{
                'warningDuration' => 5000,
                'criticalDuration' => 30000,
                'maxCpuTime' => 10000,
                'maxSoqlQueries' => 50,
                'maxDmlStatements' => 75,
                'warningErrorRate' => 5.0,
                'criticalErrorRate' => 15.0
            },
            
            'notifications' => new Map<String, Object>{
                'enableEmail' => false,
                'emailRecipients' => '',
                'reportFrequency' => 'weekly',
                'reportDay' => 'monday',
                'alertTriggers' => new Map<String, Object>{
                    'performanceThreshold' => true,
                    'errorThreshold' => true,
                    'failedFlows' => true,
                    'resourceLimits' => false,
                    'dailyDigest' => true
                }
            },
            
            'system' => new Map<String, Object>{
                'autoArchive' => true,
                'archiveAfterDays' => 365,
                'cleanupSchedule' => 'daily',
                'analysisSchedule' => 'hourly',
                'enableDebugLogging' => false,
                'logLevel' => 'info'
            }
        };
        
        return defaultSettings;
    }
}