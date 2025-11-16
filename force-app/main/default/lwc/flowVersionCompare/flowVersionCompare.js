import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import compareFlowVersions from '@salesforce/apex/FS_DiffService.compareFlowVersions';

export default class FlowVersionCompare extends LightningElement {
    @track flowApiName = '';
    @track fromVersion = 1;
    @track toVersion = 2;
    @track comparisonResult = null;
    @track isLoading = false;
    @track showDetails = false;

    // Sample flows for testing
    flowOptions = [
        { label: 'Test_Diff_Flow', value: 'Test_Diff_Flow' },
        { label: 'Simple_Contact_Creation', value: 'Simple_Contact_Creation' },
        { label: 'Complex_Opportunity_Flow', value: 'Complex_Opportunity_Flow' }
    ];

    get hasResult() {
        return this.comparisonResult !== null;
    }

    get hasElementChanges() {
        return this.comparisonResult?.elementChanges?.length > 0;
    }

    get hasFormulaChanges() {
        return this.comparisonResult?.formulaChanges?.length > 0;
    }

    get hasDecisionChanges() {
        return this.comparisonResult?.decisionPathChanges?.length > 0;
    }

    get performanceData() {
        if (!this.comparisonResult?.performanceChange) return null;
        
        const perf = this.comparisonResult.performanceChange;
        return [
            {
                metric: 'CPU Time',
                improvement: perf.cpuImprovement,
                isPositive: perf.cpuImprovement > 0,
                icon: 'utility:processor',
                iconVariant: perf.cpuImprovement > 0 ? 'success' : 'error',
                trendIcon: perf.cpuImprovement > 0 ? 'utility:arrowup' : 'utility:arrowdown',
                trendLabel: perf.cpuImprovement > 0 ? 'improvement' : 'regression'
            },
            {
                metric: 'Memory Usage',
                improvement: perf.memoryImprovement,
                isPositive: perf.memoryImprovement > 0,
                icon: 'utility:database',
                iconVariant: perf.memoryImprovement > 0 ? 'success' : 'error',
                trendIcon: perf.memoryImprovement > 0 ? 'utility:arrowup' : 'utility:arrowdown',
                trendLabel: perf.memoryImprovement > 0 ? 'improvement' : 'regression'
            },
            {
                metric: 'Execution Time',
                improvement: perf.executionTimeImprovement,
                isPositive: perf.executionTimeImprovement > 0,
                icon: 'utility:clock',
                iconVariant: perf.executionTimeImprovement > 0 ? 'success' : 'error',
                trendIcon: perf.executionTimeImprovement > 0 ? 'utility:arrowup' : 'utility:arrowdown',
                trendLabel: perf.executionTimeImprovement > 0 ? 'faster execution' : 'slower execution'
            },
            {
                metric: 'Complexity',
                improvement: Math.abs(perf.complexityChange),
                isPositive: perf.complexityChange <= 0,
                icon: 'utility:hierarchy',
                iconVariant: perf.complexityChange <= 0 ? 'success' : 'warning',
                trendIcon: perf.complexityChange <= 0 ? 'utility:arrowdown' : 'utility:arrowup',
                trendLabel: perf.complexityChange <= 0 ? 'simplified' : 'more complex'
            }
        ];
    }

    get riskLevel() {
        if (!this.comparisonResult?.performanceChange?.riskScore) return 'low';
        
        const score = this.comparisonResult.performanceChange.riskScore;
        if (score >= 7) return 'high';
        if (score >= 4) return 'medium';
        return 'low';
    }

    get riskLevelClass() {
        return `risk-indicator risk-${this.riskLevel}`;
    }

    get showDetailsLabel() {
        return this.showDetails ? 'Hide Details' : 'Show Details';
    }

    handleFlowChange(event) {
        this.flowApiName = event.detail.value;
    }

    handleFromVersionChange(event) {
        this.fromVersion = parseInt(event.target.value);
    }

    handleToVersionChange(event) {
        this.toVersion = parseInt(event.target.value);
    }

    async handleCompare() {
        if (!this.flowApiName || this.fromVersion === null || this.toVersion === null) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }

        this.isLoading = true;
        this.comparisonResult = null;

        try {
            const result = await compareFlowVersions({
                flowApiName: this.flowApiName,
                fromVersion: this.fromVersion,
                toVersion: this.toVersion
            });

            this.comparisonResult = result;

            if (result.success) {
                this.showToast('Success', 'Flow comparison completed successfully', 'success');
            } else {
                this.showToast('Error', result.errorMessage || 'Comparison failed', 'error');
            }

        } catch (error) {
            console.error('Error comparing flows:', error);
            this.showToast('Error', 'Failed to compare flow versions', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleToggleDetails() {
        this.showDetails = !this.showDetails;
    }

    getChangeTypeClass(changeType) {
        switch (changeType) {
            case 'ADDED':
                return 'change-added';
            case 'REMOVED':
                return 'change-removed';
            case 'MODIFIED':
                return 'change-modified';
            default:
                return 'change-default';
        }
    }

    getImpactClass(impact) {
        if (!impact) return 'impact-low';
        
        switch (impact.toUpperCase()) {
            case 'HIGH':
                return 'impact-high';
            case 'MEDIUM':
                return 'impact-medium';
            case 'LOW':
                return 'impact-low';
            default:
                return 'impact-low';
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}