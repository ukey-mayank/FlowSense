// Check what fields are available on FS_Flow_Analysis__c
Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get('FS_Flow_Analysis__c').getDescribe().fields.getMap();

System.debug('=== Available Fields on FS_Flow_Analysis__c ===');
for (String fieldName : fields.keySet()) {
    System.debug('Field: ' + fieldName);
}