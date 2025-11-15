import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';

export default class SmartNotifications extends LightningElement {
    @api height = '400px';
    @api maxNotifications = 50;
    @api enableRealTime = false;

    @track notifications = [];
    @track isLoading = false;
    @track error;
    @track showSettings = false;
    @track notificationSettings = {
        enableEmailAlerts: true,
        enableInAppAlerts: true,
        enableSMSAlerts: false,
        performanceThreshold: 70,
        executionTimeThreshold: 5000,
        cpuTimeThreshold: 3000,
        riskLevelThresholds: ['High', 'Critical']
    };

    subscription = {};
    channelName = '/event/FlowSense_Alert__e';

    connectedCallback() {
        this.loadNotificationSettings();
        this.loadRecentNotifications();
        
        if (this.enableRealTime && isEmpEnabled) {
            this.subscribeToNotifications();
        }
    }

    disconnectedCallback() {
        if (this.subscription) {
            this.unsubscribeFromNotifications();
        }
    }

    // ===== Real-time Subscription Methods =====
    subscribeToNotifications() {
        const messageCallback = (response) => {
            this.handleNewNotification(response.data.payload);
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
            console.log('Successfully subscribed to notifications channel');
        }).catch(error => {
            this.error = 'Failed to subscribe to notifications: ' + error.message;
            console.error(error);
        });

