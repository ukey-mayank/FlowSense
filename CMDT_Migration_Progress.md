# CMDT Migration Progress

## Challenge
Salesforce doesn't allow both Custom Settings (`__c`) and Custom Metadata Types (`__mdt`) with similar names. The existing `FS_Global_Settings__c` (Custom Settings) must be replaced with `FS_Global_Settings__mdt` (CMDT).

## Classes That Need Updating (11 total):

### Critical Classes (Used in Production):
- [ ] FS_LoggingService.cls
- [ ] FS_PerformanceService.cls  
- [ ] FS_PerformanceScoreAction.cls
- [ ] FS_NotifyOnErrorAction.cls
- [ ] FS_LogStepAction.cls

### Test Classes:
- [ ] FS_TestDataFactory.cls
- [ ] FS_LoggingServiceTest.cls
- [ ] FS_PerformanceServiceTest.cls
- [ ] FS_LogStepActionTest.cls
- [ ] FS_PerformanceScoreActionTest.cls
- [ ] FS_NotifyOnErrorActionTest.cls

## Migration Pattern:

### Old (Custom Settings):
```apex
FS_Global_Settings__c settings = FS_Global_Settings__c.getInstance();
Integer days = (Integer)settings.Data_Retention_Days__c;
Integer cpuThreshold = (Integer)settings.CPU_Poor_Threshold__c;
```

### New (CMDT via FS_SettingsUtil):
```apex
Integer days = FS_SettingsUtil.getRetentionDays();
Integer cpuThreshold = FS_SettingsUtil.getCPUWarningThreshold();
```

## Steps:
1. ✅ Created FS_SettingsUtil with CMDT access
2. ⏳ Update all 11 classes to use FS_SettingsUtil
3. ⏳ Deploy updated classes
4. ⏳ Delete Custom Settings object
5. ⏳ Deploy CMDT objects
6. ⏳ Deploy CMDT records
7. ⏳ Verify everything works

## Status: IN PROGRESS - Updating classes...

