import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getFlowSteps from '@salesforce/apex/FS_FlowStepSelector.selectByFlowRunId';

const FLOW_RUN_FIELDS = [
    'FS_Flow_Run__c.Flow_Api_Name__c',
    'FS_Flow_Run__c.Flow_Label__c',
    'FS_Flow_Run__c.Flow_Version__c',
    'FS_Flow_Run__c.Status__c',
    'FS_Flow_Run__c.Started_At__c',
    'FS_Flow_Run__c.Ended_At__c',
    'FS_Flow_Run__c.CPU_Time_Millis__c',
    'FS_Flow_Run__c.SOQL_Count__c',
    'FS_Flow_Run__c.DML_Count__c',
    'FS_Flow_Run__c.Error_Message__c'
];

export default class FsRunExplorer extends LightningElement {
    @api runId; // Flow Run ID from property
    @api height = '600px'; // Component height
    @api recordId; // Flow Run ID from record page context
    @track flowSteps = [];
    @track selectedStepId = null;

    @wire(getRecord, { recordId: '$recordId', fields: FLOW_RUN_FIELDS })
    flowRunRecord;

    @wire(getFlowSteps, { flowRunId: '$effectiveRunId' })
    wiredFlowSteps({ error, data }) {
        if (data) {
            this.flowSteps = data.map((step, index) => {
                return {
                    ...step,
                    timelineClass: this.getTimelineClass(step),
                    showDetails: false,
                    isLast: index === data.length - 1
                };
            });
        } else if (error) {
            console.error('Error fetching flow steps:', error);
        }
    }

    get flowRun() {
        return this.flowRunRecord?.data?.fields ? {
            Flow_Api_Name__c: this.flowRunRecord.data.fields.Flow_Api_Name__c?.value,
            Flow_Label__c: this.flowRunRecord.data.fields.Flow_Label__c?.value,
            Flow_Version__c: this.flowRunRecord.data.fields.Flow_Version__c?.value,
            Status__c: this.flowRunRecord.data.fields.Status__c?.value,
            Started_At__c: this.flowRunRecord.data.fields.Started_At__c?.value,
            Ended_At__c: this.flowRunRecord.data.fields.Ended_At__c?.value,
            CPU_Time_Millis__c: this.flowRunRecord.data.fields.CPU_Time_Millis__c?.value || 0,
            SOQL_Count__c: this.flowRunRecord.data.fields.SOQL_Count__c?.value || 0,
            DML_Count__c: this.flowRunRecord.data.fields.DML_Count__c?.value || 0,
            Error_Message__c: this.flowRunRecord.data.fields.Error_Message__c?.value
        } : {};
    }

    get statusVariant() {
        const status = this.flowRun.Status__c;
        switch (status) {
            case 'Success': return 'success';
            case 'Failed': return 'error';
            case 'InProgress': return 'warning';
            default: return 'inverse';
        }
    }

    get totalDuration() {
        if (this.flowRun.Started_At__c && this.flowRun.Ended_At__c) {
            const start = new Date(this.flowRun.Started_At__c);
            const end = new Date(this.flowRun.Ended_At__c);
            return end.getTime() - start.getTime();
        }
        return 0;
    }

    get stepCount() {
        return this.flowSteps.length;
    }

    get hasError() {
        return this.flowRun.Error_Message__c && this.flowRun.Error_Message__c.trim();
    }

    getTimelineClass(step) {
        let baseClass = 'timeline-step';
        
        // Add type-specific class
        if (step.Element_Type__c) {
            baseClass += ` step-${step.Element_Type__c.toLowerCase()}`;
        }
        
        // Add performance-based class
        if (step.Duration_Millis__c > 1000) {
            baseClass += ' step-slow';
        } else if (step.Duration_Millis__c > 500) {
            baseClass += ' step-medium';
        } else {
            baseClass += ' step-fast';
        }
        
        // Add error class if there's an outcome indicating error
        if (step.Outcome__c && step.Outcome__c.toLowerCase().includes('error')) {
            baseClass += ' step-error';
        }
        
        return baseClass;
    }

    handleStepClick(event) {
        const stepId = event.currentTarget.dataset.stepId;
        
        // Toggle details for the clicked step
        this.flowSteps = this.flowSteps.map(step => {
            if (step.Id === stepId) {
                return { ...step, showDetails: !step.showDetails };
            } else {
                return { ...step, showDetails: false };
            }
        });
        
        this.selectedStepId = this.selectedStepId === stepId ? null : stepId;
    }
}