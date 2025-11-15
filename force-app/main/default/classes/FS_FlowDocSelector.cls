/**
 * @description Selector class for FS_Flow_Document__c object following selector pattern
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_FlowDocSelector {
    
    /**
     * @description Get flow documents by IDs
     * @param docIds Set of flow document IDs
     * @return List of flow document records
     */
    public static List<FS_Flow_Document__c> selectById(Set<Id> docIds) {
        if (docIds == null || docIds.isEmpty()) {
            return new List<FS_Flow_Document__c>();
        }
        
        return [
            SELECT Id, Name, Flow_Api_Name__c, Flow_Label__c, Version__c,
                   Markdown__c, Diagram_SVG__c, Test_Scenarios__c,
                   Document_Type__c, Generation_Status__c, Generated_Date__c,
                   Generation_Time_Ms__c, Element_Count__c, Decision_Count__c,
                   Loop_Count__c, Subflow_Count__c, Screen_Count__c,
                   Export_Format__c, Last_Exported__c, Quality_Score__c,
                   Completeness_Percentage__c, Template_Used__c, Auto_Update__c,
                   CreatedDate, CreatedById, LastModifiedDate
            FROM FS_Flow_Document__c
            WHERE Id IN :docIds
            WITH SECURITY_ENFORCED
            ORDER BY Generated_Date__c DESC
        ];
    }
    
    /**
     * @description Get flow documents by Flow API Name
     * @param flowApiName Flow API name
     * @return List of flow document records
     */
    public static List<FS_Flow_Document__c> selectByFlowApiName(String flowApiName) {
        return [
            SELECT Id, Name, Flow_Api_Name__c, Flow_Label__c, Version__c,
                   Document_Type__c, Generation_Status__c, Generated_Date__c,
                   Element_Count__c, Quality_Score__c, Completeness_Percentage__c,
                   CreatedDate, LastModifiedDate
            FROM FS_Flow_Document__c
            WHERE Flow_Api_Name__c = :flowApiName
            WITH SECURITY_ENFORCED
            ORDER BY Version__c DESC, Generated_Date__c DESC
        ];
    }
    
    /**
     * @description Get specific flow document by API name and version
     * @param flowApiName Flow API name
     * @param version Version number
     * @return Flow document record or null
     */
    public static FS_Flow_Document__c selectByFlowAndVersion(
        String flowApiName, 
        Integer version
    ) {
        List<FS_Flow_Document__c> docs = [
            SELECT Id, Name, Flow_Api_Name__c, Flow_Label__c, Version__c,
                   Markdown__c, Diagram_SVG__c, Test_Scenarios__c,
                   Document_Type__c, Generation_Status__c, Generated_Date__c,
                   Generation_Time_Ms__c, Element_Count__c, Decision_Count__c,
                   Loop_Count__c, Subflow_Count__c, Screen_Count__c,
                   Quality_Score__c, Completeness_Percentage__c
            FROM FS_Flow_Document__c
            WHERE Flow_Api_Name__c = :flowApiName
            AND Version__c = :version
            WITH SECURITY_ENFORCED
            ORDER BY Generated_Date__c DESC
            LIMIT 1
        ];
        
        return docs.isEmpty() ? null : docs[0];
    }
    
    /**
     * @description Get latest complete documentation for each flow
     * @param limitCount Maximum number of records to return
     * @return List of flow document records
     */
    public static List<FS_Flow_Document__c> selectLatestCompleteDocuments(Integer limitCount) {
        return [
            SELECT Id, Name, Flow_Api_Name__c, Flow_Label__c, Version__c,
                   Document_Type__c, Generation_Status__c, Generated_Date__c,
                   Quality_Score__c, Completeness_Percentage__c
            FROM FS_Flow_Document__c
            WHERE Generation_Status__c = 'Completed'
            AND Document_Type__c = 'Complete'
            WITH SECURITY_ENFORCED
            ORDER BY Generated_Date__c DESC
            LIMIT :limitCount
        ];
    }
    
    /**
     * @description Get documents pending generation
     * @param limitCount Maximum number of records to return
     * @return List of pending flow document records
     */
    public static List<FS_Flow_Document__c> selectPendingDocuments(Integer limitCount) {
        return [
            SELECT Id, Name, Flow_Api_Name__c, Flow_Label__c, Version__c,
                   Document_Type__c, Generation_Status__c, CreatedDate
            FROM FS_Flow_Document__c
            WHERE Generation_Status__c IN ('Pending', 'In_Progress')
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate ASC
            LIMIT :limitCount
        ];
    }
    
    /**
     * @description Get documents for auto-update
     * @param limitCount Maximum number of records to return
     * @return List of flow document records with auto-update enabled
     */
    public static List<FS_Flow_Document__c> selectAutoUpdateDocuments(Integer limitCount) {
        return [
            SELECT Id, Name, Flow_Api_Name__c, Version__c,
                   Document_Type__c, Generated_Date__c
            FROM FS_Flow_Document__c
            WHERE Auto_Update__c = true
            AND Generation_Status__c = 'Completed'
            WITH SECURITY_ENFORCED
            ORDER BY Generated_Date__c ASC
            LIMIT :limitCount
        ];
    }
    
    /**
     * @description Get flow documents for LWC components
     * @param flowId Flow ID to filter by
     * @param documentType Document type filter
     * @param searchTerm Search term
     * @return List of document records
     */
    @AuraEnabled(cacheable=true)
    public static List<FS_Flow_Document__c> getFlowDocuments(String flowId, String documentType, String searchTerm) {
        String query = 'SELECT Id, Name, Document_Type__c, Content_Summary__c, Content_Size__c, ' +
                      'LastModifiedDate, Flow_API_Name__c, Flow_Label__c ' +
                      'FROM FS_Flow_Document__c ';
        
        List<String> conditions = new List<String>();
        
        if (String.isNotBlank(flowId) && flowId != 'all') {
            conditions.add('Flow_API_Name__c = :flowId');
        }
        
        if (String.isNotBlank(documentType) && documentType != 'all') {
            conditions.add('Document_Type__c = :documentType');
        }
        
        if (String.isNotBlank(searchTerm)) {
            conditions.add('(Name LIKE :searchPattern OR Content_Summary__c LIKE :searchPattern)');
        }
        
        if (!conditions.isEmpty()) {
            query += ' WHERE ' + String.join(conditions, ' AND ');
        }
        
        query += ' WITH SECURITY_ENFORCED ORDER BY LastModifiedDate DESC LIMIT 50';
        
        String searchPattern = String.isNotBlank(searchTerm) ? '%' + searchTerm + '%' : null;
        
        return Database.query(query);
    }
    
    /**
     * @description Get document content by ID
     * @param documentId Document ID
     * @return Document with content
     */
    @AuraEnabled(cacheable=true)
    public static FS_Flow_Document__c getDocumentContent(Id documentId) {
        return [
            SELECT Id, Name, Document_Type__c, Content__c, Content_Summary__c,
                   LastModifiedDate, Flow_API_Name__c, Flow_Label__c
            FROM FS_Flow_Document__c
            WHERE Id = :documentId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }
}

