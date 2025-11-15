/**
 * @description Service class for generating flow documentation and diagrams
 * @author FlowSense
 * @version 1.0
 */
public without sharing class FS_DocumentationService {
    
    private static final String CLASS_NAME = 'FS_DocumentationService';
    
    /**
     * @description Generate complete documentation for a flow
     * @param flowApiName Flow API name
     * @param version Version number
     * @return Flow document record
     */
    public static FS_Flow_Document__c generateDocumentation(String flowApiName, Integer version) {
        Long startTime = System.currentTimeMillis();
        
        try {
            FS_Flow_Document__c doc = new FS_Flow_Document__c();
            doc.Flow_Api_Name__c = flowApiName;
            doc.Version__c = version;
            doc.Document_Type__c = 'Complete';
            doc.Generation_Status__c = 'In_Progress';
            
            // Get flow metadata
            FlowMetadata metadata = getFlowMetadata(flowApiName);
            if (metadata != null) {
                doc.Flow_Label__c = metadata.label;
                doc.Element_Count__c = metadata.elementCount;
                doc.Decision_Count__c = metadata.decisionCount;
                doc.Loop_Count__c = metadata.loopCount;
                doc.Subflow_Count__c = metadata.subflowCount;
                doc.Screen_Count__c = metadata.screenCount;
                
                // Generate markdown documentation
                doc.Markdown__c = generateMarkdown(metadata);
                
                // Generate SVG diagram
                doc.Diagram_SVG__c = generateSvgDiagram(metadata);
                
                // Generate test scenarios
                doc.Test_Scenarios__c = generateTestScenarios(metadata);
                
                doc.Generation_Status__c = 'Completed';
                doc.Generated_Date__c = System.now();
            } else {
                doc.Generation_Status__c = 'Failed';
            }
            
            Long endTime = System.currentTimeMillis();
            doc.Generation_Time_Ms__c = endTime - startTime;
            
            // Calculate quality score
            FS_FlowDocDomain.calculateQualityScore(new List<FS_Flow_Document__c>{ doc });
            
            insert doc;
            return doc;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error generating documentation - ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * @description Generate markdown documentation
     * @param metadata Flow metadata
     * @return Markdown string
     */
    public static String generateMarkdown(FlowMetadata metadata) {
        List<String> lines = new List<String>();
        
        // Title and header
        lines.add('# Flow Documentation: ' + metadata.label);
        lines.add('');
        lines.add('**API Name:** ' + metadata.apiName);
        lines.add('**Version:** ' + metadata.version);
        lines.add('**Type:** ' + metadata.processType);
        lines.add('**Status:** ' + (metadata.isActive ? 'Active' : 'Inactive'));
        lines.add('**Last Modified:** ' + String.valueOf(metadata.lastModifiedDate));
        lines.add('');
        
        // Description
        if (String.isNotBlank(metadata.description)) {
            lines.add('## Description');
            lines.add('');
            lines.add(metadata.description);
            lines.add('');
        }
        
        // Overview
        lines.add('## Overview');
        lines.add('');
        lines.add('This flow contains the following components:');
        lines.add('');
        lines.add('| Component Type | Count |');
        lines.add('|---------------|-------|');
        lines.add('| Total Elements | ' + metadata.elementCount + ' |');
        lines.add('| Decisions | ' + metadata.decisionCount + ' |');
        lines.add('| Loops | ' + metadata.loopCount + ' |');
        lines.add('| Subflows | ' + metadata.subflowCount + ' |');
        lines.add('| Screens | ' + metadata.screenCount + ' |');
        lines.add('');
        
        // Variables
        if (metadata.variables != null && !metadata.variables.isEmpty()) {
            lines.add('## Variables');
            lines.add('');
            lines.add('| Variable Name | Data Type | Input | Output |');
            lines.add('|--------------|-----------|-------|--------|');
            for (FlowVariable var : metadata.variables) {
                lines.add('| ' + var.name + ' | ' + var.dataType + ' | ' + 
                         (var.isInput ? 'Yes' : 'No') + ' | ' + 
                         (var.isOutput ? 'Yes' : 'No') + ' |');
            }
            lines.add('');
        }
        
        // Flow Logic
        lines.add('## Flow Logic');
        lines.add('');
        lines.add('The flow executes the following logic:');
        lines.add('');
        
        if (metadata.elements != null && !metadata.elements.isEmpty()) {
            Integer stepNum = 1;
            for (FlowElement element : metadata.elements) {
                lines.add(stepNum + '. **' + element.label + '** (' + element.type + ')');
                if (String.isNotBlank(element.description)) {
                    lines.add('   - ' + element.description);
                }
                stepNum++;
            }
        } else {
            lines.add('*Flow structure details not available*');
        }
        lines.add('');
        
        // Best Practices
        lines.add('## Best Practices & Recommendations');
        lines.add('');
        lines.add(generateRecommendations(metadata));
        lines.add('');
        
        // Footer
        lines.add('---');
        lines.add('*Documentation generated by FlowSense on ' + System.now().format() + '*');
        
        return String.join(lines, '\n');
    }
    
    /**
     * @description Generate SVG diagram of flow
     * @param metadata Flow metadata
     * @return SVG string
     */
    public static String generateSvgDiagram(FlowMetadata metadata) {
        List<String> svg = new List<String>();
        
        // SVG header
        svg.add('<?xml version="1.0" encoding="UTF-8"?>');
        svg.add('<svg xmlns="http://www.w3.org/2000/svg" width="800" height="600" viewBox="0 0 800 600">');
        svg.add('  <defs>');
        svg.add('    <style>');
        svg.add('      .element { fill: #0176d3; stroke: #014486; stroke-width: 2; }');
        svg.add('      .decision { fill: #ffb75d; stroke: #ff9a3c; stroke-width: 2; }');
        svg.add('      .screen { fill: #54698d; stroke: #3c4f6d; stroke-width: 2; }');
        svg.add('      .text { fill: white; font-family: Arial; font-size: 12px; text-anchor: middle; }');
        svg.add('      .label { fill: #080707; font-family: Arial; font-size: 14px; font-weight: bold; }');
        svg.add('    </style>');
        svg.add('  </defs>');
        svg.add('');
        
        // Title
        svg.add('  <text x="400" y="30" class="label">' + escapeXml(metadata.label) + '</text>');
        svg.add('');
        
        // Start node
        svg.add('  <circle cx="400" cy="70" r="15" fill="#16325c" stroke="#0c1b33" stroke-width="2"/>');
        svg.add('  <text x="400" y="75" class="text">Start</text>');
        svg.add('');
        
        // Draw elements
        if (metadata.elements != null && !metadata.elements.isEmpty()) {
            Integer yPos = 120;
            Integer xPos = 400;
            
            for (Integer i = 0; i < metadata.elements.size() && i < 10; i++) {
                FlowElement element = metadata.elements[i];
                String cssClass = 'element';
                String shape = 'rect';
                
                if (element.type == 'Decision') {
                    cssClass = 'decision';
                    shape = 'polygon';
                } else if (element.type == 'Screen') {
                    cssClass = 'screen';
                }
                
                // Draw element shape
                if (shape == 'rect') {
                    svg.add('  <rect x="' + (xPos - 80) + '" y="' + yPos + '" width="160" height="40" class="' + cssClass + '"/>');
                } else {
                    svg.add('  <polygon points="' + xPos + ',' + yPos + ' ' + 
                           (xPos + 80) + ',' + (yPos + 20) + ' ' + 
                           xPos + ',' + (yPos + 40) + ' ' + 
                           (xPos - 80) + ',' + (yPos + 20) + '" class="' + cssClass + '"/>');
                }
                
                // Draw element label
                String label = element.label;
                if (label.length() > 20) {
                    label = label.substring(0, 17) + '...';
                }
                svg.add('  <text x="' + xPos + '" y="' + (yPos + 25) + '" class="text">' + escapeXml(label) + '</text>');
                
                // Draw connector line
                if (i < metadata.elements.size() - 1) {
                    svg.add('  <line x1="' + xPos + '" y1="' + (yPos + 45) + '" x2="' + xPos + '" y2="' + (yPos + 55) + '" stroke="#16325c" stroke-width="2"/>');
                    svg.add('  <polygon points="' + xPos + ',' + (yPos + 60) + ' ' + 
                           (xPos - 5) + ',' + (yPos + 50) + ' ' + 
                           (xPos + 5) + ',' + (yPos + 50) + '" fill="#16325c"/>');
                }
                
                yPos += 70;
            }
            
            // Add ellipsis if more elements
            if (metadata.elements.size() > 10) {
                svg.add('  <text x="' + xPos + '" y="' + (yPos + 20) + '" class="label">... ' + 
                       (metadata.elements.size() - 10) + ' more elements</text>');
            }
        }
        
        // SVG footer
        svg.add('</svg>');
        
        return String.join(svg, '\n');
    }
    
    /**
     * @description Generate test scenarios
     * @param metadata Flow metadata
     * @return Test scenarios string
     */
    public static String generateTestScenarios(FlowMetadata metadata) {
        List<String> scenarios = new List<String>();
        
        scenarios.add('# Test Scenarios for ' + metadata.label);
        scenarios.add('');
        scenarios.add('## Test Case 1: Happy Path');
        scenarios.add('**Objective:** Verify flow executes successfully with valid inputs');
        scenarios.add('**Prerequisites:** Valid test data available');
        scenarios.add('**Steps:**');
        scenarios.add('1. Trigger flow with valid input parameters');
        scenarios.add('2. Verify flow completes without errors');
        scenarios.add('3. Validate output values');
        scenarios.add('**Expected Result:** Flow completes successfully');
        scenarios.add('');
        
        scenarios.add('## Test Case 2: Error Handling');
        scenarios.add('**Objective:** Verify flow handles errors gracefully');
        scenarios.add('**Prerequisites:** Test data that triggers error conditions');
        scenarios.add('**Steps:**');
        scenarios.add('1. Trigger flow with invalid/missing inputs');
        scenarios.add('2. Verify error is caught and handled');
        scenarios.add('3. Validate error messages');
        scenarios.add('**Expected Result:** Flow handles errors without crashing');
        scenarios.add('');
        
        if (metadata.decisionCount > 0) {
            scenarios.add('## Test Case 3: Decision Paths');
            scenarios.add('**Objective:** Verify all decision branches work correctly');
            scenarios.add('**Prerequisites:** Test data for each decision outcome');
            scenarios.add('**Steps:**');
            scenarios.add('1. Test each decision branch with appropriate data');
            scenarios.add('2. Verify correct path is taken');
            scenarios.add('3. Validate outcomes for each path');
            scenarios.add('**Expected Result:** All decision paths execute correctly');
            scenarios.add('');
        }
        
        if (metadata.loopCount > 0) {
            scenarios.add('## Test Case 4: Loop Handling');
            scenarios.add('**Objective:** Verify loops process collections correctly');
            scenarios.add('**Prerequisites:** Test collection with multiple records');
            scenarios.add('**Steps:**');
            scenarios.add('1. Trigger flow with collection input');
            scenarios.add('2. Verify each item is processed');
            scenarios.add('3. Validate loop completion and results');
            scenarios.add('**Expected Result:** Loop processes all items successfully');
            scenarios.add('');
        }
        
        scenarios.add('## Test Case 5: Performance');
        scenarios.add('**Objective:** Verify flow meets performance requirements');
        scenarios.add('**Prerequisites:** Realistic data volume');
        scenarios.add('**Steps:**');
        scenarios.add('1. Execute flow with production-like data volume');
        scenarios.add('2. Monitor CPU time, SOQL, and DML limits');
        scenarios.add('3. Validate execution time');
        scenarios.add('**Expected Result:** Flow completes within acceptable limits');
        
        return String.join(scenarios, '\n');
    }
    
    /**
     * @description Generate recommendations based on flow analysis
     * @param metadata Flow metadata
     * @return Recommendations string
     */
    private static String generateRecommendations(FlowMetadata metadata) {
        List<String> recs = new List<String>();
        
        if (metadata.elementCount > 50) {
            recs.add('- Consider breaking this flow into smaller subflows for better maintainability');
        }
        
        if (metadata.loopCount > 0) {
            recs.add('- Ensure collection variables in loops use bulkification');
            recs.add('- Avoid SOQL/DML operations inside loops');
        }
        
        if (metadata.subflowCount > 0) {
            recs.add('- Document the purpose and dependencies of each subflow');
        }
        
        if (metadata.decisionCount > 5) {
            recs.add('- Consider using formula fields or Apex for complex decision logic');
        }
        
        recs.add('- Add fault paths to handle errors gracefully');
        recs.add('- Use FlowSense monitoring to track performance in production');
        recs.add('- Regularly review and optimize based on execution data');
        
        return String.join(recs, '\n');
    }
    
    /**
     * @description Get flow metadata
     * @param flowApiName Flow API name
     * @return Flow metadata
     */
    private static FlowMetadata getFlowMetadata(String flowApiName) {
        try {
            // Use existing FlowMetadataService
            return FS_FlowMetadataService.getFlowMetadata(flowApiName, false);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error fetching metadata - ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Escape XML special characters
     * @param text Text to escape
     * @return Escaped text
     */
    private static String escapeXml(String text) {
        if (String.isBlank(text)) {
            return '';
        }
        
        return text.replace('&', '&amp;')
                   .replace('<', '&lt;')
                   .replace('>', '&gt;')
                   .replace('"', '&quot;')
                   .replace('\'', '&apos;');
    }
    
    /**
     * @description Export documentation to different formats
     * @param docId Flow document ID
     * @param format Export format (PDF, HTML, etc.)
     * @return Export result
     */
    public static ExportResult exportDocumentation(Id docId, String format) {
        ExportResult result = new ExportResult();
        result.format = format;
        result.success = false;
        
        try {
            FS_Flow_Document__c doc = FS_FlowDocSelector.selectById(new Set<Id>{ docId })[0];
            
            if (doc == null) {
                result.errorMessage = 'Document not found';
                return result;
            }
            
            // For now, just mark as exported (actual export would require additional services)
            doc.Last_Exported__c = System.now();
            update doc;
            
            result.success = true;
            result.content = doc.Markdown__c;
            
        } catch (Exception e) {
            result.errorMessage = e.getMessage();
        }
        
        return result;
    }
    
    /**
     * @description Inner class for export result
     */
    public class ExportResult {
        public Boolean success;
        public String format;
        public String content;
        public String errorMessage;
    }
    
    // Reuse inner classes from FS_FlowMetadataService
    public class FlowMetadata extends FS_FlowMetadataService.FlowMetadata {}
    public class FlowVariable extends FS_FlowMetadataService.FlowVariable {}
    public class FlowElement extends FS_FlowMetadataService.FlowElement {}
}

