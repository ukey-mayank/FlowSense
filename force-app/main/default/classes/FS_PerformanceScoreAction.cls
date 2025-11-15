/**
 * @description Invocable action for calculating performance scores for flows
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_PerformanceScoreAction {
    
    @InvocableMethod(label='Calculate Performance Score' description='Calculate performance score for a flow execution' category='FlowSense')
    public static List<Result> calculatePerformanceScore(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        try {
            for (Request request : requests) {
                Result result = calculateScore(request);
                results.add(result);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in FS_PerformanceScoreAction: ' + e.getMessage());
            
            for (Request request : requests) {
                Result result = new Result();
                result.isSuccess = false;
                result.errorMessage = 'Failed to calculate performance score: ' + e.getMessage();
                result.overallScore = 0;
                results.add(result);
            }
        }
        
        return results;
    }
    
    /**
     * @description Calculate performance score for a single request
     * @param request The performance score request
     * @return Result with calculated score
     */
    @TestVisible
    private static Result calculateScore(Request request) {
        Result result = new Result();
        result.isSuccess = true;
        
        try {
            // Get performance thresholds from settings
            PerformanceThresholds thresholds = getPerformanceThresholds();
            
            // Calculate individual component scores
            Decimal cpuScore = calculateCpuScore(request.cpuTimeMillis, thresholds);
            Decimal soqlScore = calculateSoqlScore(request.soqlCount, thresholds);
            Decimal dmlScore = calculateDmlScore(request.dmlCount, thresholds);
            Decimal durationScore = calculateDurationScore(request.executionTimeMillis, thresholds);
            Decimal heapScore = calculateHeapScore(request.heapSizeBytes, thresholds);
            
            // Calculate weighted overall score
            ScoreWeights weights = getScoreWeights();
            Decimal overallScore = (cpuScore * weights.cpuWeight +
                                   soqlScore * weights.soqlWeight +
                                   dmlScore * weights.dmlWeight +
                                   durationScore * weights.durationWeight +
                                   heapScore * weights.heapWeight) / weights.totalWeight;
            
            // Round to 2 decimal places
            overallScore = overallScore.setScale(2);
            
            // Determine performance grade
            String grade = calculateGrade(overallScore);
            
            // Set result values
            result.overallScore = overallScore;
            result.cpuScore = cpuScore.setScale(2);
            result.soqlScore = soqlScore.setScale(2);
            result.dmlScore = dmlScore.setScale(2);
            result.durationScore = durationScore.setScale(2);
            result.heapScore = heapScore.setScale(2);
            result.performanceGrade = grade;
            result.scoreBreakdown = buildScoreBreakdown(result, request, thresholds);
            result.recommendations = generateRecommendations(result, request, thresholds);
            
            // Check if any critical thresholds are exceeded
            result.criticalIssuesFound = checkCriticalIssues(request, thresholds);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error calculating performance score: ' + e.getMessage());
            result.isSuccess = false;
            result.errorMessage = e.getMessage();
            result.overallScore = 0;
        }
        
        return result;
    }
    
    /**
     * @description Calculate CPU performance score
     * @param cpuTime CPU time in milliseconds
     * @param thresholds Performance thresholds
     * @return CPU score (0-100)
     */
    private static Decimal calculateCpuScore(Decimal cpuTime, PerformanceThresholds thresholds) {
        if (cpuTime == null || cpuTime <= 0) {
            return 100;
        }
        
        if (cpuTime <= thresholds.cpuExcellent) {
            return 100;
        } else if (cpuTime <= thresholds.cpuGood) {
            return 80 + (20 * (thresholds.cpuGood - cpuTime) / (thresholds.cpuGood - thresholds.cpuExcellent));
        } else if (cpuTime <= thresholds.cpuFair) {
            return 60 + (20 * (thresholds.cpuFair - cpuTime) / (thresholds.cpuFair - thresholds.cpuGood));
        } else if (cpuTime <= thresholds.cpuPoor) {
            return 40 + (20 * (thresholds.cpuPoor - cpuTime) / (thresholds.cpuPoor - thresholds.cpuFair));
        } else {
            return Math.max(0, 40 - (cpuTime - thresholds.cpuPoor) / 100);
        }
    }
    
    /**
     * @description Calculate SOQL performance score
     * @param soqlCount Number of SOQL queries
     * @param thresholds Performance thresholds
     * @return SOQL score (0-100)
     */
    private static Decimal calculateSoqlScore(Decimal soqlCount, PerformanceThresholds thresholds) {
        if (soqlCount == null || soqlCount <= 0) {
            return 100;
        }
        
        if (soqlCount <= thresholds.soqlExcellent) {
            return 100;
        } else if (soqlCount <= thresholds.soqlGood) {
            return 80 + (20 * (thresholds.soqlGood - soqlCount) / (thresholds.soqlGood - thresholds.soqlExcellent));
        } else if (soqlCount <= thresholds.soqlFair) {
            return 60 + (20 * (thresholds.soqlFair - soqlCount) / (thresholds.soqlFair - thresholds.soqlGood));
        } else if (soqlCount <= thresholds.soqlPoor) {
            return 40 + (20 * (thresholds.soqlPoor - soqlCount) / (thresholds.soqlPoor - thresholds.soqlFair));
        } else {
            return Math.max(0, 40 - (soqlCount - thresholds.soqlPoor) * 2);
        }
    }
    
    /**
     * @description Calculate DML performance score
     * @param dmlCount Number of DML operations
     * @param thresholds Performance thresholds
     * @return DML score (0-100)
     */
    private static Decimal calculateDmlScore(Decimal dmlCount, PerformanceThresholds thresholds) {
        if (dmlCount == null || dmlCount <= 0) {
            return 100;
        }
        
        if (dmlCount <= thresholds.dmlExcellent) {
            return 100;
        } else if (dmlCount <= thresholds.dmlGood) {
            return 80 + (20 * (thresholds.dmlGood - dmlCount) / (thresholds.dmlGood - thresholds.dmlExcellent));
        } else if (dmlCount <= thresholds.dmlFair) {
            return 60 + (20 * (thresholds.dmlFair - dmlCount) / (thresholds.dmlFair - thresholds.dmlGood));
        } else if (dmlCount <= thresholds.dmlPoor) {
            return 40 + (20 * (thresholds.dmlPoor - dmlCount) / (thresholds.dmlPoor - thresholds.dmlFair));
        } else {
            return Math.max(0, 40 - (dmlCount - thresholds.dmlPoor) * 3);
        }
    }
    
    /**
     * @description Calculate duration performance score
     * @param duration Execution duration in milliseconds
     * @param thresholds Performance thresholds
     * @return Duration score (0-100)
     */
    private static Decimal calculateDurationScore(Decimal duration, PerformanceThresholds thresholds) {
        if (duration == null || duration <= 0) {
            return 100;
        }
        
        if (duration <= thresholds.durationExcellent) {
            return 100;
        } else if (duration <= thresholds.durationGood) {
            return 80 + (20 * (thresholds.durationGood - duration) / (thresholds.durationGood - thresholds.durationExcellent));
        } else if (duration <= thresholds.durationFair) {
            return 60 + (20 * (thresholds.durationFair - duration) / (thresholds.durationFair - thresholds.durationGood));
        } else if (duration <= thresholds.durationPoor) {
            return 40 + (20 * (thresholds.durationPoor - duration) / (thresholds.durationPoor - thresholds.durationFair));
        } else {
            return Math.max(0, 40 - (duration - thresholds.durationPoor) / 200);
        }
    }
    
    /**
     * @description Calculate heap size performance score
     * @param heapSize Heap size in bytes
     * @param thresholds Performance thresholds
     * @return Heap score (0-100)
     */
    private static Decimal calculateHeapScore(Decimal heapSize, PerformanceThresholds thresholds) {
        if (heapSize == null || heapSize <= 0) {
            return 100;
        }
        
        // Convert bytes to MB for comparison
        Decimal heapMB = heapSize / (1024 * 1024);
        
        if (heapMB <= thresholds.heapExcellent) {
            return 100;
        } else if (heapMB <= thresholds.heapGood) {
            return 80 + (20 * (thresholds.heapGood - heapMB) / (thresholds.heapGood - thresholds.heapExcellent));
        } else if (heapMB <= thresholds.heapFair) {
            return 60 + (20 * (thresholds.heapFair - heapMB) / (thresholds.heapFair - thresholds.heapGood));
        } else if (heapMB <= thresholds.heapPoor) {
            return 40 + (20 * (thresholds.heapPoor - heapMB) / (thresholds.heapPoor - thresholds.heapFair));
        } else {
            return Math.max(0, 40 - (heapMB - thresholds.heapPoor));
        }
    }
    
    /**
     * @description Calculate performance grade based on overall score
     * @param score Overall performance score
     * @return Performance grade (A-F)
     */
    private static String calculateGrade(Decimal score) {
        if (score >= 90) {
            return 'A';
        } else if (score >= 80) {
            return 'B';
        } else if (score >= 70) {
            return 'C';
        } else if (score >= 60) {
            return 'D';
        } else {
            return 'F';
        }
    }
    
    /**
     * @description Build detailed score breakdown
     * @param result The result object
     * @param request The original request
     * @param thresholds Performance thresholds
     * @return Score breakdown text
     */
    private static String buildScoreBreakdown(Result result, Request request, PerformanceThresholds thresholds) {
        String breakdown = 'Performance Score Breakdown:\n';
        breakdown += '• Overall Score: ' + result.overallScore + '/100 (Grade: ' + result.performanceGrade + ')\n';
        breakdown += '• CPU Time: ' + result.cpuScore + '/100 (' + (request.cpuTimeMillis != null ? request.cpuTimeMillis + 'ms' : 'N/A') + ')\n';
        breakdown += '• SOQL Queries: ' + result.soqlScore + '/100 (' + (request.soqlCount != null ? request.soqlCount + ' queries' : 'N/A') + ')\n';
        breakdown += '• DML Operations: ' + result.dmlScore + '/100 (' + (request.dmlCount != null ? request.dmlCount + ' operations' : 'N/A') + ')\n';
        breakdown += '• Execution Time: ' + result.durationScore + '/100 (' + (request.executionTimeMillis != null ? request.executionTimeMillis + 'ms' : 'N/A') + ')\n';
        breakdown += '• Heap Usage: ' + result.heapScore + '/100 (' + (request.heapSizeBytes != null ? (request.heapSizeBytes / (1024 * 1024)).setScale(2) + 'MB' : 'N/A') + ')';
        
        return breakdown;
    }
    
    /**
     * @description Generate performance recommendations
     * @param result The result object
     * @param request The original request
     * @param thresholds Performance thresholds
     * @return Performance recommendations
     */
    private static String generateRecommendations(Result result, Request request, PerformanceThresholds thresholds) {
        List<String> recommendations = new List<String>();
        
        if (result.cpuScore < 70 && request.cpuTimeMillis != null && request.cpuTimeMillis > thresholds.cpuFair) {
            recommendations.add('• Optimize CPU-intensive operations and reduce computational complexity');
        }
        
        if (result.soqlScore < 70 && request.soqlCount != null && request.soqlCount > thresholds.soqlFair) {
            recommendations.add('• Reduce SOQL queries by using bulk operations and query optimization');
        }
        
        if (result.dmlScore < 70 && request.dmlCount != null && request.dmlCount > thresholds.dmlFair) {
            recommendations.add('• Consolidate DML operations and use bulk processing patterns');
        }
        
        if (result.durationScore < 70 && request.executionTimeMillis != null && request.executionTimeMillis > thresholds.durationFair) {
            recommendations.add('• Optimize flow logic and consider asynchronous processing for long-running operations');
        }
        
        if (result.heapScore < 70 && request.heapSizeBytes != null && request.heapSizeBytes > (thresholds.heapFair * 1024 * 1024)) {
            recommendations.add('• Optimize memory usage by processing smaller data sets and clearing unused variables');
        }
        
        if (recommendations.isEmpty()) {
            recommendations.add('• Great job! Performance metrics are within acceptable ranges');
        }
        
        return 'Recommendations:\n' + String.join(recommendations, '\n');
    }
    
    /**
     * @description Check for critical performance issues
     * @param request The performance request
     * @param thresholds Performance thresholds
     * @return Boolean indicating if critical issues found
     */
    private static Boolean checkCriticalIssues(Request request, PerformanceThresholds thresholds) {
        Boolean criticalIssues = false;
        
        if (request.cpuTimeMillis != null && request.cpuTimeMillis > thresholds.cpuPoor) {
            criticalIssues = true;
        }
        
        if (request.soqlCount != null && request.soqlCount > thresholds.soqlPoor) {
            criticalIssues = true;
        }
        
        if (request.dmlCount != null && request.dmlCount > thresholds.dmlPoor) {
            criticalIssues = true;
        }
        
        if (request.executionTimeMillis != null && request.executionTimeMillis > thresholds.durationPoor) {
            criticalIssues = true;
        }
        
        if (request.heapSizeBytes != null && request.heapSizeBytes > (thresholds.heapPoor * 1024 * 1024)) {
            criticalIssues = true;
        }
        
        return criticalIssues;
    }
    
    /**
     * @description Get performance thresholds from settings
     * @return Performance thresholds
     */
    private static PerformanceThresholds getPerformanceThresholds() {
        // Using default thresholds - CMDT migration in progress
        // Future enhancement: Map CMDT Warning/Critical thresholds to performance grades
        PerformanceThresholds thresholds = new PerformanceThresholds();
        
        // CPU thresholds (milliseconds) - defaults
        thresholds.cpuExcellent = 1000;
        thresholds.cpuGood = 3000;
        thresholds.cpuFair = 5000;
        thresholds.cpuPoor = 8000;
        
        // SOQL thresholds (count) - defaults
        thresholds.soqlExcellent = 5;
        thresholds.soqlGood = 15;
        thresholds.soqlFair = 25;
        thresholds.soqlPoor = 40;
        
        // DML thresholds (count) - defaults
        thresholds.dmlExcellent = 5;
        thresholds.dmlGood = 15;
        thresholds.dmlFair = 25;
        thresholds.dmlPoor = 40;
        
        // Duration thresholds (milliseconds) - defaults
        thresholds.durationExcellent = 2000;
        thresholds.durationGood = 5000;
        thresholds.durationFair = 10000;
        thresholds.durationPoor = 20000;
        
        // Heap thresholds (MB) - defaults
        thresholds.heapExcellent = 1;
        thresholds.heapGood = 3;
        thresholds.heapFair = 5;
        thresholds.heapPoor = 8;
        
        return thresholds;
    }
    
    /**
     * @description Get score weights for weighted average calculation
     * @return Score weights
     */
    private static ScoreWeights getScoreWeights() {
        ScoreWeights weights = new ScoreWeights();
        weights.cpuWeight = 25;
        weights.soqlWeight = 20;
        weights.dmlWeight = 15;
        weights.durationWeight = 25;
        weights.heapWeight = 15;
        weights.totalWeight = weights.cpuWeight + weights.soqlWeight + weights.dmlWeight + 
                             weights.durationWeight + weights.heapWeight;
        
        return weights;
    }
    
    /**
     * @description Request wrapper for performance score calculation
     */
    public class Request {
        @InvocableVariable(label='CPU Time (ms)' description='CPU time consumed in milliseconds')
        public Decimal cpuTimeMillis;
        
        @InvocableVariable(label='SOQL Count' description='Number of SOQL queries executed')
        public Decimal soqlCount;
        
        @InvocableVariable(label='DML Count' description='Number of DML operations performed')
        public Decimal dmlCount;
        
        @InvocableVariable(label='Execution Time (ms)' description='Total execution time in milliseconds')
        public Decimal executionTimeMillis;
        
        @InvocableVariable(label='Heap Size (bytes)' description='Heap size used in bytes')
        public Decimal heapSizeBytes;
        
        @InvocableVariable(label='Flow API Name' description='API name of the flow for context')
        public String flowApiName;
        
        @InvocableVariable(label='Interview ID' description='Flow interview ID for reference')
        public String interviewId;
    }
    
    /**
     * @description Result wrapper for performance score calculation
     */
    public class Result {
        @InvocableVariable(label='Success' description='Indicates if score calculation was successful')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Overall Score' description='Overall performance score (0-100)')
        public Decimal overallScore;
        
        @InvocableVariable(label='CPU Score' description='CPU performance score (0-100)')
        public Decimal cpuScore;
        
        @InvocableVariable(label='SOQL Score' description='SOQL performance score (0-100)')
        public Decimal soqlScore;
        
        @InvocableVariable(label='DML Score' description='DML performance score (0-100)')
        public Decimal dmlScore;
        
        @InvocableVariable(label='Duration Score' description='Duration performance score (0-100)')
        public Decimal durationScore;
        
        @InvocableVariable(label='Heap Score' description='Heap usage performance score (0-100)')
        public Decimal heapScore;
        
        @InvocableVariable(label='Performance Grade' description='Performance grade (A-F)')
        public String performanceGrade;
        
        @InvocableVariable(label='Score Breakdown' description='Detailed breakdown of all scores')
        public String scoreBreakdown;
        
        @InvocableVariable(label='Recommendations' description='Performance optimization recommendations')
        public String recommendations;
        
        @InvocableVariable(label='Critical Issues Found' description='Indicates if critical performance issues were found')
        public Boolean criticalIssuesFound;
        
        @InvocableVariable(label='Error Message' description='Error message if calculation failed')
        public String errorMessage;
    }
    
    /**
     * @description Performance thresholds wrapper
     */
    private class PerformanceThresholds {
        public Decimal cpuExcellent = 1000;
        public Decimal cpuGood = 3000;
        public Decimal cpuFair = 5000;
        public Decimal cpuPoor = 8000;
        
        public Decimal soqlExcellent = 5;
        public Decimal soqlGood = 15;
        public Decimal soqlFair = 25;
        public Decimal soqlPoor = 40;
        
        public Decimal dmlExcellent = 5;
        public Decimal dmlGood = 15;
        public Decimal dmlFair = 25;
        public Decimal dmlPoor = 40;
        
        public Decimal durationExcellent = 2000;
        public Decimal durationGood = 5000;
        public Decimal durationFair = 10000;
        public Decimal durationPoor = 20000;
        
        public Decimal heapExcellent = 1;
        public Decimal heapGood = 3;
        public Decimal heapFair = 5;
        public Decimal heapPoor = 8;
    }
    
    /**
     * @description Score weights wrapper
     */
    private class ScoreWeights {
        public Decimal cpuWeight;
        public Decimal soqlWeight;
        public Decimal dmlWeight;
        public Decimal durationWeight;
        public Decimal heapWeight;
        public Decimal totalWeight;
    }
}