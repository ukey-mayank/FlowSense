/**
 * @description Service class for notification delivery (structure - integrations not implemented)
 * @author FlowSense
 * @version 1.0
 */
public without sharing class FS_NotifyService {
    
    private static final String CLASS_NAME = 'FS_NotifyService';
    
    /**
     * @description Send notification based on alert policy
     * @param alert Alert policy record
     * @param flowRun Flow run that triggered the alert
     * @return Notification result
     */
    public static NotificationResult sendAlert(FS_Flow_Alert__c alert, FS_Flow_Run__c flowRun) {
        NotificationResult result = new NotificationResult();
        result.success = true;
        result.channelsSent = new List<String>();
        result.errors = new List<String>();
        
        try {
            // Parse channels from multi-select picklist
            Set<String> channels = parseChannels(alert.Channel__c);
            
            // Send to each channel
            for (String channel : channels) {
                try {
                    switch on channel {
                        when 'Email' {
                            sendEmail(alert, flowRun);
                            result.channelsSent.add('Email');
                        }
                        when 'Slack' {
                            sendSlack(alert, flowRun);
                            result.channelsSent.add('Slack');
                        }
                        when 'Teams' {
                            sendTeams(alert, flowRun);
                            result.channelsSent.add('Teams');
                        }
                        when 'WhatsApp' {
                            sendWhatsApp(alert, flowRun);
                            result.channelsSent.add('WhatsApp');
                        }
                        when 'Webhook' {
                            sendWebhook(alert, flowRun);
                            result.channelsSent.add('Webhook');
                        }
                        when 'Platform_Event' {
                            sendPlatformEvent(alert, flowRun);
                            result.channelsSent.add('Platform_Event');
                        }
                    }
                } catch (Exception e) {
                    result.errors.add(channel + ': ' + e.getMessage());
                    System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error sending to ' + channel + ' - ' + e.getMessage());
                }
            }
            
            // Update alert last sent timestamp
            alert.Last_Alert_Sent__c = System.now();
            if (alert.Alert_Count__c == null) {
                alert.Alert_Count__c = 0;
            }
            alert.Alert_Count__c++;
            update alert;
            
            result.success = result.errors.isEmpty();
            
        } catch (Exception e) {
            result.success = false;
            result.errors.add('General error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, CLASS_NAME + ': Error in sendAlert - ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Send email notification
     * @param alert Alert policy
     * @param flowRun Flow run
     */
    private static void sendEmail(FS_Flow_Alert__c alert, FS_Flow_Run__c flowRun) {
        if (String.isBlank(alert.Email_Recipients__c)) {
            throw new NotificationException('No email recipients specified');
        }
        
        List<String> recipients = alert.Email_Recipients__c.split('[,;\\n]');
        List<String> cleanRecipients = new List<String>();
        
        for (String recipient : recipients) {
            String clean = recipient.trim();
            if (String.isNotBlank(clean)) {
                cleanRecipients.add(clean);
            }
        }
        
        if (cleanRecipients.isEmpty()) {
            throw new NotificationException('No valid email recipients');
        }
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(cleanRecipients);
        email.setSubject('FlowSense Alert: ' + alert.Name + ' - ' + alert.Severity__c);
        email.setPlainTextBody(buildEmailBody(alert, flowRun));
        email.setHtmlBody(buildHtmlEmailBody(alert, flowRun));
        
        // Send email
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        
        if (!results[0].isSuccess()) {
            throw new NotificationException('Email send failed: ' + results[0].getErrors()[0].getMessage());
        }
        
        System.debug(LoggingLevel.INFO, CLASS_NAME + ': Email sent to ' + cleanRecipients.size() + ' recipients');
    }
    
    /**
     * @description Send Slack notification (placeholder - requires Named Credential)
     * @param alert Alert policy
     * @param flowRun Flow run
     */
    private static void sendSlack(FS_Flow_Alert__c alert, FS_Flow_Run__c flowRun) {
        // Placeholder: Would use Named Credential to Slack API
        System.debug(LoggingLevel.INFO, CLASS_NAME + ': Slack notification would be sent here');
        // Implementation would use:
        // - Named Credential for Slack API
        // - HttpRequest to Slack webhook
        // - Format message as Slack blocks
    }
    
    /**
     * @description Send Microsoft Teams notification (placeholder - requires Named Credential)
     * @param alert Alert policy
     * @param flowRun Flow run
     */
    private static void sendTeams(FS_Flow_Alert__c alert, FS_Flow_Run__c flowRun) {
        // Placeholder: Would use webhook URL
        System.debug(LoggingLevel.INFO, CLASS_NAME + ': Teams notification would be sent here');
        // Implementation would use:
        // - Webhook URL from alert or CMDT
        // - HttpRequest to Teams webhook
        // - Format message as Teams card
    }
    
    /**
     * @description Send WhatsApp notification (placeholder - requires Named Credential)
     * @param alert Alert policy
     * @param flowRun Flow run
     */
    private static void sendWhatsApp(FS_Flow_Alert__c alert, FS_Flow_Run__c flowRun) {
        // Placeholder: Would use WhatsApp Business API
        System.debug(LoggingLevel.INFO, CLASS_NAME + ': WhatsApp notification would be sent here');
        // Implementation would use:
        // - Named Credential to WhatsApp API
        // - HttpRequest with authentication
        // - Format message per WhatsApp requirements
    }
    
    /**
     * @description Send custom webhook notification (placeholder - requires configuration)
     * @param alert Alert policy
     * @param flowRun Flow run
     */
    private static void sendWebhook(FS_Flow_Alert__c alert, FS_Flow_Run__c flowRun) {
        // Placeholder: Would use custom webhook URL
        System.debug(LoggingLevel.INFO, CLASS_NAME + ': Webhook notification would be sent here');
        // Implementation would use:
        // - Webhook URL from alert
        // - HttpRequest with JSON payload
        // - Handle authentication if required
    }
    
    /**
     * @description Send Platform Event notification
     * @param alert Alert policy
     * @param flowRun Flow run
     */
    private static void sendPlatformEvent(FS_Flow_Alert__c alert, FS_Flow_Run__c flowRun) {
        // Placeholder: Would publish to FS_Flow_Alert_Event__e
        System.debug(LoggingLevel.INFO, CLASS_NAME + ': Platform Event would be published here');
        // Implementation would:
        // - Create FS_Flow_Alert_Event__e record
        // - Populate event fields
        // - Publish via EventBus.publish()
    }
    
    /**
     * @description Build plain text email body
     * @param alert Alert policy
     * @param flowRun Flow run
     * @return Email body text
     */
    private static String buildEmailBody(FS_Flow_Alert__c alert, FS_Flow_Run__c flowRun) {
        List<String> lines = new List<String>();
        
        lines.add('FlowSense Alert');
        lines.add('================');
        lines.add('');
        lines.add('Policy: ' + alert.Name);
        lines.add('Severity: ' + alert.Severity__c);
        lines.add('Time: ' + System.now().format());
        lines.add('');
        lines.add('Flow Details:');
        lines.add('-------------');
        lines.add('Flow Name: ' + flowRun.Flow_Label__c);
        lines.add('API Name: ' + flowRun.Flow_API_Name__c);
        lines.add('Status: ' + flowRun.Status__c);
        lines.add('Started: ' + flowRun.Started_At__c);
        
        if (flowRun.Status__c == 'Failed' && String.isNotBlank(flowRun.Error_Message__c)) {
            lines.add('');
            lines.add('Error: ' + flowRun.Error_Message__c);
        }
        
        lines.add('');
        lines.add('Performance Metrics:');
        lines.add('-------------------');
        lines.add('CPU Time: ' + (flowRun.CPU_Time_Millis__c != null ? flowRun.CPU_Time_Millis__c + 'ms' : 'N/A'));
        lines.add('SOQL Queries: ' + (flowRun.SOQL_Count__c != null ? String.valueOf(flowRun.SOQL_Count__c) : 'N/A'));
        lines.add('DML Statements: ' + (flowRun.DML_Count__c != null ? String.valueOf(flowRun.DML_Count__c) : 'N/A'));
        lines.add('Duration: ' + (flowRun.Duration_Ms__c != null ? flowRun.Duration_Ms__c + 'ms' : 'N/A'));
        
        if (flowRun.Performance_Score__c != null) {
            lines.add('Performance Score: ' + flowRun.Performance_Score__c);
        }
        
        lines.add('');
        lines.add('View in FlowSense: ' + URL.getOrgDomainUrl().toExternalForm() + '/' + flowRun.Id);
        
        return String.join(lines, '\n');
    }
    
    /**
     * @description Build HTML email body
     * @param alert Alert policy
     * @param flowRun Flow run
     * @return HTML email body
     */
    private static String buildHtmlEmailBody(FS_Flow_Alert__c alert, FS_Flow_Run__c flowRun) {
        List<String> html = new List<String>();
        
        String severityColor = getSeverityColor(alert.Severity__c);
        
        html.add('<html><body style="font-family: Arial, sans-serif;">');
        html.add('<div style="background-color: ' + severityColor + '; color: white; padding: 20px; margin-bottom: 20px;">');
        html.add('<h1 style="margin: 0;">FlowSense Alert</h1>');
        html.add('<p style="margin: 5px 0 0 0; font-size: 18px;">' + alert.Name + '</p>');
        html.add('</div>');
        
        html.add('<div style="padding: 20px;">');
        html.add('<table style="width: 100%; border-collapse: collapse;">');
        html.add('<tr><td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Severity:</strong></td><td style="padding: 8px; border-bottom: 1px solid #ddd;">' + alert.Severity__c + '</td></tr>');
        html.add('<tr><td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Flow Name:</strong></td><td style="padding: 8px; border-bottom: 1px solid #ddd;">' + flowRun.Flow_Label__c + '</td></tr>');
        html.add('<tr><td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>Status:</strong></td><td style="padding: 8px; border-bottom: 1px solid #ddd;">' + flowRun.Status__c + '</td></tr>');
        html.add('<tr><td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>CPU Time:</strong></td><td style="padding: 8px; border-bottom: 1px solid #ddd;">' + (flowRun.CPU_Time_Millis__c != null ? flowRun.CPU_Time_Millis__c + 'ms' : 'N/A') + '</td></tr>');
        html.add('<tr><td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>SOQL Queries:</strong></td><td style="padding: 8px; border-bottom: 1px solid #ddd;">' + (flowRun.SOQL_Count__c != null ? String.valueOf(flowRun.SOQL_Count__c) : 'N/A') + '</td></tr>');
        html.add('<tr><td style="padding: 8px; border-bottom: 1px solid #ddd;"><strong>DML Statements:</strong></td><td style="padding: 8px; border-bottom: 1px solid #ddd;">' + (flowRun.DML_Count__c != null ? String.valueOf(flowRun.DML_Count__c) : 'N/A') + '</td></tr>');
        html.add('</table>');
        
        if (flowRun.Status__c == 'Failed' && String.isNotBlank(flowRun.Error_Message__c)) {
            html.add('<div style="background-color: #fee; padding: 10px; margin-top: 20px; border-left: 4px solid #c00;">');
            html.add('<strong>Error:</strong><br/>' + flowRun.Error_Message__c);
            html.add('</div>');
        }
        
        html.add('<p style="margin-top: 20px;">');
        html.add('<a href="' + URL.getOrgDomainUrl().toExternalForm() + '/' + flowRun.Id + '" style="background-color: #0176d3; color: white; padding: 10px 20px; text-decoration: none; border-radius: 4px;">View in FlowSense</a>');
        html.add('</p>');
        html.add('</div>');
        html.add('</body></html>');
        
        return String.join(html, '');
    }
    
    /**
     * @description Parse channels from multi-select picklist value
     * @param channelValue Channel multi-select value
     * @return Set of channel names
     */
    private static Set<String> parseChannels(String channelValue) {
        Set<String> channels = new Set<String>();
        
        if (String.isBlank(channelValue)) {
            return channels;
        }
        
        for (String channel : channelValue.split(';')) {
            channels.add(channel.trim());
        }
        
        return channels;
    }
    
    /**
     * @description Get color code for severity
     * @param severity Severity level
     * @return Hex color code
     */
    private static String getSeverityColor(String severity) {
        switch on severity {
            when 'Critical' {
                return '#c23934';
            }
            when 'Warning' {
                return '#ff9a3c';
            }
            when else {
                return '#0176d3';
            }
        }
    }
    
    /**
     * @description Check if alert should be sent based on frequency
     * @param alert Alert policy
     * @return True if alert should be sent
     */
    public static Boolean shouldSendAlert(FS_Flow_Alert__c alert) {
        if (!alert.Active__c) {
            return false;
        }
        
        if (String.isBlank(alert.Alert_Frequency__c) || alert.Alert_Frequency__c == 'Every_Occurrence') {
            return true;
        }
        
        if (alert.Last_Alert_Sent__c == null) {
            return true;
        }
        
        DateTime lastSent = alert.Last_Alert_Sent__c;
        DateTime now = System.now();
        
        switch on alert.Alert_Frequency__c {
            when 'Once_Per_Hour' {
                return lastSent.addHours(1) < now;
            }
            when 'Once_Per_Day' {
                return lastSent.addDays(1) < now;
            }
            when 'Digest_Daily' {
                // For digest, would need separate implementation
                return false;
            }
            when else {
                return true;
            }
        }
    }
    
    /**
     * @description Inner class for notification result
     */
    public class NotificationResult {
        public Boolean success;
        public List<String> channelsSent;
        public List<String> errors;
    }
    
    /**
     * @description Custom exception for notification errors
     */
    public class NotificationException extends Exception {}
}

