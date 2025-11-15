// Test if CMDT exists in org
try {
    List<FS_Global_Settings__mdt> settings = [SELECT Id FROM FS_Global_Settings__mdt LIMIT 1];
    System.debug('FS_Global_Settings__mdt exists! Found ' + settings.size() + ' records.');
} catch (Exception e) {
    System.debug('FS_Global_Settings__mdt NOT found: ' + e.getMessage());
}

try {
    List<FS_Integration_Channel__mdt> channels = [SELECT Id FROM FS_Integration_Channel__mdt LIMIT 1];
    System.debug('FS_Integration_Channel__mdt exists! Found ' + channels.size() + ' records.');
} catch (Exception e) {
    System.debug('FS_Integration_Channel__mdt NOT found: ' + e.getMessage());
}

try {
    List<FS_AI_Settings__mdt> aiSettings = [SELECT Id FROM FS_AI_Settings__mdt LIMIT 1];
    System.debug('FS_AI_Settings__mdt exists! Found ' + aiSettings.size() + ' records.');
} catch (Exception e) {
    System.debug('FS_AI_Settings__mdt NOT found: ' + e.getMessage());
}

