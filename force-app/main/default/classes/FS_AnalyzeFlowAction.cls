/**
 * @description Simple Flow Analysis Action - Logs analysis to debug logs
 * @author FlowSense
 * @date 2024
 */
public with sharing class FS_AnalyzeFlowAction {
    
    @InvocableMethod(label='Analyze Flow Performance' description='Analyzes flow performance and logs results')
    public static List<Result> analyzeFlow(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        for (Request request : requests) {
            try {
                // Handle null flowApiName
                if (String.isBlank(request.flowApiName)) {
                    Result result = new Result();
                    result.isSuccess = false;
                    result.errorMessage = 'Flow API Name is required';
                    results.add(result);
                    continue;
                }
                
                // Simple analysis logic
                Double performanceScore = calculatePerformanceScore(request);
                Double complexityScore = calculateComplexityScore(request);
                String riskLevel = determineRiskLevel(performanceScore, complexityScore);
                
                // Create or find Flow Run record (required for Flow Analysis)
                Id flowRunId;
                try {
                    FS_Flow_Run__c dummyRun = new FS_Flow_Run__c();
                    dummyRun.Flow_API_Name__c = request.flowApiName;
                    dummyRun.Interview_ID__c = 'analysis-' + System.currentTimeMillis();
                    dummyRun.Status__c = 'Success'; // Valid picklist value
                    insert dummyRun;
                    flowRunId = dummyRun.Id;
                } catch (Exception runException) {
                    Result result = new Result();
                    result.isSuccess = false;
                    result.errorMessage = 'Unable to create flow run: ' + runException.getMessage();
                    results.add(result);
                    continue;
                }
                
                // Create Flow Analysis record
                FS_Flow_Analysis__c analysis = new FS_Flow_Analysis__c();
                analysis.Flow_API_Name__c = request.flowApiName;
                analysis.Flow_Run__c = flowRunId;
                analysis.Analysis_Date__c = System.now();
                analysis.Analysis_Type__c = 'Performance'; // Valid picklist value
                analysis.Performance_Score__c = performanceScore;
                analysis.Complexity_Score__c = complexityScore;
                analysis.Risk_Level__c = riskLevel;
                analysis.Status__c = 'Completed';
                
                insert analysis;
                
                // Also log the analysis to debug logs
                System.debug('FlowSense Analysis for ' + request.flowApiName);
                System.debug('Performance Score: ' + performanceScore);
                System.debug('Complexity Score: ' + complexityScore);
                System.debug('Risk Level: ' + riskLevel);
                
                Result result = new Result();
                result.isSuccess = true;
                result.analysisId = analysis.Id;
                result.performanceScore = performanceScore;
                result.complexityScore = complexityScore;
                result.riskLevel = riskLevel;
                result.message = 'Analysis completed successfully for ' + request.flowApiName;
                results.add(result);
                
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'FS_AnalyzeFlowAction Error: ' + e.getMessage());
                System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + e.getStackTraceString());
                Result result = new Result();
                result.isSuccess = false;
                result.errorMessage = e.getMessage() + ' | Stack: ' + e.getStackTraceString();
                results.add(result);
            }
        }
        
        return results;
    }
    
    private static Double calculatePerformanceScore(Request request) {
        // Simple scoring algorithm
        Double score = 100.0;
        
        if (request.executionTimeSeconds != null) {
            if (request.executionTimeSeconds > 30) {
                score -= 30;
            } else if (request.executionTimeSeconds > 10) {
                score -= 15;
            } else if (request.executionTimeSeconds > 5) {
                score -= 5;
            }
        }
        
        if (request.elementCount != null) {
            if (request.elementCount > 50) {
                score -= 20;
            } else if (request.elementCount > 25) {
                score -= 10;
            }
        }
        
        return Math.max(score, 0);
    }
    
    private static Double calculateComplexityScore(Request request) {
        Double score = 0.0;
        
        if (request.elementCount != null) {
            score += request.elementCount * 2;
        }
        
        if (request.loopCount != null) {
            score += request.loopCount * 10;
        }
        
        if (request.subflowCount != null) {
            score += request.subflowCount * 5;
        }
        
        return score;
    }
    
    private static String determineRiskLevel(Double performanceScore, Double complexityScore) {
        if (performanceScore < 50 || complexityScore > 100) {
            return 'High';
        } else if (performanceScore < 75 || complexityScore > 50) {
            return 'Medium';
        } else {
            return 'Low';
        }
    }
    
    public class Request {
        @InvocableVariable(label='Flow API Name' required=true)
        public String flowApiName;
        
        @InvocableVariable(label='Execution Time (Seconds)')
        public Double executionTimeSeconds;
        
        @InvocableVariable(label='Element Count')
        public Integer elementCount;
        
        @InvocableVariable(label='Loop Count')
        public Integer loopCount;
        
        @InvocableVariable(label='Subflow Count')
        public Integer subflowCount;
    }
    
    public class Result {
        @InvocableVariable(label='Success')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Analysis ID')
        public String analysisId;
        
        @InvocableVariable(label='Performance Score')
        public Double performanceScore;
        
        @InvocableVariable(label='Complexity Score')
        public Double complexityScore;
        
        @InvocableVariable(label='Risk Level')
        public String riskLevel;
        
        @InvocableVariable(label='Message')
        public String message;
        
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
    
    private static String generateRecommendations(String riskLevel, Integer performanceScore, Integer complexityScore) {
        List<String> recommendations = new List<String>();
        
        if (performanceScore < 70) {
            recommendations.add('Consider optimizing database queries and reducing SOQL operations');
            recommendations.add('Review loop structures for potential bulk processing opportunities');
        }
        
        if (complexityScore > 70) {
            recommendations.add('Consider breaking down complex flow into smaller, reusable subflows');
            recommendations.add('Review decision logic for simplification opportunities');
        }
        
        if (riskLevel == 'High' || riskLevel == 'Critical') {
            recommendations.add('Priority review recommended - consider immediate optimization');
            recommendations.add('Enable enhanced debug logging for detailed performance analysis');
        }
        
        if (recommendations.isEmpty()) {
            recommendations.add('Flow is performing well - no immediate optimizations needed');
        }
        
        return String.join(recommendations, '\n• ');
    }
}