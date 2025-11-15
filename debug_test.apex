// Simple debug test to understand what's happening
FS_AnalyzeFlowAction.Request request = new FS_AnalyzeFlowAction.Request();
request.flowApiName = 'Test_Flow_Debug';

List<FS_AnalyzeFlowAction.Result> results = FS_AnalyzeFlowAction.analyzeFlow(
    new List<FS_AnalyzeFlowAction.Request>{ request }
);

System.debug('Results size: ' + results.size());
if (results.size() > 0) {
    FS_AnalyzeFlowAction.Result result = results[0];
    System.debug('IsSuccess: ' + result.isSuccess);
    System.debug('Error Message: ' + result.errorMessage);
    System.debug('Analysis ID: ' + result.analysisId);
    System.debug('Performance Score: ' + result.performanceScore);
}