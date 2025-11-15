// Debug test for the failing assertion tests
FS_AnalyzeFlowAction.Request request1 = new FS_AnalyzeFlowAction.Request();
request1.flowApiName = 'AI_Summary_Test';
request1.executionTimeSeconds = 5.0;
request1.elementCount = 15;

List<FS_AnalyzeFlowAction.Result> results1 = FS_AnalyzeFlowAction.analyzeFlow(
    new List<FS_AnalyzeFlowAction.Request>{ request1 }
);

if (results1.size() > 0 && results1[0].isSuccess) {
    FS_Flow_Analysis__c analysis1 = [SELECT AI_Summary__c, Performance_Score__c FROM FS_Flow_Analysis__c WHERE Id = :results1[0].analysisId];
    System.debug('=== AI SUMMARY TEST ===');
    System.debug('Performance Score: ' + analysis1.Performance_Score__c);
    System.debug('AI Summary: ' + analysis1.AI_Summary__c);
    System.debug('Contains actual score: ' + analysis1.AI_Summary__c.contains(String.valueOf(analysis1.Performance_Score__c)));
}

// Test recommendations
FS_AnalyzeFlowAction.Request request2 = new FS_AnalyzeFlowAction.Request();
request2.flowApiName = 'Recommendations_Test';
request2.executionTimeSeconds = 25.0; // Poor performance
request2.elementCount = 40; // High complexity

List<FS_AnalyzeFlowAction.Result> results2 = FS_AnalyzeFlowAction.analyzeFlow(
    new List<FS_AnalyzeFlowAction.Request>{ request2 }
);

if (results2.size() > 0 && results2[0].isSuccess) {
    FS_Flow_Analysis__c analysis2 = [SELECT Recommendations__c FROM FS_Flow_Analysis__c WHERE Id = :results2[0].analysisId];
    System.debug('=== RECOMMENDATIONS TEST ===');
    System.debug('Recommendations: ' + analysis2.Recommendations__c);
    System.debug('Contains optimizing: ' + analysis2.Recommendations__c.contains('optimizing'));
    System.debug('Contains breaking down: ' + analysis2.Recommendations__c.contains('breaking down'));
}