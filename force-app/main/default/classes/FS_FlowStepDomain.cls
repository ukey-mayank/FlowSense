/**
 * @description Domain class for FS_Flow_Step__c business logic
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_FlowStepDomain {
    
    /**
     * @description Validate flow step records before insert
     * @param flowSteps List of flow step records
     */
    public static void validateBeforeInsert(List<FS_Flow_Step__c> flowSteps) {
        for (FS_Flow_Step__c step : flowSteps) {
            // Validate required fields
            if (step.Flow_Run__c == null) {
                step.addError('Flow Run is required');
            }
            
            if (String.isBlank(step.Element_Developer_Name__c)) {
                step.addError('Element Developer Name is required');
            }
            
            if (step.Sequence_Number__c == null) {
                step.addError('Sequence Number is required');
            }
        }
    }
    
    /**
     * @description Calculate duration for completed steps
     * @param flowSteps List of flow step records
     */
    public static void calculateDuration(List<FS_Flow_Step__c> flowSteps) {
        for (FS_Flow_Step__c step : flowSteps) {
            if (step.Entered_At__c != null && step.Exited_At__c != null) {
                Long duration = step.Exited_At__c.getTime() - step.Entered_At__c.getTime();
                step.Duration_Millis__c = duration;
            }
        }
    }
    
    /**
     * @description Identify performance hotspots in steps
     * @param flowSteps List of flow step records
     * @return List of hotspot indicators
     */
    public static List<HotspotIndicator> identifyHotspots(List<FS_Flow_Step__c> flowSteps) {
        List<HotspotIndicator> hotspots = new List<HotspotIndicator>();
        
        for (FS_Flow_Step__c step : flowSteps) {
            HotspotIndicator indicator = new HotspotIndicator();
            indicator.stepId = step.Id;
            indicator.elementName = step.Element_Developer_Name__c;
            indicator.elementType = step.Element_Type__c;
            indicator.isHotspot = false;
            indicator.reasons = new List<String>();
            
            // Check for long-running step
            if (step.Duration_Millis__c != null && step.Duration_Millis__c > 5000) {
                indicator.isHotspot = true;
                indicator.reasons.add('Long execution time: ' + step.Duration_Millis__c + 'ms');
            }
            
            // Check for high CPU usage
            if (step.CPU_Millis__c != null && step.CPU_Millis__c > 3000) {
                indicator.isHotspot = true;
                indicator.reasons.add('High CPU time: ' + step.CPU_Millis__c + 'ms');
            }
            
            // Check for SOQL in loops (multiple SOQL in GetRecords element)
            if (step.Element_Type__c == 'GetRecords' && step.SOQL_Count__c != null && step.SOQL_Count__c > 10) {
                indicator.isHotspot = true;
                indicator.reasons.add('Potential SOQL in loop: ' + step.SOQL_Count__c + ' queries');
            }
            
            // Check for DML in loops
            if (step.Element_Type__c == 'UpdateRecords' && step.DML_Count__c != null && step.DML_Count__c > 10) {
                indicator.isHotspot = true;
                indicator.reasons.add('Potential DML in loop: ' + step.DML_Count__c + ' operations');
            }
            
            if (indicator.isHotspot) {
                hotspots.add(indicator);
            }
        }
        
        return hotspots;
    }
    
    /**
     * @description Aggregate step metrics by element type
     * @param flowSteps List of flow step records
     * @return Map of element type to metrics
     */
    public static Map<String, ElementTypeMetrics> aggregateByElementType(List<FS_Flow_Step__c> flowSteps) {
        Map<String, ElementTypeMetrics> metricsMap = new Map<String, ElementTypeMetrics>();
        
        for (FS_Flow_Step__c step : flowSteps) {
            String elementType = step.Element_Type__c;
            
            if (!metricsMap.containsKey(elementType)) {
                metricsMap.put(elementType, new ElementTypeMetrics(elementType));
            }
            
            ElementTypeMetrics metrics = metricsMap.get(elementType);
            metrics.count++;
            
            if (step.Duration_Millis__c != null) {
                metrics.totalDuration += step.Duration_Millis__c;
                metrics.maxDuration = Math.max(metrics.maxDuration, step.Duration_Millis__c);
            }
            
            if (step.CPU_Millis__c != null) {
                metrics.totalCpu += step.CPU_Millis__c;
            }
            
            if (step.SOQL_Count__c != null) {
                metrics.totalSoql += step.SOQL_Count__c;
            }
            
            if (step.DML_Count__c != null) {
                metrics.totalDml += step.DML_Count__c;
            }
        }
        
        // Calculate averages
        for (ElementTypeMetrics metrics : metricsMap.values()) {
            if (metrics.count > 0) {
                metrics.avgDuration = metrics.totalDuration / metrics.count;
                metrics.avgCpu = metrics.totalCpu / metrics.count;
            }
        }
        
        return metricsMap;
    }
    
    /**
     * @description Inner class for hotspot indicators
     */
    public class HotspotIndicator {
        public Id stepId;
        public String elementName;
        public String elementType;
        public Boolean isHotspot;
        public List<String> reasons;
    }
    
    /**
     * @description Inner class for element type metrics
     */
    public class ElementTypeMetrics {
        public String elementType;
        public Integer count;
        public Decimal totalDuration;
        public Decimal maxDuration;
        public Decimal avgDuration;
        public Decimal totalCpu;
        public Decimal avgCpu;
        public Decimal totalSoql;
        public Decimal totalDml;
        
        public ElementTypeMetrics(String elementType) {
            this.elementType = elementType;
            this.count = 0;
            this.totalDuration = 0;
            this.maxDuration = 0;
            this.avgDuration = 0;
            this.totalCpu = 0;
            this.avgCpu = 0;
            this.totalSoql = 0;
            this.totalDml = 0;
        }
    }
}

