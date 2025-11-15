import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getFlowSenseSettings from '@salesforce/apex/FS_SettingsService.getFlowSenseSettings';
import saveFlowSenseSettings from '@salesforce/apex/FS_SettingsService.saveFlowSenseSettings';
import resetSettingsToDefault from '@salesforce/apex/FS_SettingsService.resetSettingsToDefault';

export default class FsSettings extends LightningElement {
    @api height = '600px';
    @api initialSection = 'general';

    @track currentSection = 'general';
    @track isLoading = false;
    @track hasUnsavedChanges = false;

    // Settings data structure
    @track settings = {
        // General settings
        enableMonitoring: true,
        monitoringLevel: 'standard',
        dataRetentionDays: 90,
        enablePerformanceTracking: true,
        batchSize: 200,
        
        // Thresholds
        thresholds: {
            warningDuration: 5000,
            criticalDuration: 30000,
            maxCpuTime: 10000,
            maxSoqlQueries: 50,
            maxDmlStatements: 75,
            warningErrorRate: 5.0,
            criticalErrorRate: 15.0
        },
        
        // Notifications
        notifications: {
            enableEmail: false,
            emailRecipients: '',
            reportFrequency: 'weekly',
            reportDay: 'monday',
            alertTriggers: {
                performanceThreshold: true,
                errorThreshold: true,
                failedFlows: true,
                resourceLimits: false,
                dailyDigest: true
            }
        },
        
        // System
        system: {
            autoArchive: true,
            archiveAfterDays: 365,
            cleanupSchedule: 'daily',
            analysisSchedule: 'hourly',
            enableDebugLogging: false,
            logLevel: 'info'
        }
    };

    // Setting sections configuration
    settingSections = [
        {
            key: 'general',
            label: 'General',
            icon: 'utility:settings',
            buttonClass: 'menu-button active'
        },
        {
            key: 'thresholds',
            label: 'Thresholds',
            icon: 'utility:metrics',
            buttonClass: 'menu-button'
        },
        {
            key: 'notifications',
            label: 'Notifications',
            icon: 'utility:notification',
            buttonClass: 'menu-button'
        },
        {
            key: 'system',
            label: 'System',
            icon: 'utility:database',
            buttonClass: 'menu-button'
        }
    ];

    // Options for various dropdowns
    monitoringLevelOptions = [
        { label: 'Basic', value: 'basic' },
        { label: 'Standard', value: 'standard' },
        { label: 'Detailed', value: 'detailed' },
        { label: 'Verbose', value: 'verbose' }
    ];

    reportFrequencyOptions = [
        { label: 'Daily', value: 'daily' },
        { label: 'Weekly', value: 'weekly' },
        { label: 'Monthly', value: 'monthly' }
    ];

    reportDayOptions = [
        { label: 'Monday', value: 'monday' },
        { label: 'Tuesday', value: 'tuesday' },
        { label: 'Wednesday', value: 'wednesday' },
        { label: 'Thursday', value: 'thursday' },
        { label: 'Friday', value: 'friday' },
        { label: 'Saturday', value: 'saturday' },
        { label: 'Sunday', value: 'sunday' }
    ];

    scheduleOptions = [
        { label: 'Hourly', value: 'hourly' },
        { label: 'Every 6 Hours', value: '6hourly' },
        { label: 'Daily', value: 'daily' },
        { label: 'Weekly', value: 'weekly' }
    ];

    logLevelOptions = [
        { label: 'Error', value: 'error' },
        { label: 'Warning', value: 'warning' },
        { label: 'Info', value: 'info' },
        { label: 'Debug', value: 'debug' },
        { label: 'Trace', value: 'trace' }
    ];

    // Wired method to load settings
    @wire(getFlowSenseSettings)
    wiredSettings({ error, data }) {
        if (data) {
            this.settings = { ...this.settings, ...data };
            this.hasUnsavedChanges = false;
        } else if (error) {
            this.showError('Error loading settings: ' + error.body.message);
        }
    }

    connectedCallback() {
        this.currentSection = this.initialSection;
        this.updateSectionButtons();
    }

    get containerStyle() {
        return `height: ${this.height}`;
    }

    get saveDisabled() {
        return !this.hasUnsavedChanges || this.isLoading;
    }

    get isGeneralSection() {
        return this.currentSection === 'general';
    }

    get isThresholdsSection() {
        return this.currentSection === 'thresholds';
    }

    get isNotificationsSection() {
        return this.currentSection === 'notifications';
    }

    get isSystemSection() {
        return this.currentSection === 'system';
    }

    get isReportDayDisabled() {
        return this.settings.notifications.reportFrequency === 'daily';
    }

    get archiveDisabled() {
        return !this.settings.system.autoArchive;
    }

    get logLevelDisabled() {
        return !this.settings.system.enableDebugLogging;
    }

    get alertTriggerOptions() {
        return [
            {
                label: 'Performance Threshold Exceeded',
                value: 'performanceThreshold',
                checked: this.settings.notifications.alertTriggers.performanceThreshold
            },
            {
                label: 'Error Rate Threshold Exceeded',
                value: 'errorThreshold',
                checked: this.settings.notifications.alertTriggers.errorThreshold
            },
            {
                label: 'Failed Flow Executions',
                value: 'failedFlows',
                checked: this.settings.notifications.alertTriggers.failedFlows
            },
            {
                label: 'Resource Limit Warnings',
                value: 'resourceLimits',
                checked: this.settings.notifications.alertTriggers.resourceLimits
            },
            {
                label: 'Daily Performance Digest',
                value: 'dailyDigest',
                checked: this.settings.notifications.alertTriggers.dailyDigest
            }
        ];
    }

