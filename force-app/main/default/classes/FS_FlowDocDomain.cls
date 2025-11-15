/**
 * @description Domain class for FS_Flow_Document__c business logic
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_FlowDocDomain {
    
    /**
     * @description Validate flow document records before insert
     * @param flowDocs List of flow document records
     */
    public static void validateBeforeInsert(List<FS_Flow_Document__c> flowDocs) {
        for (FS_Flow_Document__c doc : flowDocs) {
            // Validate required fields
            if (String.isBlank(doc.Flow_Api_Name__c)) {
                doc.addError('Flow API Name is required');
            }
            
            if (doc.Version__c == null) {
                doc.addError('Version is required');
            }
            
            if (String.isBlank(doc.Document_Type__c)) {
                doc.Document_Type__c = 'Complete';
            }
            
            if (String.isBlank(doc.Generation_Status__c)) {
                doc.Generation_Status__c = 'Pending';
            }
        }
    }
    
    /**
     * @description Calculate quality score based on completeness
     * @param flowDocs List of flow document records
     */
    public static void calculateQualityScore(List<FS_Flow_Document__c> flowDocs) {
        for (FS_Flow_Document__c doc : flowDocs) {
            Decimal score = 0;
            Decimal maxScore = 100;
            
            // Markdown documentation (30 points)
            if (String.isNotBlank(doc.Markdown__c)) {
                if (doc.Markdown__c.length() > 5000) {
                    score += 30;
                } else if (doc.Markdown__c.length() > 1000) {
                    score += 20;
                } else {
                    score += 10;
                }
            }
            
            // SVG diagram (30 points)
            if (String.isNotBlank(doc.Diagram_SVG__c)) {
                if (doc.Diagram_SVG__c.contains('<svg') && doc.Diagram_SVG__c.contains('</svg>')) {
                    score += 30;
                } else {
                    score += 15;
                }
            }
            
            // Test scenarios (20 points)
            if (String.isNotBlank(doc.Test_Scenarios__c)) {
                if (doc.Test_Scenarios__c.length() > 500) {
                    score += 20;
                } else {
                    score += 10;
                }
            }
            
            // Element counts (20 points)
            if (doc.Element_Count__c != null && doc.Element_Count__c > 0) {
                score += 5;
            }
            if (doc.Decision_Count__c != null) {
                score += 5;
            }
            if (doc.Loop_Count__c != null) {
                score += 5;
            }
            if (doc.Subflow_Count__c != null) {
                score += 5;
            }
            
            doc.Quality_Score__c = score;
            doc.Completeness_Percentage__c = (score / maxScore) * 100;
        }
    }
    
    /**
     * @description Update generation timestamp
     * @param flowDocs List of flow document records
     */
    public static void updateGenerationTimestamp(List<FS_Flow_Document__c> flowDocs) {
        for (FS_Flow_Document__c doc : flowDocs) {
            if (doc.Generation_Status__c == 'Completed' && doc.Generated_Date__c == null) {
                doc.Generated_Date__c = System.now();
            }
        }
    }
    
    /**
     * @description Validate SVG content
     * @param svgContent SVG string
     * @return True if valid SVG
     */
    public static Boolean isValidSvg(String svgContent) {
        if (String.isBlank(svgContent)) {
            return false;
        }
        
        return svgContent.contains('<svg') && svgContent.contains('</svg>');
    }
    
    /**
     * @description Extract statistics from flow metadata
     * @param flowMetadata Flow metadata JSON
     * @return Flow statistics
     */
    public static FlowStatistics extractStatistics(String flowMetadata) {
        FlowStatistics stats = new FlowStatistics();
        
        if (String.isBlank(flowMetadata)) {
            return stats;
        }
        
        // Simple parsing - in real implementation, parse JSON properly
        stats.elementCount = countOccurrences(flowMetadata, '"element"');
        stats.decisionCount = countOccurrences(flowMetadata, '"Decision"');
        stats.loopCount = countOccurrences(flowMetadata, '"Loop"');
        stats.subflowCount = countOccurrences(flowMetadata, '"Subflow"');
        stats.screenCount = countOccurrences(flowMetadata, '"Screen"');
        
        return stats;
    }
    
    /**
     * @description Count occurrences of a substring
     * @param text Text to search
     * @param substring Substring to find
     * @return Count of occurrences
     */
    private static Integer countOccurrences(String text, String substring) {
        if (String.isBlank(text) || String.isBlank(substring)) {
            return 0;
        }
        
        Integer count = 0;
        Integer index = 0;
        
        while ((index = text.indexOf(substring, index)) != -1) {
            count++;
            index += substring.length();
        }
        
        return count;
    }
    
    /**
     * @description Inner class for flow statistics
     */
    public class FlowStatistics {
        public Integer elementCount = 0;
        public Integer decisionCount = 0;
        public Integer loopCount = 0;
        public Integer subflowCount = 0;
        public Integer screenCount = 0;
    }
}

