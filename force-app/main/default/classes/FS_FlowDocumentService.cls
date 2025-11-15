/**
 * @description Service class for FlowSense Document operations used by LWC
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_FlowDocumentService {
    
    /**
     * @description Save a flow document
     * @param documentId Document ID to update
     * @param title New title
     * @param content New content
     * @return Updated document ID
     */
    @AuraEnabled
    public static String saveDocument(Id documentId, String title, String content) {
        try {
            FS_Flow_Document__c doc = [
                SELECT Id, Name, Content__c
                FROM FS_Flow_Document__c
                WHERE Id = :documentId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            doc.Name = title;
            doc.Content__c = content;
            doc.Content_Size__c = content.length();
            
            update doc;
            
            return doc.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error saving document: ' + e.getMessage());
        }
    }
    
    /**
     * @description Create a new flow document
     * @param flowId Flow API name
     * @param documentType Document type
     * @param title Document title
     * @param content Document content
     * @return New document record
     */
    @AuraEnabled
    public static FS_Flow_Document__c createDocument(String flowId, String documentType, String title, String content) {
        try {
            FS_Flow_Document__c doc = new FS_Flow_Document__c();
            doc.Name = title;
            doc.Flow_API_Name__c = flowId;
            doc.Document_Type__c = documentType;
            doc.Content__c = content;
            doc.Content_Size__c = content?.length() ?? 0;
            doc.Content_Summary__c = content?.length() > 255 ? content.substring(0, 255) : content;
            
            insert doc;
            
            return doc;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating document: ' + e.getMessage());
        }
    }
}