    // Event handlers
    handleSectionChange(event) {
        const newSection = event.currentTarget.dataset.section;
        if (newSection !== this.currentSection) {
            this.currentSection = newSection;
            this.updateSectionButtons();
        }
    }

    updateSectionButtons() {
        this.settingSections = this.settingSections.map(section => ({
            ...section,
            buttonClass: section.key === this.currentSection ? 'menu-button active' : 'menu-button'
        }));
    }

    // General settings handlers
    handleToggleChange(event) {
        const field = event.currentTarget.dataset.field;
        this.settings = {
            ...this.settings,
            [field]: event.target.checked
        };
        this.hasUnsavedChanges = true;
    }

    handleSelectChange(event) {
        const field = event.currentTarget.dataset.field;
        this.settings = {
            ...this.settings,
            [field]: event.detail.value
        };
        this.hasUnsavedChanges = true;
    }

    handleInputChange(event) {
        const field = event.currentTarget.dataset.field;
        const value = event.target.type === 'number' ? 
                     parseFloat(event.target.value) : 
                     event.target.value;
        
        this.settings = {
            ...this.settings,
            [field]: value
        };
        this.hasUnsavedChanges = true;
    }

    // Threshold handlers
    handleThresholdChange(event) {
        const threshold = event.currentTarget.dataset.threshold;
        const value = parseFloat(event.target.value);
        
        this.settings = {
            ...this.settings,
            thresholds: {
                ...this.settings.thresholds,
                [threshold]: value
            }
        };
        this.hasUnsavedChanges = true;
    }

    // Notification handlers
    handleNotificationToggle(event) {
        const notification = event.currentTarget.dataset.notification;
        this.settings = {
            ...this.settings,
            notifications: {
                ...this.settings.notifications,
                [notification]: event.target.checked
            }
        };
        this.hasUnsavedChanges = true;
    }

    handleNotificationChange(event) {
        const notification = event.currentTarget.dataset.notification;
        this.settings = {
            ...this.settings,
            notifications: {
                ...this.settings.notifications,
                [notification]: event.target.value
            }
        };
        this.hasUnsavedChanges = true;
    }

    handleAlertTriggerChange(event) {
        const trigger = event.currentTarget.dataset.trigger;
        this.settings = {
            ...this.settings,
            notifications: {
                ...this.settings.notifications,
                alertTriggers: {
                    ...this.settings.notifications.alertTriggers,
                    [trigger]: event.target.checked
                }
            }
        };
        this.hasUnsavedChanges = true;
    }

    // System handlers
    handleSystemToggle(event) {
        const system = event.currentTarget.dataset.system;
        this.settings = {
            ...this.settings,
            system: {
                ...this.settings.system,
                [system]: event.target.checked
            }
        };
        this.hasUnsavedChanges = true;
    }

    handleSystemChange(event) {
        const system = event.currentTarget.dataset.system;
        const value = event.target.type === 'number' ? 
                     parseFloat(event.target.value) : 
                     event.target.value;
        
        this.settings = {
            ...this.settings,
            system: {
                ...this.settings.system,
                [system]: value
            }
        };
        this.hasUnsavedChanges = true;
    }

    // Save and reset operations
    async saveSettings() {
        if (!this.hasUnsavedChanges) return;

        this.isLoading = true;
        try {
            // Validate settings before saving
            if (this.validateSettings()) {
                await saveFlowSenseSettings({ settings: this.settings });
                this.hasUnsavedChanges = false;
                this.showSuccess('Settings saved successfully');
                
                // Refresh the wired data
                return refreshApex(this.wiredSettings);
            }
        } catch (error) {
            this.showError('Error saving settings: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }

    async resetToDefaults() {
        if (!confirm('Are you sure you want to reset all settings to default values? This action cannot be undone.')) {
            return;
        }

        this.isLoading = true;
        try {
            const defaultSettings = await resetSettingsToDefault();
            this.settings = { ...this.settings, ...defaultSettings };
            this.hasUnsavedChanges = true;
            this.showSuccess('Settings reset to defaults. Don\'t forget to save!');
        } catch (error) {
            this.showError('Error resetting settings: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }

    // Validation
    validateSettings() {
        const errors = [];

        // Validate thresholds
        if (this.settings.thresholds.criticalDuration <= this.settings.thresholds.warningDuration) {
            errors.push('Critical duration threshold must be greater than warning threshold');
        }

        if (this.settings.thresholds.criticalErrorRate <= this.settings.thresholds.warningErrorRate) {
            errors.push('Critical error rate threshold must be greater than warning threshold');
        }

        // Validate data retention
        if (this.settings.dataRetentionDays < 7) {
            errors.push('Data retention must be at least 7 days');
        }

        // Validate email recipients
        if (this.settings.notifications.enableEmail && !this.settings.notifications.emailRecipients) {
            errors.push('Email recipients are required when email notifications are enabled');
        }

        // Validate email format
        if (this.settings.notifications.emailRecipients) {
            const emails = this.settings.notifications.emailRecipients.split(',').map(e => e.trim());
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            
            for (const email of emails) {
                if (email && !emailRegex.test(email)) {
                    errors.push(`Invalid email format: ${email}`);
                }
            }
        }

        // Show errors if any
        if (errors.length > 0) {
            this.showError('Validation errors:\n' + errors.join('\n'));
            return false;
        }

        return true;
    }

    // Utility methods
    showError(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'sticky'
        }));
    }

    showSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        }));
    }

    showWarning(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Warning',
            message: message,
            variant: 'warning'
        }));
    }
}