/**
 * @description Domain class for FS_Flow_Change__c business logic
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_FlowChangeDomain {
    
    /**
     * @description Validate flow change records before insert
     * @param flowChanges List of flow change records
     */
    public static void validateBeforeInsert(List<FS_Flow_Change__c> flowChanges) {
        for (FS_Flow_Change__c change : flowChanges) {
            // Validate required fields
            if (String.isBlank(change.Flow_API_Name__c)) {
                change.addError('Flow API Name is required');
            }
            
            if (change.From_Version__c == null || change.To_Version__c == null) {
                change.addError('Both From Version and To Version are required');
            }
            
            if (change.From_Version__c != null && change.To_Version__c != null) {
                if (change.From_Version__c >= change.To_Version__c) {
                    change.addError('To Version must be greater than From Version');
                }
            }
            
            if (change.Analyzed_At__c == null) {
                change.Analyzed_At__c = System.now();
            }
        }
    }
    
    /**
     * @description Calculate content hash for deduplication
     * @param flowApiName Flow API name
     * @param fromVersion From version
     * @param toVersion To version
     * @param snapshotData Snapshot data
     * @return Content hash
     */
    public static String calculateContentHash(
        String flowApiName, 
        Integer fromVersion, 
        Integer toVersion,
        String snapshotData
    ) {
        String content = flowApiName + ':' + fromVersion + ':' + toVersion;
        if (String.isNotBlank(snapshotData)) {
            content += ':' + snapshotData;
        }
        
        Blob hash = Crypto.generateDigest('SHA-256', Blob.valueOf(content));
        return EncodingUtil.convertToHex(hash);
    }
    
    /**
     * @description Assess impact level of changes
     * @param changeSummary Change summary text
     * @return Impact level (Low, Medium, High, Critical)
     */
    public static String assessImpactLevel(String changeSummary) {
        if (String.isBlank(changeSummary)) {
            return 'Low';
        }
        
        String summary = changeSummary.toLowerCase();
        Integer criticalCount = 0;
        Integer highCount = 0;
        Integer mediumCount = 0;
        
        // Critical indicators
        if (summary.contains('removed') || summary.contains('deleted')) {
            criticalCount++;
        }
        if (summary.contains('permission') || summary.contains('security')) {
            criticalCount++;
        }
        
        // High indicators
        if (summary.contains('modified logic') || summary.contains('changed formula')) {
            highCount++;
        }
        if (summary.contains('record update') || summary.contains('data modification')) {
            highCount++;
        }
        
        // Medium indicators
        if (summary.contains('added') || summary.contains('new element')) {
            mediumCount++;
        }
        if (summary.contains('path change') || summary.contains('decision')) {
            mediumCount++;
        }
        
        // Determine impact level
        if (criticalCount > 0) {
            return 'Critical';
        } else if (highCount > 1 || (highCount > 0 && mediumCount > 2)) {
            return 'High';
        } else if (highCount > 0 || mediumCount > 2) {
            return 'Medium';
        } else {
            return 'Low';
        }
    }
    
    /**
     * @description Generate change summary from snapshot comparison
     * @param fromSnapshot From version snapshot
     * @param toSnapshot To version snapshot
     * @return Change summary
     */
    public static String generateChangeSummary(String fromSnapshot, String toSnapshot) {
        List<String> changes = new List<String>();
        
        // Simple comparison - in real implementation, this would parse JSON snapshots
        if (String.isBlank(fromSnapshot) && String.isNotBlank(toSnapshot)) {
            changes.add('Initial version created');
        } else if (String.isNotBlank(fromSnapshot) && String.isNotBlank(toSnapshot)) {
            if (fromSnapshot.length() < toSnapshot.length()) {
                changes.add('Elements added');
            } else if (fromSnapshot.length() > toSnapshot.length()) {
                changes.add('Elements removed');
            } else {
                changes.add('Elements modified');
            }
        }
        
        return String.join(changes, '; ');
    }
    
    /**
     * @description Prevent duplicate change records
     * @param flowChanges List of flow change records
     */
    public static void preventDuplicates(List<FS_Flow_Change__c> flowChanges) {
        // Build hash set
        Set<String> hashes = new Set<String>();
        for (FS_Flow_Change__c change : flowChanges) {
            if (String.isNotBlank(change.Content_Hash__c)) {
                hashes.add(change.Content_Hash__c);
            }
        }
        
        // Check for existing records
        if (!hashes.isEmpty()) {
            List<FS_Flow_Change__c> existing = [
                SELECT Content_Hash__c
                FROM FS_Flow_Change__c
                WHERE Content_Hash__c IN :hashes
                WITH SECURITY_ENFORCED
                LIMIT 10000
            ];
            
            Set<String> existingHashes = new Set<String>();
            for (FS_Flow_Change__c ex : existing) {
                existingHashes.add(ex.Content_Hash__c);
            }
            
            // Mark duplicates
            for (FS_Flow_Change__c change : flowChanges) {
                if (String.isNotBlank(change.Content_Hash__c) && 
                    existingHashes.contains(change.Content_Hash__c)) {
                    change.addError('A change record for these versions already exists');
                }
            }
        }
    }
}

