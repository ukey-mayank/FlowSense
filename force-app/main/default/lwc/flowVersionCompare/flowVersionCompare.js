import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import compareFlowVersions from '@salesforce/apex/FS_DiffService.compareFlowVersions';
import getFlowOptions from '@salesforce/apex/FS_DiffService.getFlowOptions';
import getFlowVersions from '@salesforce/apex/FS_DiffService.getFlowVersions';

export default class FlowVersionCompare extends LightningElement {
    @track flowApiName = '';
    @track fromVersion = '';
    @track toVersion = '';
    @track comparisonResult = null;
    @track isLoading = false;
    @track showDetails = false;
    @track isLoadingVersions = false;

    @track flowOptions = [];
    @track fromVersionOptions = [];
    @track toVersionOptions = [];
    @track availableVersions = [];

    // Wire to get flow options
    @wire(getFlowOptions)
    wiredFlowOptions({ error, data }) {
        if (data) {
            this.flowOptions = data.map(flow => ({
                label: flow.label, // Already includes latest version and run count
                value: flow.value
            }));
        } else if (error) {
            console.error('Error loading flow options:', error);
            this.showToast('Error', 'Failed to load flow options', 'error');
        }
    }

    get hasResult() {
        return this.comparisonResult !== null;
    }

    get hasSingleVersionOnly() {
        return this.availableVersions && this.availableVersions.length === 1;
    }

    get compareButtonDisabled() {
        return this.isLoading || this.hasSingleVersionOnly || !this.flowApiName || !this.fromVersion || !this.toVersion;
    }

    get versionDropdownsDisabled() {
        return this.isLoadingVersions || this.hasSingleVersionOnly;
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

    async handleFlowChange(event) {
        this.flowApiName = event.detail.value;
        this.fromVersion = '';
        this.toVersion = '';
        this.comparisonResult = null;
        
        if (this.flowApiName) {
            await this.loadFlowVersions();
        } else {
            this.clearVersionOptions();
        }
    }

    async loadFlowVersions() {
        this.isLoadingVersions = true;
        
        try {
            const versions = await getFlowVersions({ flowApiName: this.flowApiName });
            this.availableVersions = versions;
            
            // Check if flow has exactly one version (not zero or multiple)
            if (versions.length === 1) {
                this.showToast(
                    'Single Version Flow', 
                    `This flow (${this.flowApiName}) has only one version (v${versions[0]}). Version comparison requires at least two versions.`, 
                    'warning'
                );
                this.clearVersionOptions();
                return;
            } else if (versions.length === 0) {
                this.showToast(
                    'No Versions Found', 
                    `No versions found for flow: ${this.flowApiName}. Please check if the flow exists.`, 
                    'error'
                );
                this.clearVersionOptions();
                return;
            }
            
            // Create version options for flows with multiple versions
            this.fromVersionOptions = versions.map(version => ({
                label: `Version ${version}`,
                value: version.toString()
            }));
            
            this.toVersionOptions = versions.map(version => ({
                label: `Version ${version}`,
                value: version.toString()
            }));
            
            // Set smart default values - compare the two most recent versions
            if (versions.length >= 2) {
                this.fromVersion = versions[versions.length - 2].toString(); // Second latest
                this.toVersion = versions[versions.length - 1].toString();   // Latest
            }
            
        } catch (error) {
            console.error('Error loading flow versions:', error);
            this.showToast('Error', 'Failed to load flow versions', 'error');
            this.clearVersionOptions();
        } finally {
            this.isLoadingVersions = false;
        }
    }

    clearVersionOptions() {
        this.availableVersions = [];
        this.fromVersionOptions = [];
        this.toVersionOptions = [];
        this.fromVersion = '';
        this.toVersion = '';
    }

    handleFromVersionChange(event) {
        this.fromVersion = event.detail.value;
    }

    handleToVersionChange(event) {
        this.toVersion = event.detail.value;
    }

    async handleCompare() {
        if (!this.flowApiName || !this.fromVersion || !this.toVersion) {
            this.showToast('Error', 'Please select a flow and both version numbers', 'error');
            return;
        }

        if (this.hasSingleVersionOnly) {
            this.showToast('Warning', 'Cannot compare versions - this flow has only one version available', 'warning');
            return;
        }

        const fromVersionNum = parseInt(this.fromVersion);
        const toVersionNum = parseInt(this.toVersion);

        if (fromVersionNum >= toVersionNum) {
            this.showToast('Error', 'From Version must be less than To Version', 'error');
            return;
        }

        this.isLoading = true;
        this.comparisonResult = null;

        try {
            const result = await compareFlowVersions({
                flowApiName: this.flowApiName,
                fromVersion: fromVersionNum,
                toVersion: toVersionNum
            });

            this.comparisonResult = result;
            
            // Try to access properties directly
            const success = result.success;
            const errorMessage = result.errorMessage;

            if (success === true) {
                this.showToast('Success', `Flow comparison completed successfully: v${fromVersionNum} → v${toVersionNum}`, 'success');
            } else {
                this.showToast('Error', errorMessage || 'Comparison failed', 'error');
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