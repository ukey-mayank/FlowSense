public with sharing class FS_DashboardController {
    
    @AuraEnabled(cacheable=true)
    public static List<FlowAnalyticsWrapper> getFlowAnalytics(Integer daysPast, String riskLevel, String searchTerm) {
        List<FlowAnalyticsWrapper> results = new List<FlowAnalyticsWrapper>();
        
        try {
            String query = 'SELECT Flow_API_Name__c, Performance_Score__c, Risk_Level__c, ' +
                          'Analysis_Date__c, Complexity_Score__c ' +
                          'FROM FS_Flow_Analysis__c ' +
                          'WHERE Analysis_Date__c >= :startDate';
            
            DateTime startDate = DateTime.now().addDays(-daysPast);
            Map<String, Object> bindVars = new Map<String, Object>{'startDate' => startDate};
            
            if (String.isNotBlank(riskLevel)) {
                query += ' AND Risk_Level__c = :riskLevel';
                bindVars.put('riskLevel', riskLevel);
            }
            
            if (String.isNotBlank(searchTerm)) {
                query += ' AND Flow_API_Name__c LIKE :searchPattern';
                bindVars.put('searchPattern', '%' + searchTerm + '%');
            }
            
            query += ' ORDER BY Analysis_Date__c DESC';
            
            List<FS_Flow_Analysis__c> analyses = Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE);
            
            // Group by flow API name and get latest analysis
            Map<String, FS_Flow_Analysis__c> latestAnalyses = new Map<String, FS_Flow_Analysis__c>();
            for (FS_Flow_Analysis__c analysis : analyses) {
                String flowName = analysis.Flow_API_Name__c;
                if (!latestAnalyses.containsKey(flowName) || 
                    analysis.Analysis_Date__c > latestAnalyses.get(flowName).Analysis_Date__c) {
                    latestAnalyses.put(flowName, analysis);
                }
            }
            
            // Get execution statistics for each flow
            Map<String, FlowExecutionStats> executionStats = getFlowExecutionStats(latestAnalyses.keySet(), daysPast);
            
            for (String flowName : latestAnalyses.keySet()) {
                FS_Flow_Analysis__c analysis = latestAnalyses.get(flowName);
                FlowExecutionStats stats = executionStats.get(flowName);
                
                FlowAnalyticsWrapper wrapper = new FlowAnalyticsWrapper();
                wrapper.id = analysis.Id;
                wrapper.flowName = flowName;
                wrapper.lastExecution = analysis.Analysis_Date__c;
                wrapper.performanceScore = analysis.Performance_Score__c != null ? analysis.Performance_Score__c.intValue() : 0;
                wrapper.riskLevel = analysis.Risk_Level__c;
                wrapper.averageDuration = stats != null ? stats.averageDuration : 0;
                wrapper.executionCount = stats != null ? stats.executionCount : 0;
                
                results.add(wrapper);
            }
            
        } catch (Exception e) {
            System.debug('Error in getFlowAnalytics: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve flow analytics: ' + e.getMessage());
        }
        
        return results;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAllFlowNames() {
        List<Map<String, String>> flowOptions = new List<Map<String, String>>();
        
        try {
            // Get all flow names from Flow_Analysis records
            Set<String> flowNamesSet = new Set<String>();
            
            // Get flows from Analysis records
            List<FS_Flow_Analysis__c> analyses = [
                SELECT Flow_API_Name__c 
                FROM FS_Flow_Analysis__c 
                WHERE Flow_API_Name__c != null
                ORDER BY Flow_API_Name__c
            ];
            
            for (FS_Flow_Analysis__c analysis : analyses) {
                flowNamesSet.add(analysis.Flow_API_Name__c);
            }
            
            // Get flows from Run records that might not be in Analysis
            List<AggregateResult> runResults = [
                SELECT Flow_API_Name__c 
                FROM FS_Flow_Run__c 
                WHERE Flow_API_Name__c != null
                GROUP BY Flow_API_Name__c
                ORDER BY Flow_API_Name__c
            ];
            
            for (AggregateResult result : runResults) {
                String flowName = (String)result.get('Flow_API_Name__c');
                flowNamesSet.add(flowName);
            }
            
            // Convert to options format
            for (String flowName : flowNamesSet) {
                Map<String, String> option = new Map<String, String>();
                option.put('label', flowName);
                option.put('value', flowName);
                flowOptions.add(option);
            }
            
        } catch (Exception e) {
            System.debug('Error in getAllFlowNames: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve flow names: ' + e.getMessage());
        }
        
        return flowOptions;
    }
    
    // Non-cacheable versions for refresh operations
    @AuraEnabled
    public static List<FlowAnalyticsWrapper> getFlowAnalyticsRefresh(Integer daysPast, String riskLevel, String searchTerm) {
        return getFlowAnalytics(daysPast, riskLevel, searchTerm);
    }
    
    @AuraEnabled
    public static PerformanceMetrics getPerformanceMetricsRefresh(Integer daysPast) {
        return getPerformanceMetrics(daysPast);
    }
    
    @AuraEnabled
    public static List<Map<String, String>> getAllFlowNamesRefresh() {
        return getAllFlowNames();
    }
    
    @AuraEnabled
    public static FlowDetailWrapper getFlowDetails(String flowName) {
        FlowDetailWrapper details = new FlowDetailWrapper();
        
        try {
            // Get latest flow analysis
            List<FS_Flow_Analysis__c> analyses = [
                SELECT Id, Flow_API_Name__c, Performance_Score__c, Risk_Level__c,
                       Complexity_Score__c, Analysis_Date__c
                FROM FS_Flow_Analysis__c 
                WHERE Flow_API_Name__c = :flowName
                ORDER BY Analysis_Date__c DESC
                LIMIT 1
            ];
            
            if (!analyses.isEmpty()) {
                FS_Flow_Analysis__c analysis = analyses[0];
                details.flowName = analysis.Flow_API_Name__c;
                details.performanceScore = analysis.Performance_Score__c != null ? analysis.Performance_Score__c.intValue() : 0;
                details.riskLevel = analysis.Risk_Level__c;
                details.complexityScore = analysis.Complexity_Score__c != null ? analysis.Complexity_Score__c.intValue() : 0;
                details.lastAnalysisDate = analysis.Analysis_Date__c;
                details.analysisSummary = 'Analysis completed on ' + analysis.Analysis_Date__c.format();
            } else {
                details.flowName = flowName;
                details.performanceScore = 0;
                details.riskLevel = 'Unknown';
                details.complexityScore = 0;
            }
            
            // Get execution statistics (last 30 days)
            DateTime thirtyDaysAgo = DateTime.now().addDays(-30);
            
            List<AggregateResult> execStats = [
                SELECT COUNT(Id) totalRuns, AVG(Duration_Ms__c) avgDuration,
                       MIN(Duration_Ms__c) minDuration, MAX(Duration_Ms__c) maxDuration,
                       AVG(CPU_Time_Millis__c) avgCpuTime, AVG(SOQL_Count__c) avgSoql,
                       AVG(DML_Count__c) avgDml
                FROM FS_Flow_Run__c 
                WHERE Flow_API_Name__c = :flowName 
                AND Started_At__c >= :thirtyDaysAgo
            ];
            
            if (!execStats.isEmpty() && execStats[0].get('totalRuns') != null) {
                details.totalExecutions = (Integer)execStats[0].get('totalRuns');
                details.averageDuration = execStats[0].get('avgDuration') != null ? 
                    ((Decimal)execStats[0].get('avgDuration')).intValue() : 0;
                details.minDuration = execStats[0].get('minDuration') != null ? 
                    ((Decimal)execStats[0].get('minDuration')).intValue() : 0;
                details.maxDuration = execStats[0].get('maxDuration') != null ? 
                    ((Decimal)execStats[0].get('maxDuration')).intValue() : 0;
                details.averageCpuTime = execStats[0].get('avgCpuTime') != null ? 
                    ((Decimal)execStats[0].get('avgCpuTime')).intValue() : 0;
                details.averageSoqlCount = execStats[0].get('avgSoql') != null ? 
                    ((Decimal)execStats[0].get('avgSoql')).intValue() : 0;
                details.averageDmlCount = execStats[0].get('avgDml') != null ? 
                    ((Decimal)execStats[0].get('avgDml')).intValue() : 0;
            }
            
            // Get recent execution trend (last 7 days)
            DateTime sevenDaysAgo = DateTime.now().addDays(-7);
            
            List<AggregateResult> recentTrend = [
                SELECT COUNT(Id) recentRuns
                FROM FS_Flow_Run__c 
                WHERE Flow_API_Name__c = :flowName 
                AND Started_At__c >= :sevenDaysAgo
            ];
            
            if (!recentTrend.isEmpty() && recentTrend[0].get('recentRuns') != null) {
                details.recentExecutions = (Integer)recentTrend[0].get('recentRuns');
            }
            
        } catch (Exception e) {
            System.debug('Error in getFlowDetails: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve flow details: ' + e.getMessage());
        }
        
        return details;
    }
    
    @AuraEnabled
    public static String triggerFlowAnalysis(String flowName) {
        try {
            // Get or create a flow run for this flow
            List<FS_Flow_Run__c> flowRuns = [
                SELECT Id, Duration_Ms__c, CPU_Time_Millis__c, SOQL_Count__c, DML_Count__c, Status__c
                FROM FS_Flow_Run__c 
                WHERE Flow_API_Name__c = :flowName 
                ORDER BY Started_At__c DESC
                LIMIT 1
            ];
            
            Id flowRunId;
            Decimal avgDuration = 0;
            Decimal cpuTime = 0;
            Integer soqlCount = 0;
            Integer dmlCount = 0;
            
            if (!flowRuns.isEmpty()) {
                FS_Flow_Run__c latestRun = flowRuns[0];
                flowRunId = latestRun.Id;
                avgDuration = latestRun.Duration_Ms__c != null ? latestRun.Duration_Ms__c : 0;
                cpuTime = latestRun.CPU_Time_Millis__c != null ? latestRun.CPU_Time_Millis__c : 0;
                soqlCount = latestRun.SOQL_Count__c != null ? latestRun.SOQL_Count__c.intValue() : 0;
                dmlCount = latestRun.DML_Count__c != null ? latestRun.DML_Count__c.intValue() : 0;
            } else {
                // Create a minimal flow run for analysis
                FS_Flow_Run__c dummyRun = new FS_Flow_Run__c();
                dummyRun.Flow_API_Name__c = flowName;
                dummyRun.Interview_ID__c = 'dashboard-analysis-' + System.currentTimeMillis();
                dummyRun.Status__c = 'Success';
                dummyRun.Started_At__c = System.now();
                dummyRun.Duration_Ms__c = 0;
                insert dummyRun;
                flowRunId = dummyRun.Id;
            }
            
            // Calculate performance metrics
            Decimal performanceScore = calculatePerformanceScore(avgDuration, cpuTime, soqlCount, dmlCount);
            Decimal riskScore = calculateRiskScore(avgDuration, cpuTime, soqlCount, dmlCount);
            String riskLevel = getRiskLevel(riskScore);
            Decimal complexityScore = calculateComplexityScore(soqlCount, dmlCount);
            
            // Generate recommendations
            String recommendations = generateRecommendations(avgDuration, cpuTime, soqlCount, dmlCount);
            
            // Generate AI summary
            String aiSummary = generateAISummary(flowName, performanceScore, riskLevel, avgDuration);
            
            // Create analysis data JSON
            String analysisData = generateAnalysisData(avgDuration, cpuTime, soqlCount, dmlCount);
            
            // Create a comprehensive analysis record
            FS_Flow_Analysis__c newAnalysis = new FS_Flow_Analysis__c();
            newAnalysis.Flow_API_Name__c = flowName;
            newAnalysis.Flow_Run__c = flowRunId;
            newAnalysis.Analysis_Type__c = 'Performance';
            newAnalysis.Analysis_Date__c = DateTime.now();
            newAnalysis.Analyzed_At__c = DateTime.now();
            newAnalysis.Status__c = 'Completed';
            newAnalysis.Performance_Score__c = performanceScore;
            newAnalysis.Risk_Score__c = riskScore;
            newAnalysis.Risk_Level__c = riskLevel;
            newAnalysis.Complexity_Score__c = complexityScore;
            newAnalysis.Recommendations__c = recommendations;
            newAnalysis.AI_Summary__c = aiSummary;
            newAnalysis.Analysis_Data__c = analysisData;
            
            insert newAnalysis;
            
            return 'Comprehensive analysis completed for ' + flowName + 
                   '. Performance Score: ' + performanceScore.intValue() + 
                   '%, Risk Level: ' + riskLevel + '.';
            
        } catch (Exception e) {
            System.debug('Error in triggerFlowAnalysis: ' + e.getMessage());
            throw new AuraHandledException('Failed to trigger analysis: ' + e.getMessage());
        }
    }
    
    private static Decimal calculatePerformanceScore(Decimal duration, Decimal cpuTime, Integer soql, Integer dml) {
        Decimal score = 100;
        
        // Reduce score based on execution time
        if (duration > 10000) score -= 30;       // > 10s
        else if (duration > 5000) score -= 20;   // > 5s
        else if (duration > 2000) score -= 10;   // > 2s
        
        // Reduce score based on CPU time
        if (cpuTime > 5000) score -= 20;         // > 5s
        else if (cpuTime > 2000) score -= 10;    // > 2s
        
        // Reduce score based on SOQL count
        if (soql > 100) score -= 25;             // > 100 queries
        else if (soql > 50) score -= 15;         // > 50 queries
        else if (soql > 20) score -= 5;          // > 20 queries
        
        // Reduce score based on DML count
        if (dml > 150) score -= 20;              // > 150 DML
        else if (dml > 100) score -= 10;         // > 100 DML
        
        return Math.max(score, 0);
    }
    
    private static Decimal calculateRiskScore(Decimal duration, Decimal cpuTime, Integer soql, Integer dml) {
        Decimal risk = 0;
        
        // Risk factors
        if (duration > 10000) risk += 3;
        if (cpuTime > 5000) risk += 2.5;
        if (soql > 100) risk += 3;
        if (dml > 150) risk += 2;
        
        return Math.min(risk, 10);
    }
    
    private static String getRiskLevel(Decimal riskScore) {
        if (riskScore >= 7) return 'High';
        if (riskScore >= 4) return 'Medium';
        return 'Low';
    }
    
    private static Decimal calculateComplexityScore(Integer soql, Integer dml) {
        return Math.min((soql * 0.5) + (dml * 0.3), 100);
    }
    
    private static String generateRecommendations(Decimal duration, Decimal cpuTime, Integer soql, Integer dml) {
        List<String> recommendations = new List<String>();
        
        if (duration > 5000) {
            recommendations.add('Consider optimizing flow logic to reduce execution time');
        }
        if (cpuTime > 2000) {
            recommendations.add('Review CPU-intensive operations and consider bulkification');
        }
        if (soql > 50) {
            recommendations.add('Reduce SOQL queries by using collections and bulk operations');
        }
        if (dml > 100) {
            recommendations.add('Optimize DML operations by batching records');
        }
        if (recommendations.isEmpty()) {
            recommendations.add('Flow performance is optimal. No immediate optimizations needed');
        }
        
        return String.join(recommendations, '. ') + '.';
    }
    
    private static String generateAISummary(String flowName, Decimal performanceScore, String riskLevel, Decimal duration) {
        String performanceLevel = performanceScore >= 80 ? 'excellent' : 
                                 performanceScore >= 60 ? 'good' : 'needs improvement';
        
        return 'FlowSense AI Analysis: ' + flowName + ' shows ' + performanceLevel + 
               ' performance with a score of ' + performanceScore.intValue() + '%. ' +
               'Risk level is ' + riskLevel.toLowerCase() + 
               '. Average execution time is ' + duration.intValue() + 'ms. ' +
               (performanceScore < 70 ? 'Optimization recommended to improve user experience.' :
                'Performance is within acceptable parameters.');
    }
    
    private static String generateAnalysisData(Decimal duration, Decimal cpuTime, Integer soql, Integer dml) {
        Map<String, Object> metrics = new Map<String, Object>();
        metrics.put('avgDuration', duration);
        metrics.put('cpuTime', cpuTime);
        metrics.put('soqlCount', soql);
        metrics.put('dmlCount', dml);
        metrics.put('analysisTimestamp', System.now().getTime());
        
        Map<String, Object> data = new Map<String, Object>();
        data.put('metrics', metrics);
        data.put('version', '2.0');
        data.put('source', 'Dashboard Analysis');
        
        return JSON.serialize(data);
    }
    
    @AuraEnabled(cacheable=true)
    public static PerformanceMetrics getPerformanceMetrics(Integer daysPast) {
        PerformanceMetrics metrics = new PerformanceMetrics();
        
        try {
            DateTime startDate = DateTime.now().addDays(-daysPast);
            
            // Get flow run statistics
            List<AggregateResult> runStats = [
                SELECT COUNT(Id) totalRuns, AVG(Duration_Ms__c) avgDuration
                FROM FS_Flow_Run__c 
                WHERE Started_At__c >= :startDate
            ];
            
            if (!runStats.isEmpty() && runStats[0].get('totalRuns') != null) {
                metrics.totalExecutions = (Integer)runStats[0].get('totalRuns');
                metrics.averageExecutionTime = runStats[0].get('avgDuration') != null ? 
                    ((Decimal)runStats[0].get('avgDuration')).intValue() : 0;
            }
            
            // Get performance score statistics
            List<AggregateResult> analysisStats = [
                SELECT AVG(Performance_Score__c) avgScore, COUNT(Id) totalAnalyses
                FROM FS_Flow_Analysis__c 
                WHERE Analysis_Date__c >= :startDate
            ];
            
            if (!analysisStats.isEmpty() && analysisStats[0].get('avgScore') != null) {
                metrics.averagePerformanceScore = ((Decimal)analysisStats[0].get('avgScore')).intValue();
            }
            
            // Get high risk flow count
            List<AggregateResult> highRiskStats = [
                SELECT COUNT(Id) highRiskCount
                FROM FS_Flow_Analysis__c 
                WHERE Analysis_Date__c >= :startDate 
                AND Risk_Level__c IN ('High', 'Critical')
            ];
            
            if (!highRiskStats.isEmpty() && highRiskStats[0].get('highRiskCount') != null) {
                metrics.highRiskFlows = (Integer)highRiskStats[0].get('highRiskCount');
            }
            
        } catch (Exception e) {
            System.debug('Error in getPerformanceMetrics: ' + e.getMessage());
            throw new AuraHandledException('Failed to retrieve performance metrics: ' + e.getMessage());
        }
        
        return metrics;
    }
    
    private static Map<String, FlowExecutionStats> getFlowExecutionStats(Set<String> flowNames, Integer daysPast) {
        Map<String, FlowExecutionStats> statsMap = new Map<String, FlowExecutionStats>();
        
        if (flowNames.isEmpty()) {
            return statsMap;
        }
        
        DateTime startDate = DateTime.now().addDays(-daysPast);
        
        List<AggregateResult> results = [
            SELECT Flow_API_Name__c, COUNT(Id) execCount, AVG(Duration_Ms__c) avgDuration
            FROM FS_Flow_Run__c 
            WHERE Flow_API_Name__c IN :flowNames 
            AND Started_At__c >= :startDate
            GROUP BY Flow_API_Name__c
        ];
        
        for (AggregateResult result : results) {
            String flowName = (String)result.get('Flow_API_Name__c');
            FlowExecutionStats stats = new FlowExecutionStats();
            stats.executionCount = (Integer)result.get('execCount');
            stats.averageDuration = result.get('avgDuration') != null ? 
                ((Decimal)result.get('avgDuration')).intValue() : 0;
            statsMap.put(flowName, stats);
        }
        
        return statsMap;
    }
    
    public class FlowAnalyticsWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String flowName;
        @AuraEnabled public DateTime lastExecution;
        @AuraEnabled public Integer performanceScore;
        @AuraEnabled public String riskLevel;
        @AuraEnabled public Integer averageDuration;
        @AuraEnabled public Integer executionCount;
    }
    
    public class PerformanceMetrics {
        @AuraEnabled public Integer totalExecutions = 0;
        @AuraEnabled public Integer averagePerformanceScore = 0;
        @AuraEnabled public Integer highRiskFlows = 0;
        @AuraEnabled public Integer averageExecutionTime = 0;
    }
    
    public class FlowDetailWrapper {
        @AuraEnabled public String flowName;
        @AuraEnabled public Integer performanceScore;
        @AuraEnabled public String riskLevel;
        @AuraEnabled public Integer complexityScore;
        @AuraEnabled public DateTime lastAnalysisDate;
        @AuraEnabled public String analysisSummary;
        @AuraEnabled public Integer totalExecutions;
        @AuraEnabled public Integer averageDuration;
        @AuraEnabled public Integer minDuration;
        @AuraEnabled public Integer maxDuration;
        @AuraEnabled public Integer averageCpuTime;
        @AuraEnabled public Integer averageSoqlCount;
        @AuraEnabled public Integer averageDmlCount;
        @AuraEnabled public Integer recentExecutions;
    }
    
    private class FlowExecutionStats {
        public Integer executionCount = 0;
        public Integer averageDuration = 0;
    }
}