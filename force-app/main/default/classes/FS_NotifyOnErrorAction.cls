/**
 * @description Invocable action for sending notifications when flow errors occur
 * @author FlowSense
 * @version 1.0
 */
public with sharing class FS_NotifyOnErrorAction {
    
    @InvocableMethod(label='Notify on Flow Error' description='Send notifications when a flow encounters an error' category='FlowSense')
    public static List<Result> notifyOnError(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        try {
            for (Request request : requests) {
                Result result = new Result();
                result.isSuccess = true;
                result.message = 'Notification processing initiated';
                
                // Process notification asynchronously if enabled
                if (isAsyncProcessingEnabled()) {
                    FS_NotifyOnErrorQueueable queueable = new FS_NotifyOnErrorQueueable(request);
                    System.enqueueJob(queueable);
                    result.message = 'Notification queued for async processing';
                } else {
                    // Process synchronously
                    processNotification(request);
                    result.message = 'Notification processed synchronously';
                }
                
                results.add(result);
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in FS_NotifyOnErrorAction: ' + e.getMessage());
            
            for (Request request : requests) {
                Result result = new Result();
                result.isSuccess = false;
                result.errorMessage = 'Failed to process notification: ' + e.getMessage();
                results.add(result);
            }
        }
        
        return results;
    }
    
    /**
     * @description Process notification for flow error
     * @param request The notification request
     */
    @TestVisible
    private static void processNotification(Request request) {
        try {
            // Find applicable alert policies
            List<FS_Flow_Alert__c> alertPolicies = getApplicableAlertPolicies(request.flowApiName);
            
            if (alertPolicies.isEmpty()) {
                System.debug('No applicable alert policies found for flow: ' + request.flowApiName);
                return;
            }
            
            // Process each alert policy
            for (FS_Flow_Alert__c policy : alertPolicies) {
                if (shouldTriggerAlert(policy, request)) {
                    sendNotifications(policy, request);
                    updateAlertStatistics(policy);
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing notification: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get applicable alert policies for a flow
     * @param flowApiName The flow API name
     * @return List of applicable alert policies
     */
    private static List<FS_Flow_Alert__c> getApplicableAlertPolicies(String flowApiName) {
        List<FS_Flow_Alert__c> policies = [
            SELECT Id, Name, Active__c, Severity__c, Applies_To__c, Flow_Filter__c,
                   Channel__c, Email_Recipients__c, Webhook_URL__c, Slack_Channel__c,
                   Alert_Frequency__c, Last_Alert_Sent__c, Alert_Count__c
            FROM FS_Flow_Alert__c
            WHERE Active__c = true
        ];
        
        List<FS_Flow_Alert__c> applicablePolicies = new List<FS_Flow_Alert__c>();
        
        for (FS_Flow_Alert__c policy : policies) {
            if (policyAppliesTo(policy, flowApiName)) {
                applicablePolicies.add(policy);
            }
        }
        
        return applicablePolicies;
    }
    
    /**
     * @description Check if alert policy applies to the given flow
     * @param policy The alert policy
     * @param flowApiName The flow API name
     * @return Boolean indicating if policy applies
     */
    private static Boolean policyAppliesTo(FS_Flow_Alert__c policy, String flowApiName) {
        switch on policy.Applies_To__c {
            when 'All' {
                return true;
            }
            when 'By_API_Name' {
                return String.isNotBlank(policy.Flow_Filter__c) && 
                       policy.Flow_Filter__c.equals(flowApiName);
            }
            when 'By_Pattern' {
                return String.isNotBlank(policy.Flow_Filter__c) && 
                       Pattern.matches(policy.Flow_Filter__c, flowApiName);
            }
            when else {
                return false;
            }
        }
    }
    
    /**
     * @description Check if alert should be triggered based on frequency settings
     * @param policy The alert policy
     * @param request The notification request
     * @return Boolean indicating if alert should be triggered
     */
    private static Boolean shouldTriggerAlert(FS_Flow_Alert__c policy, Request request) {
        if (policy.Alert_Frequency__c == 'Every_Occurrence') {
            return true;
        }
        
        if (policy.Last_Alert_Sent__c == null) {
            return true;
        }
        
        DateTime now = System.now();
        DateTime lastAlert = policy.Last_Alert_Sent__c;
        
        switch on policy.Alert_Frequency__c {
            when 'Once_Per_Hour' {
                return lastAlert.addHours(1) <= now;
            }
            when 'Once_Per_Day' {
                return lastAlert.addDays(1) <= now;
            }
            when 'Digest_Daily' {
                return lastAlert.addDays(1) <= now;
            }
            when else {
                return true;
            }
        }
    }
    
    /**
     * @description Send notifications through configured channels
     * @param policy The alert policy
     * @param request The notification request
     */
    private static void sendNotifications(FS_Flow_Alert__c policy, Request request) {
        if (String.isBlank(policy.Channel__c)) {
            return;
        }
        
        List<String> channels = policy.Channel__c.split(';');
        String message = buildNotificationMessage(policy, request);
        
        for (String channel : channels) {
            switch on channel.trim() {
                when 'Email' {
                    sendEmailNotification(policy, message);
                }
                when 'Slack' {
                    sendSlackNotification(policy, message);
                }
                when 'Teams' {
                    sendTeamsNotification(policy, message);
                }
                when 'Webhook' {
                    sendWebhookNotification(policy, message);
                }
                when 'Platform_Event' {
                    publishPlatformEvent(policy, request);
                }
            }
        }
    }
    
    /**
     * @description Build notification message
     * @param policy The alert policy
     * @param request The notification request
     * @return Formatted notification message
     */
    private static String buildNotificationMessage(FS_Flow_Alert__c policy, Request request) {
        String severity = policy.Severity__c != null ? policy.Severity__c.toUpperCase() : 'ERROR';
        
        String message = '🚨 FlowSense Alert [' + severity + ']\n\n';
        message += '**Flow:** ' + request.flowApiName + '\n';
        message += '**Error:** ' + request.errorMessage + '\n';
        message += '**Time:** ' + System.now().format('yyyy-MM-dd HH:mm:ss') + '\n';
        
        if (String.isNotBlank(request.interviewId)) {
            message += '**Interview ID:** ' + request.interviewId + '\n';
        }
        
        if (String.isNotBlank(request.runtimeUser)) {
            message += '**User:** ' + request.runtimeUser + '\n';
        }
        
        message += '\n*Alert Policy:* ' + policy.Name;
        
        return message;
    }
    
    /**
     * @description Send email notification
     * @param policy The alert policy
     * @param message The notification message
     */
    private static void sendEmailNotification(FS_Flow_Alert__c policy, String message) {
        if (String.isBlank(policy.Email_Recipients__c)) {
            return;
        }
        
        try {
            List<String> recipients = policy.Email_Recipients__c.split('[,;\\n]');
            List<String> cleanRecipients = new List<String>();
            
            for (String recipient : recipients) {
                String cleanRecipient = recipient.trim();
                if (String.isNotBlank(cleanRecipient)) {
                    cleanRecipients.add(cleanRecipient);
                }
            }
            
            if (!cleanRecipients.isEmpty()) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(cleanRecipients);
                email.setSubject('FlowSense Alert: ' + policy.Name);
                email.setPlainTextBody(message);
                
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error sending email notification: ' + e.getMessage());
        }
    }
    
    /**
     * @description Send Slack notification (placeholder for webhook implementation)
     * @param policy The alert policy
     * @param message The notification message
     */
    private static void sendSlackNotification(FS_Flow_Alert__c policy, String message) {
        // Implementation would use Named Credentials for Slack webhook
        System.debug('Slack notification: ' + message + ' to channel: ' + policy.Slack_Channel__c);
    }
    
    /**
     * @description Send Teams notification (placeholder for webhook implementation)
     * @param policy The alert policy
     * @param message The notification message
     */
    private static void sendTeamsNotification(FS_Flow_Alert__c policy, String message) {
        // Implementation would use Named Credentials for Teams webhook
        System.debug('Teams notification: ' + message);
    }
    
    /**
     * @description Send webhook notification (placeholder for custom webhook implementation)
     * @param policy The alert policy
     * @param message The notification message
     */
    private static void sendWebhookNotification(FS_Flow_Alert__c policy, String message) {
        // Implementation would use Named Credentials for custom webhook
        System.debug('Webhook notification to: ' + policy.Webhook_URL__c + ' with message: ' + message);
    }
    
    /**
     * @description Publish platform event for alert
     * @param policy The alert policy
     * @param request The notification request
     */
    private static void publishPlatformEvent(FS_Flow_Alert__c policy, Request request) {
        // Implementation would publish FS_Flow_Alert_Event__e platform event
        System.debug('Platform event published for policy: ' + policy.Name);
    }
    
    /**
     * @description Update alert statistics
     * @param policy The alert policy
     */
    private static void updateAlertStatistics(FS_Flow_Alert__c policy) {
        try {
            policy.Last_Alert_Sent__c = System.now();
            policy.Alert_Count__c = (policy.Alert_Count__c != null ? policy.Alert_Count__c : 0) + 1;
            update policy;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error updating alert statistics: ' + e.getMessage());
        }
    }
    
    /**
     * @description Check if async processing is enabled
     * @return Boolean indicating if async processing is enabled
     */
    private static Boolean isAsyncProcessingEnabled() {
        return FS_SettingsUtil.isAsyncProcessingEnabled();
    }
    
    /**
     * @description Request wrapper for error notifications
     */
    public class Request {
        @InvocableVariable(label='Flow API Name' description='API name of the flow that encountered an error' required=true)
        public String flowApiName;
        
        @InvocableVariable(label='Error Message' description='Error message or exception details' required=true)
        public String errorMessage;
        
        @InvocableVariable(label='Interview ID' description='Flow interview ID for tracking')
        public String interviewId;
        
        @InvocableVariable(label='Runtime User' description='User who was running the flow when error occurred')
        public String runtimeUser;
        
        @InvocableVariable(label='Flow Label' description='User-friendly label of the flow')
        public String flowLabel;
        
        @InvocableVariable(label='Error Type' description='Type or category of error')
        public String errorType;
        
        @InvocableVariable(label='Stack Trace' description='Full stack trace of the error')
        public String stackTrace;
    }
    
    /**
     * @description Result wrapper for error notifications
     */
    public class Result {
        @InvocableVariable(label='Success' description='Indicates if the notification was processed successfully')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Message' description='Success or informational message')
        public String message;
        
        @InvocableVariable(label='Error Message' description='Error message if notification failed')
        public String errorMessage;
    }
    
    /**
     * @description Queueable class for async notification processing
     */
    public class FS_NotifyOnErrorQueueable implements Queueable {
        private Request request;
        
        public FS_NotifyOnErrorQueueable(Request req) {
            this.request = req;
        }
        
        public void execute(QueueableContext context) {
            processNotification(this.request);
        }
    }
}