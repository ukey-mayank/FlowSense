/**
 * @description Simplified Document Service for LWC demo purposes
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_SimpleDocumentService {
    
    /**
     * @description Get demo document list for LWC
     * @return List of demo documents
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getDemoDocuments() {
        List<Map<String, Object>> demoDocuments = new List<Map<String, Object>>();
        
        // Return demo data for UI testing
        demoDocuments.add(new Map<String, Object>{
            'Id' => 'demo1',
            'Title' => 'Flow Documentation Template',
            'DocumentType' => 'flow_doc',
            'Description' => 'Template for documenting Salesforce Flow logic and business requirements.',
            'LastModifiedDate' => System.today().addDays(-2),
            'ContentSize' => '2.4 KB'
        });
        
        demoDocuments.add(new Map<String, Object>{
            'Id' => 'demo2',
            'Title' => 'Performance Analysis Report',
            'DocumentType' => 'analysis_report', 
            'Description' => 'Automated analysis of flow execution performance and optimization recommendations.',
            'LastModifiedDate' => System.today().addDays(-1),
            'ContentSize' => '15.2 KB'
        });
        
        demoDocuments.add(new Map<String, Object>{
            'Id' => 'demo3',
            'Title' => 'Best Practices Guide',
            'DocumentType' => 'best_practices',
            'Description' => 'Collection of Salesforce Flow best practices and design patterns.',
            'LastModifiedDate' => System.today(),
            'ContentSize' => '8.7 KB'
        });
        
        return demoDocuments;
    }
    
    /**
     * @description Get demo document content
     * @param documentId Document ID
     * @return Document content
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDemoDocumentContent(String documentId) {
        Map<String, Object> content = new Map<String, Object>();
        
        if (documentId == 'demo1') {
            content.put('Title', 'Flow Documentation Template');
            content.put('DocumentType', 'flow_doc');
            content.put('FlowName', 'Sample Flow');
            content.put('Content', '# Flow Documentation Template\n\n## Overview\nThis is a sample flow documentation template.\n\n## Business Requirements\n- Process automation\n- Data validation\n- User notifications\n\n## Technical Implementation\n```\nFlow Elements:\n- Start Element\n- Decision Logic\n- Record Updates\n- Email Alerts\n```');
        } else if (documentId == 'demo2') {
            content.put('Title', 'Performance Analysis Report');
            content.put('DocumentType', 'analysis_report');
            content.put('FlowName', 'Sample Flow');
            content.put('Content', '# Performance Analysis Report\n\n## Summary\n- Average execution time: 2.3 seconds\n- Peak execution time: 8.1 seconds\n- Success rate: 98.2%\n\n## Recommendations\n1. Optimize SOQL queries\n2. Reduce DML operations\n3. Consider bulkification\n\n## Performance Metrics\n- CPU Time: 1,200ms avg\n- SOQL Queries: 3 avg\n- DML Operations: 2 avg');
        }
        
        return content;
    }
}