        onError(error => {
            console.error('Streaming API error: ', error);
        });
    }

    unsubscribeFromNotifications() {
        unsubscribe(this.subscription, response => {
            console.log('Unsubscribed from notifications channel');
        });
    }

    // ===== Notification Processing =====
    handleNewNotification(notificationData) {
        const notification = {
            id: notificationData.Id || this.generateNotificationId(),
            title: notificationData.Title__c,
            message: notificationData.Message__c,
            severity: notificationData.Severity__c,
            category: notificationData.Category__c,
            flowName: notificationData.Flow_Name__c,
            timestamp: notificationData.CreatedDate || new Date().toISOString(),
            isRead: false,
            actionType: notificationData.Action_Type__c,
            threshold: notificationData.Threshold_Value__c,
            actualValue: notificationData.Actual_Value__c
        };

        this.addNotificationToList(notification);
        this.showInAppNotification(notification);
        this.triggerAdditionalAlerts(notification);
    }

    addNotificationToList(notification) {
        this.notifications = [notification, ...this.notifications.slice(0, this.maxNotifications - 1)];
    }

    showInAppNotification(notification) {
        if (!this.notificationSettings.enableInAppAlerts) return;

        const variant = this.getToastVariant(notification.severity);
        const mode = notification.severity === 'Critical' ? 'sticky' : 'dismissable';

        this.dispatchEvent(
            new ShowToastEvent({
                title: notification.title,
                message: `${notification.flowName}: ${notification.message}`,
                variant: variant,
                mode: mode
            })
        );
    }

    triggerAdditionalAlerts(notification) {
        if (notification.severity === 'Critical' || notification.severity === 'High') {
            this.triggerEmailAlert(notification);
            this.triggerSMSAlert(notification);
        }
    }

    // ===== Alert Methods =====
    async triggerEmailAlert(notification) {
        if (!this.notificationSettings.enableEmailAlerts) return;
        
        try {
            // Call Apex method to send email
            // Implementation would depend on your email service setup
            console.log('Email alert triggered for:', notification);
        } catch (error) {
            console.error('Failed to send email alert:', error);
        }
    }

    async triggerSMSAlert(notification) {
        if (!this.notificationSettings.enableSMSAlerts) return;
        
        try {
            // Call Apex method to send SMS
            // Implementation would depend on your SMS service setup
            console.log('SMS alert triggered for:', notification);
        } catch (error) {
            console.error('Failed to send SMS alert:', error);
        }
    }

    // ===== Data Loading =====
    async loadRecentNotifications() {
        this.isLoading = true;
        this.error = undefined;

        try {
            // Simulate loading recent notifications
            // In real implementation, call Apex method
            await this.simulateLoadNotifications();
        } catch (error) {
            this.error = error.message;
        } finally {
            this.isLoading = false;
        }
    }

    async simulateLoadNotifications() {
        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        this.notifications = [
            {
                id: '1',
                title: 'Performance Degradation Alert',
                message: 'Performance score dropped below 70%',
                severity: 'High',
                category: 'Performance',
                flowName: 'Customer Onboarding',
                timestamp: new Date(Date.now() - 1800000).toISOString(),
                isRead: false,
                actionType: 'Performance_Check',
                threshold: '70%',
                actualValue: '65%'
            },
            {
                id: '2',
                title: 'Execution Time Warning',
                message: 'Average execution time exceeded threshold',
                severity: 'Medium',
                category: 'Performance',
                flowName: 'Lead Assignment',
                timestamp: new Date(Date.now() - 3600000).toISOString(),
                isRead: true,
                actionType: 'Execution_Time',
                threshold: '5000ms',
                actualValue: '7200ms'
            },
            {
                id: '3',
                title: 'Flow Optimization Opportunity',
                message: 'SOQL queries can be optimized',
                severity: 'Low',
                category: 'Optimization',
                flowName: 'Opportunity Management',
                timestamp: new Date(Date.now() - 7200000).toISOString(),
                isRead: true,
                actionType: 'Optimization',
                threshold: '10 queries',
                actualValue: '15 queries'
            }
        ];
    }

    loadNotificationSettings() {
        // Load from localStorage or user preferences
        const savedSettings = localStorage.getItem('flowsense_notification_settings');
        if (savedSettings) {
            this.notificationSettings = { ...this.notificationSettings, ...JSON.parse(savedSettings) };
        }
    }

    // ===== Event Handlers =====
    handleNotificationClick(event) {
        const notificationId = event.currentTarget.dataset.id;
        this.markAsRead(notificationId);
    }

    handleMarkAllAsRead() {
        this.notifications = this.notifications.map(notification => ({
            ...notification,
            isRead: true
        }));
    }

    handleClearAll() {
        this.notifications = [];
    }

    handleSettingsToggle() {
        this.showSettings = !this.showSettings;
    }

    handleSettingsChange(event) {
        const { name, value, type, checked } = event.target;
        const newValue = type === 'checkbox' ? checked : value;
        
        this.notificationSettings = {
            ...this.notificationSettings,
            [name]: newValue
        };

        this.saveNotificationSettings();
    }

    markAsRead(notificationId) {
        this.notifications = this.notifications.map(notification => 
            notification.id === notificationId 
                ? { ...notification, isRead: true }
                : notification
        );
    }

    saveNotificationSettings() {
        localStorage.setItem('flowsense_notification_settings', JSON.stringify(this.notificationSettings));
    }

    // ===== Utility Methods =====
    getToastVariant(severity) {
        const variantMap = {
            'Critical': 'error',
            'High': 'warning',
            'Medium': 'warning',
            'Low': 'info',
            'Info': 'success'
        };
        return variantMap[severity] || 'info';
    }

    getSeverityClass(severity) {
        return `notification-severity severity-${severity.toLowerCase()}`;
    }

    getCategoryIcon(category) {
        const iconMap = {
            'Performance': 'utility:warning',
            'Security': 'utility:shield',
            'Optimization': 'utility:opportunity',
            'System': 'utility:settings',
            'User': 'utility:user'
        };
        return iconMap[category] || 'utility:notification';
    }

    generateNotificationId() {
        return Date.now().toString() + Math.random().toString(36).substr(2, 9);
    }

    formatTimestamp(timestamp) {
        const date = new Date(timestamp);
        const now = new Date();
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMs / 3600000);
        const diffDays = Math.floor(diffMs / 86400000);

        if (diffMins < 1) return 'Just now';
        if (diffMins < 60) return `${diffMins}m ago`;
        if (diffHours < 24) return `${diffHours}h ago`;
        if (diffDays < 7) return `${diffDays}d ago`;
        return date.toLocaleDateString();
    }

    // ===== Getters =====
    get unreadCount() {
        return this.notifications.filter(n => !n.isRead).length;
    }

    get hasNotifications() {
        return this.notifications.length > 0;
    }

    get containerStyle() {
        return `height: ${this.height}; max-height: ${this.height};`;
    }

    get sortedNotifications() {
        return [...this.notifications].sort((a, b) => {
            if (a.isRead !== b.isRead) return a.isRead ? 1 : -1;
            return new Date(b.timestamp) - new Date(a.timestamp);
        });
    }

    get showEmptyState() {
        return !this.hasNotifications && !this.isLoading && !this.error;
    }

    get showNotificationsList() {
        return this.hasNotifications && !this.isLoading;
    }
}