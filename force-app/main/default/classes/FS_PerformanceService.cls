/**
 * @description Service class for performance monitoring and analysis
 * @author FlowSense
 * @version 1.0
 */
public without sharing class FS_PerformanceService {
    
    private static final String CLASS_NAME = 'FS_PerformanceService';
    
    /**
     * @description Analyze flow performance and identify bottlenecks
     * @param flowApiName API name of the flow to analyze
     * @param daysPast Number of days to analyze
     * @return Performance analysis results
     */
    public static PerformanceAnalysisResult analyzeFlowPerformance(String flowApiName, Integer daysPast) {
        PerformanceAnalysisResult result = new PerformanceAnalysisResult();
        result.flowApiName = flowApiName;
        result.analysisPeriodDays = daysPast;
        
        try {
            // Validate inputs
            if (String.isBlank(flowApiName)) {
                throw new IllegalArgumentException('Flow API name cannot be null or empty');
            }
            if (daysPast < 0) {
                throw new IllegalArgumentException('Analysis period must be non-negative');
            }
            
            // Handle edge case: zero days means no analysis
            if (daysPast == 0) {
                result.hasData = false;
                result.recommendations = 'No analysis period specified.';
                return result;
            }
            
            DateTime startDate = System.now().addDays(-daysPast);
            
            // Get flow run statistics
            List<FS_Flow_Run__c> flowRuns = [
                SELECT Id, Duration_Ms__c, CPU_Time_Millis__c, SOQL_Count__c, 
                       DML_Count__c, Heap_Size_Bytes__c, Status__c, Started_At__c,
                       Error_Message__c
                FROM FS_Flow_Run__c
                WHERE Flow_API_Name__c = :flowApiName
                AND Started_At__c >= :startDate
                ORDER BY Started_At__c DESC
            ];
            
            if (flowRuns.isEmpty()) {
                result.hasData = false;
                result.recommendations = 'No execution data found for the specified period.';
                return result;
            }
            
            result.hasData = true;
            result.totalExecutions = flowRuns.size();
            
            // Calculate performance metrics
            calculateBasicMetrics(result, flowRuns);
            identifyPerformanceBottlenecks(result, flowRuns);
            generatePerformanceTrends(result, flowRuns);
            generateRecommendations(result);
            
            // Get step-level analysis if available
            analyzeStepPerformance(result, flowRuns);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error analyzing flow performance - ' + e.getMessage());
            result.hasError = true;
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    /**
     * @description Calculate basic performance metrics
     * @param result Performance analysis result to populate
     * @param flowRuns List of flow runs to analyze
     */
    private static void calculateBasicMetrics(PerformanceAnalysisResult result, List<FS_Flow_Run__c> flowRuns) {
        Decimal totalDuration = 0;
        Decimal totalCpuTime = 0;
        Decimal totalSoqlCount = 0;
        Decimal totalDmlCount = 0;
        Decimal totalHeapSize = 0;
        
        Decimal maxDuration = 0;
        Decimal maxCpuTime = 0;
        Decimal maxSoqlCount = 0;
        Decimal maxDmlCount = 0;
        Decimal maxHeapSize = 0;
        
        Integer successfulRuns = 0;
        Integer failedRuns = 0;
        
        for (FS_Flow_Run__c run : flowRuns) {
            // Duration metrics
            if (run.Duration_Ms__c != null) {
                totalDuration += run.Duration_Ms__c;
                maxDuration = Math.max(maxDuration, run.Duration_Ms__c);
            }
            
            // CPU metrics
            if (run.CPU_Time_Millis__c != null) {
                totalCpuTime += run.CPU_Time_Millis__c;
                maxCpuTime = Math.max(maxCpuTime, run.CPU_Time_Millis__c);
            }
            
            // SOQL metrics
            if (run.SOQL_Count__c != null) {
                totalSoqlCount += run.SOQL_Count__c;
                maxSoqlCount = Math.max(maxSoqlCount, run.SOQL_Count__c);
            }
            
            // DML metrics
            if (run.DML_Count__c != null) {
                totalDmlCount += run.DML_Count__c;
                maxDmlCount = Math.max(maxDmlCount, run.DML_Count__c);
            }
            
            // Heap metrics
            if (run.Heap_Size_Bytes__c != null) {
                totalHeapSize += run.Heap_Size_Bytes__c;
                maxHeapSize = Math.max(maxHeapSize, run.Heap_Size_Bytes__c);
            }
            
            // Status tracking
            if (run.Status__c == 'Success') {
                successfulRuns++;
            } else if (run.Status__c == 'Failed') {
                failedRuns++;
            }
        }
        
        // Calculate averages
        result.avgDurationMs = totalDuration / flowRuns.size();
        result.avgCpuTimeMs = totalCpuTime / flowRuns.size();
        result.avgSoqlCount = totalSoqlCount / flowRuns.size();
        result.avgDmlCount = totalDmlCount / flowRuns.size();
        result.avgHeapSizeMB = (totalHeapSize / flowRuns.size()) / (1024 * 1024);
        
        // Set maximum values
        result.maxDurationMs = maxDuration;
        result.maxCpuTimeMs = maxCpuTime;
        result.maxSoqlCount = maxSoqlCount;
        result.maxDmlCount = maxDmlCount;
        result.maxHeapSizeMB = maxHeapSize / (1024 * 1024);
        
        // Calculate success rate
        result.successfulExecutions = successfulRuns;
        result.failedExecutions = failedRuns;
        result.successRate = (Decimal)successfulRuns / (Decimal)flowRuns.size() * 100;
    }
    
    /**
     * @description Identify performance bottlenecks
     * @param result Performance analysis result to populate
     * @param flowRuns List of flow runs to analyze
     */
    private static void identifyPerformanceBottlenecks(PerformanceAnalysisResult result, List<FS_Flow_Run__c> flowRuns) {
        result.bottlenecks = new List<String>();
        
        // Get thresholds from CMDT settings
        Decimal cpuThreshold = FS_SettingsUtil.getCPUCriticalThreshold();
        Decimal soqlThreshold = FS_SettingsUtil.getSOQLCriticalThreshold();
        Decimal dmlThreshold = FS_SettingsUtil.getDMLCriticalThreshold();
        
        // Check CPU time bottlenecks
        if (result.avgCpuTimeMs > cpuThreshold) {
            result.bottlenecks.add('High CPU usage: Average ' + result.avgCpuTimeMs.setScale(0) + 'ms exceeds threshold of ' + cpuThreshold + 'ms');
        }
        
        // Check SOQL bottlenecks
        if (result.avgSoqlCount > soqlThreshold) {
            result.bottlenecks.add('Excessive SOQL queries: Average ' + result.avgSoqlCount.setScale(0) + ' queries exceeds threshold of ' + soqlThreshold);
        }
        
        // Check DML bottlenecks
        if (result.avgDmlCount > dmlThreshold) {
            result.bottlenecks.add('Excessive DML operations: Average ' + result.avgDmlCount.setScale(0) + ' operations exceeds threshold of ' + dmlThreshold);
        }
        
        // Check duration bottlenecks
        if (result.avgDurationMs > 20000) {
            result.bottlenecks.add('Long execution time: Average ' + result.avgDurationMs.setScale(0) + 'ms exceeds recommended 20 seconds');
        }
        
        // Check heap size bottlenecks
        if (result.avgHeapSizeMB > 8) {
            result.bottlenecks.add('High memory usage: Average ' + result.avgHeapSizeMB.setScale(2) + 'MB exceeds recommended 8MB');
        }
        
        // Check error rate
        if (result.successRate < 95) {
            result.bottlenecks.add('High failure rate: ' + (100 - result.successRate).setScale(1) + '% of executions fail');
        }
    }
    
    /**
     * @description Generate performance trends over time
     * @param result Performance analysis result to populate
     * @param flowRuns List of flow runs to analyze
     */
    private static void generatePerformanceTrends(PerformanceAnalysisResult result, List<FS_Flow_Run__c> flowRuns) {
        result.trends = new List<String>();
        
        if (flowRuns.size() < 10) {
            result.trends.add('Insufficient data for trend analysis (minimum 10 executions required)');
            return;
        }
        
        // Split into two periods for comparison
        Integer midPoint = flowRuns.size() / 2;
        List<FS_Flow_Run__c> recentRuns = new List<FS_Flow_Run__c>();
        List<FS_Flow_Run__c> olderRuns = new List<FS_Flow_Run__c>();
        
        for (Integer i = 0; i < flowRuns.size(); i++) {
            if (i < midPoint) {
                recentRuns.add(flowRuns[i]);
            } else {
                olderRuns.add(flowRuns[i]);
            }
        }
        
        // Calculate averages for each period
        Decimal recentAvgDuration = calculateAverageDuration(recentRuns);
        Decimal olderAvgDuration = calculateAverageDuration(olderRuns);
        
        Decimal recentAvgCpu = calculateAverageCpu(recentRuns);
        Decimal olderAvgCpu = calculateAverageCpu(olderRuns);
        
        // Compare trends
        if (recentAvgDuration > olderAvgDuration * 1.1) {
            result.trends.add('Duration trend: Performance degrading (recent avg: ' + 
                            recentAvgDuration.setScale(0) + 'ms vs older avg: ' + olderAvgDuration.setScale(0) + 'ms)');
        } else if (recentAvgDuration < olderAvgDuration * 0.9) {
            result.trends.add('Duration trend: Performance improving (recent avg: ' + 
                            recentAvgDuration.setScale(0) + 'ms vs older avg: ' + olderAvgDuration.setScale(0) + 'ms)');
        } else {
            result.trends.add('Duration trend: Stable performance');
        }
        
        if (recentAvgCpu > olderAvgCpu * 1.1) {
            result.trends.add('CPU trend: CPU usage increasing (recent avg: ' + 
                            recentAvgCpu.setScale(0) + 'ms vs older avg: ' + olderAvgCpu.setScale(0) + 'ms)');
        } else if (recentAvgCpu < olderAvgCpu * 0.9) {
            result.trends.add('CPU trend: CPU usage decreasing (recent avg: ' + 
                            recentAvgCpu.setScale(0) + 'ms vs older avg: ' + olderAvgCpu.setScale(0) + 'ms)');
        } else {
            result.trends.add('CPU trend: Stable CPU usage');
        }
    }
    
    /**
     * @description Calculate average duration for a list of flow runs
     * @param runs List of flow runs
     * @return Average duration
     */
    private static Decimal calculateAverageDuration(List<FS_Flow_Run__c> runs) {
        Decimal total = 0;
        Integer count = 0;
        
        for (FS_Flow_Run__c run : runs) {
            if (run.Duration_Ms__c != null) {
                total += run.Duration_Ms__c;
                count++;
            }
        }
        
        return count > 0 ? total / count : 0;
    }
    
    /**
     * @description Calculate average CPU time for a list of flow runs
     * @param runs List of flow runs
     * @return Average CPU time
     */
    private static Decimal calculateAverageCpu(List<FS_Flow_Run__c> runs) {
        Decimal total = 0;
        Integer count = 0;
        
        for (FS_Flow_Run__c run : runs) {
            if (run.CPU_Time_Millis__c != null) {
                total += run.CPU_Time_Millis__c;
                count++;
            }
        }
        
        return count > 0 ? total / count : 0;
    }
    
    /**
     * @description Analyze step-level performance
     * @param result Performance analysis result to populate
     * @param flowRuns List of flow runs to analyze
     */
    private static void analyzeStepPerformance(PerformanceAnalysisResult result, List<FS_Flow_Run__c> flowRuns) {
        try {
            List<Id> flowRunIds = new List<Id>();
            for (FS_Flow_Run__c run : flowRuns) {
                flowRunIds.add(run.Id);
            }
            
            // Get step performance data
            List<AggregateResult> stepStats = [
                SELECT Element_Type__c, Element_DeveloperName__c,
                       COUNT(Id) stepCount,
                       AVG(Duration_Millis__c) avgDuration,
                       MAX(Duration_Millis__c) maxDuration,
                       AVG(CPU_Millis__c) avgCpu
                FROM FS_Flow_Step__c
                WHERE Flow_Run__c IN :flowRunIds
                AND Duration_Millis__c != null
                GROUP BY Element_Type__c, Element_DeveloperName__c
                ORDER BY AVG(Duration_Millis__c) DESC
                LIMIT 10
            ];
            
            result.slowestSteps = new List<String>();
            for (AggregateResult stepStat : stepStats) {
                String stepType = (String)stepStat.get('Element_Type__c');
                String stepName = (String)stepStat.get('Element_DeveloperName__c');
                Decimal avgDuration = (Decimal)stepStat.get('avgDuration');
                
                result.slowestSteps.add(stepType + ' "' + stepName + '": ' + avgDuration.setScale(0) + 'ms avg');
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, CLASS_NAME + ': Error analyzing step performance - ' + e.getMessage());
        }
    }
    
    /**
     * @description Detect performance hotspots in flow execution
     * @param flowApiName Flow API name
     * @param daysPast Number of days to analyze
     * @return Hotspot analysis result
     */
    @AuraEnabled(cacheable=false)
    public static HotspotAnalysisResult detectHotspots(String flowApiName, Integer daysPast) {
        HotspotAnalysisResult result = new HotspotAnalysisResult();
        result.flowApiName = flowApiName;
        result.hotspots = new List<HotspotDetail>();
        result.elementTypeMetrics = new List<ElementTypeMetric>();
        
        try {
            DateTime startDate = System.now().addDays(-daysPast);
            
            // Get recent flow runs
            List<FS_Flow_Run__c> flowRuns = FS_FlowRunSelector.selectByFlowApiName(flowApiName, daysPast, 100);
            
            if (flowRuns.isEmpty()) {
                result.hasData = false;
                return result;
            }
            
            result.hasData = true;
            
            // Get steps for these runs
            Set<Id> runIds = new Set<Id>();
            for (FS_Flow_Run__c run : flowRuns) {
                runIds.add(run.Id);
            }
            
            List<FS_Flow_Step__c> steps = FS_FlowStepSelector.selectByFlowRunId(runIds);
            
            // Use Domain class to identify hotspots
            List<FS_FlowStepDomain.HotspotIndicator> hotspots = FS_FlowStepDomain.identifyHotspots(steps);
            
            // Convert to result format
            for (FS_FlowStepDomain.HotspotIndicator indicator : hotspots) {
                if (indicator.isHotspot) {
                    HotspotDetail detail = new HotspotDetail();
                    detail.elementName = indicator.elementName;
                    detail.elementType = indicator.elementType;
                    detail.issueType = String.join(indicator.reasons, ', ');
                    detail.severity = determineSeverity(indicator.reasons);
                    result.hotspots.add(detail);
                }
            }
            
            // Detect SOQL/DML in loops
            detectSOQLDMLInLoops(result, steps);
            
            // Detect recursion patterns
            detectRecursion(result, flowRuns);
            
            // Aggregate by element type
            Map<String, FS_FlowStepDomain.ElementTypeMetrics> metricsMap = 
                FS_FlowStepDomain.aggregateByElementType(steps);
            
            for (FS_FlowStepDomain.ElementTypeMetrics metrics : metricsMap.values()) {
                ElementTypeMetric metric = new ElementTypeMetric();
                metric.elementType = metrics.elementType;
                metric.count = metrics.count;
                metric.avgDuration = metrics.avgDuration;
                metric.maxDuration = metrics.maxDuration;
                metric.totalSoql = metrics.totalSoql;
                metric.totalDml = metrics.totalDml;
                result.elementTypeMetrics.add(metric);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error detecting hotspots - ' + e.getMessage());
            result.hasError = true;
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    /**
     * @description Detect SOQL/DML operations in loops
     * @param result Hotspot analysis result
     * @param steps Flow steps
     */
    private static void detectSOQLDMLInLoops(HotspotAnalysisResult result, List<FS_Flow_Step__c> steps) {
        Map<String, Integer> elementOccurrences = new Map<String, Integer>();
        
        for (FS_Flow_Step__c step : steps) {
            String key = step.Element_Developer_Name__c + '_' + step.Element_Type__c;
            
            if (!elementOccurrences.containsKey(key)) {
                elementOccurrences.put(key, 0);
            }
            elementOccurrences.put(key, elementOccurrences.get(key) + 1);
        }
        
        // Check for high occurrence of SOQL/DML elements
        for (String key : elementOccurrences.keySet()) {
            Integer count = elementOccurrences.get(key);
            if (count > 10) {
                String[] parts = key.split('_');
                String elementType = parts.size() > 1 ? parts[parts.size() - 1] : 'Unknown';
                
                if (elementType == 'GetRecords' || elementType == 'UpdateRecords' || 
                    elementType == 'CreateRecords' || elementType == 'DeleteRecords') {
                    
                    HotspotDetail detail = new HotspotDetail();
                    detail.elementName = parts[0];
                    detail.elementType = elementType;
                    detail.issueType = 'Potential ' + elementType + ' in loop (occurred ' + count + ' times)';
                    detail.severity = 'High';
                    result.hotspots.add(detail);
                }
            }
        }
    }
    
    /**
     * @description Detect recursion patterns
     * @param result Hotspot analysis result
     * @param flowRuns Flow runs
     */
    private static void detectRecursion(HotspotAnalysisResult result, List<FS_Flow_Run__c> flowRuns) {
        // Group runs by time windows to detect recursion
        Map<String, List<FS_Flow_Run__c>> timeWindows = new Map<String, List<FS_Flow_Run__c>>();
        
        for (FS_Flow_Run__c run : flowRuns) {
            if (run.Started_At__c != null) {
                // Group by minute
                String timeKey = run.Started_At__c.format('yyyy-MM-dd HH:mm');
                
                if (!timeWindows.containsKey(timeKey)) {
                    timeWindows.put(timeKey, new List<FS_Flow_Run__c>());
                }
                timeWindows.get(timeKey).add(run);
            }
        }
        
        // Check for multiple runs in same time window
        for (String timeKey : timeWindows.keySet()) {
            Integer count = timeWindows.get(timeKey).size();
            if (count > 5) {
                HotspotDetail detail = new HotspotDetail();
                detail.elementName = 'Flow Execution';
                detail.elementType = 'Recursion';
                detail.issueType = 'Possible recursion detected: ' + count + ' executions in same minute';
                detail.severity = 'Critical';
                result.hotspots.add(detail);
                break; // Only report once
            }
        }
    }
    
    /**
     * @description Determine severity based on reasons
     * @param reasons List of issue reasons
     * @return Severity level
     */
    private static String determineSeverity(List<String> reasons) {
        if (reasons == null || reasons.isEmpty()) {
            return 'Low';
        }
        
        for (String reason : reasons) {
            if (reason.containsIgnoreCase('loop') || reason.containsIgnoreCase('recursion')) {
                return 'Critical';
            }
            if (reason.containsIgnoreCase('high') || reason.containsIgnoreCase('long')) {
                return 'High';
            }
        }
        
        return 'Medium';
    }
    
    /**
     * @description Generate performance recommendations
     * @param result Performance analysis result to populate
     */
    private static void generateRecommendations(PerformanceAnalysisResult result) {
        result.recommendations = 'Performance Recommendations:\n\n';
        
        if (result.bottlenecks.isEmpty()) {
            result.recommendations += '✅ No significant performance issues detected.\n';
            result.recommendations += '• Continue monitoring performance metrics\n';
            result.recommendations += '• Consider setting up proactive alerts\n';
        } else {
            result.recommendations += '⚠️ Performance issues detected:\n\n';
            
            for (String bottleneck : result.bottlenecks) {
                result.recommendations += '• ' + bottleneck + '\n';
            }
            
            result.recommendations += '\n📋 Recommended Actions:\n';
            
            if (result.avgCpuTimeMs > 5000) {
                result.recommendations += '• Review and optimize CPU-intensive operations\n';
                result.recommendations += '• Consider breaking complex logic into smaller flows\n';
            }
            
            if (result.avgSoqlCount > 25) {
                result.recommendations += '• Consolidate SOQL queries using collections\n';
                result.recommendations += '• Implement query optimization techniques\n';
            }
            
            if (result.avgDmlCount > 25) {
                result.recommendations += '• Batch DML operations where possible\n';
                result.recommendations += '• Use bulk processing patterns\n';
            }
            
            if (result.avgDurationMs > 10000) {
                result.recommendations += '• Consider asynchronous processing for long operations\n';
                result.recommendations += '• Break down complex flows into smaller components\n';
            }
            
            if (result.successRate < 95) {
                result.recommendations += '• Review error patterns and implement error handling\n';
                result.recommendations += '• Add validation steps to prevent common failures\n';
            }
        }
        
        if (result.slowestSteps != null && !result.slowestSteps.isEmpty()) {
            result.recommendations += '\n🐌 Slowest Flow Steps:\n';
            for (String step : result.slowestSteps) {
                result.recommendations += '• ' + step + '\n';
            }
        }
    }
    
    /**
     * @description Get performance score for a specific flow execution
     * @param flowRunId Flow run ID
     * @return Performance score (0-100)
     */
    public static Decimal calculateExecutionScore(Id flowRunId) {
        try {
            FS_Flow_Run__c flowRun = [
                SELECT Duration_Ms__c, CPU_Time_Millis__c, SOQL_Count__c, 
                       DML_Count__c, Heap_Size_Bytes__c, Status__c
                FROM FS_Flow_Run__c
                WHERE Id = :flowRunId
                LIMIT 1
            ];
            
            if (flowRun.Status__c == 'Failed') {
                return 0;
            }
            
            // Use the FS_PerformanceScoreAction to calculate score
            FS_PerformanceScoreAction.Request request = new FS_PerformanceScoreAction.Request();
            request.cpuTimeMillis = flowRun.CPU_Time_Millis__c;
            request.soqlCount = flowRun.SOQL_Count__c;
            request.dmlCount = flowRun.DML_Count__c;
            request.executionTimeMillis = flowRun.Duration_Ms__c;
            request.heapSizeBytes = flowRun.Heap_Size_Bytes__c;
            
            List<FS_PerformanceScoreAction.Result> results = 
                FS_PerformanceScoreAction.calculatePerformanceScore(new List<FS_PerformanceScoreAction.Request>{request});
            
            if (!results.isEmpty() && results[0].isSuccess) {
                return results[0].overallScore;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error calculating execution score - ' + e.getMessage());
        }
        
        return 0;
    }
    
    /**
     * @description Performance analysis result wrapper
     */
    public class PerformanceAnalysisResult {
        public String flowApiName;
        public Integer analysisPeriodDays;
        public Boolean hasData = false;
        public Boolean hasError = false;
        public String errorMessage;
        
        public Integer totalExecutions = 0;
        public Integer successfulExecutions = 0;
        public Integer failedExecutions = 0;
        public Decimal successRate = 0;
        
        public Decimal avgDurationMs = 0;
        public Decimal avgCpuTimeMs = 0;
        public Decimal avgSoqlCount = 0;
        public Decimal avgDmlCount = 0;
        public Decimal avgHeapSizeMB = 0;
        
        public Decimal maxDurationMs = 0;
        public Decimal maxCpuTimeMs = 0;
        public Decimal maxSoqlCount = 0;
        public Decimal maxDmlCount = 0;
        public Decimal maxHeapSizeMB = 0;
        
        public List<String> bottlenecks;
        public List<String> trends;
        public List<String> slowestSteps;
        public String recommendations;
    }
    
    /**
     * @description Hotspot analysis result wrapper
     */
    public class HotspotAnalysisResult {
        @AuraEnabled public String flowApiName;
        @AuraEnabled public Boolean hasData = false;
        @AuraEnabled public Boolean hasError = false;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public List<HotspotDetail> hotspots;
        @AuraEnabled public List<ElementTypeMetric> elementTypeMetrics;
    }
    
    /**
     * @description Hotspot detail wrapper
     */
    public class HotspotDetail {
        @AuraEnabled public String elementName;
        @AuraEnabled public String elementType;
        @AuraEnabled public String issueType;
        @AuraEnabled public String severity;
    }
    
    /**
     * @description Element type metric wrapper
     */
    public class ElementTypeMetric {
        @AuraEnabled public String elementType;
        @AuraEnabled public Integer count;
        @AuraEnabled public Decimal avgDuration;
        @AuraEnabled public Decimal maxDuration;
        @AuraEnabled public Decimal totalSoql;
        @AuraEnabled public Decimal totalDml;
    }
}