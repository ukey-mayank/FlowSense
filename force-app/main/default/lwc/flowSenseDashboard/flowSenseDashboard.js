import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getFlowAnalytics from '@salesforce/apex/FS_DashboardController.getFlowAnalytics';
import getPerformanceMetrics from '@salesforce/apex/FS_DashboardController.getPerformanceMetrics';
import getAllFlowNames from '@salesforce/apex/FS_DashboardController.getAllFlowNames';
import getFlowDetails from '@salesforce/apex/FS_DashboardController.getFlowDetails';
import triggerFlowAnalysis from '@salesforce/apex/FS_DashboardController.triggerFlowAnalysis';

export default class FlowSenseDashboard extends LightningElement {
    @track flowAnalysisData = [];
    @track totalExecutions = 0;
    @track averagePerformanceScore = 0;
    @track highRiskFlows = 0;
    @track averageExecutionTime = 0;
    @track isLoading = false;
    @track selectedTimeRange = '7';
    @track selectedRiskLevel = '';
    @track searchTerm = '';
    @track flowOptions = [];
    @track allFlowOptions = [];
    @track showFlowDetailModal = false;
    @track selectedFlowDetails = null;
    @track isAnalyzing = false;
    @track isRefreshing = false; // Track refresh state separately
    @track refreshKey = 0; // Add refresh key for forcing re-renders

    columns = [
        {
            label: 'Flow Name',
            fieldName: 'flowName',
            type: 'text',
            sortable: true
        },
        {
            label: 'Last Execution',
            fieldName: 'lastExecution',
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'short',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit'
            },
            sortable: true
        },
        {
            label: 'Performance Score',
            fieldName: 'performanceScore',
            type: 'number',
            cellAttributes: {
                class: { fieldName: 'performanceScoreClass' }
            },
            sortable: true
        },
        {
            label: 'Risk Level',
            fieldName: 'riskLevel',
            type: 'text',
            cellAttributes: {
                class: { fieldName: 'riskLevelClass' }
            },
            sortable: true
        },
        {
            label: 'Avg Duration (ms)',
            fieldName: 'averageDuration',
            type: 'number',
            sortable: true
        },
        {
            label: 'Execution Count',
            fieldName: 'executionCount',
            type: 'number',
            sortable: true
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View Details', name: 'view_details' },
                    { label: 'Analyze', name: 'analyze' }
                ]
            }
        }
    ];

    timeRangeOptions = [
        { label: 'Last 24 Hours', value: '1' },
        { label: 'Last 7 Days', value: '7' },
        { label: 'Last 30 Days', value: '30' },
        { label: 'Last 90 Days', value: '90' }
    ];

    riskLevelOptions = [
        { label: 'All Risk Levels', value: '' },
        { label: 'Low', value: 'Low' },
        { label: 'Medium', value: 'Medium' },
        { label: 'High', value: 'High' },
        { label: 'Critical', value: 'Critical' }
    ];

    connectedCallback() {
        this.isLoading = true;
        Promise.all([
            this.loadFlowOptions(),
            this.loadDashboardData()
        ]).finally(() => {
            this.isLoading = false;
        });
    }

    async loadFlowOptions() {
        try {
            const flowData = await getAllFlowNames();
            this.allFlowOptions = flowData.map(flow => ({
                label: flow.label,
                value: flow.value
            }));
            this.flowOptions = [...this.allFlowOptions];
        } catch (error) {
            console.error('Error loading flow options:', error);
            this.showToast('Error', 'Failed to load flow names', 'error');
        }
    }

    async loadDashboardData() {
        console.log('Loading dashboard data...');
        
        try {
            // Add timestamp to prevent caching
            const timestamp = new Date().getTime();
            
            console.log('Making API calls with params:', {
                daysPast: parseInt(this.selectedTimeRange),
                riskLevel: this.selectedRiskLevel,
                searchTerm: this.searchTerm,
                timestamp: timestamp
            });

            const [analyticsData, metricsData] = await Promise.all([
                getFlowAnalytics({
                    daysPast: parseInt(this.selectedTimeRange),
                    riskLevel: this.selectedRiskLevel,
                    searchTerm: this.searchTerm
                }),
                getPerformanceMetrics({
                    daysPast: parseInt(this.selectedTimeRange)
                })
            ]);

            console.log('Analytics data received:', analyticsData);
            console.log('Metrics data received:', metricsData);

            // Process data with force update
            if (analyticsData) {
                this.processAnalyticsData(analyticsData);
            } else {
                console.warn('No analytics data received');
                this.flowAnalysisData = [];
            }
            
            if (metricsData) {
                this.processMetricsData(metricsData);
            } else {
                console.warn('No metrics data received');
                this.totalExecutions = 0;
                this.averagePerformanceScore = 0;
                this.highRiskFlows = 0;
                this.averageExecutionTime = 0;
            }
            
            // Force component re-render
            this.template.querySelectorAll('lightning-datatable').forEach(table => {
                if (table) {
                    console.log('Forcing datatable refresh');
                }
            });
            
            console.log('Dashboard data loaded successfully');
        } catch (error) {
            console.error('Error loading dashboard data:', error);
            this.showToast('Error', 'Failed to load dashboard data: ' + (error.body?.message || error.message), 'error');
        }
    }

    processAnalyticsData(data) {
        console.log('Processing analytics data:', data);
        
        // Ensure we create a completely new array for reactivity
        this.flowAnalysisData = [...data.map(item => ({
            ...item,
            id: item.id || Math.random().toString(36).substr(2, 9), // Ensure unique IDs
            performanceScoreClass: this.getPerformanceScoreClass(item.performanceScore),
            riskLevelClass: this.getRiskLevelClass(item.riskLevel)
        }))];
        
        console.log('Processed flow analysis data:', this.flowAnalysisData);
    }

    processMetricsData(data) {
        console.log('Processing metrics data:', data);
        
        // Force reactivity by updating each property individually
        this.totalExecutions = parseInt(data.totalExecutions) || 0;
        this.averagePerformanceScore = parseFloat(data.averagePerformanceScore) || 0;
        this.highRiskFlows = parseInt(data.highRiskFlows) || 0;
        this.averageExecutionTime = parseFloat(data.averageExecutionTime) || 0;
        
        console.log('Updated metrics:', {
            totalExecutions: this.totalExecutions,
            averagePerformanceScore: this.averagePerformanceScore,
            highRiskFlows: this.highRiskFlows,
            averageExecutionTime: this.averageExecutionTime
        });
    }

    getPerformanceScoreClass(score) {
        if (score >= 80) return 'performance-high';
        if (score >= 60) return 'performance-medium';
        return 'performance-low';
    }

    getRiskLevelClass(riskLevel) {
        const classMap = {
            'Low': 'performance-high',
            'Medium': 'performance-medium', 
            'High': 'performance-low',
            'Critical': 'performance-low'
        };
        return classMap[riskLevel] || 'performance-medium';
    }

    handleTimeRangeChange(event) {
        this.selectedTimeRange = event.detail.value;
        // Don't auto-apply filters, wait for search button
    }

    handleRiskLevelChange(event) {
        this.selectedRiskLevel = event.detail.value;
        // Don't auto-apply filters, wait for search button
    }

    handleSearchChange(event) {
        this.searchTerm = event.detail.value;
        // Don't auto-apply filters, wait for search button
    }

    // New method to apply filters when Search button is clicked
    handleApplyFilters() {
        console.log('Applying filters:', {
            timeRange: this.selectedTimeRange,
            riskLevel: this.selectedRiskLevel,
            searchTerm: this.searchTerm
        });
        this.isLoading = true;
        this.loadDashboardData().finally(() => {
            this.isLoading = false;
        });
    }

    handleSearchFocus() {
        this.flowOptions = [...this.allFlowOptions];
    }

    async handleRefresh() {
        console.log('Refresh button clicked');
        this.isRefreshing = true;
        this.isLoading = true;
        
        // Reset all data to ensure fresh reload
        this.flowAnalysisData = [];
        this.totalExecutions = 0;
        this.averagePerformanceScore = 0;
        this.highRiskFlows = 0;
        this.averageExecutionTime = 0;
        
        // Increment refresh key to force component updates
        this.refreshKey += 1;
        
        try {
            // Force reload by reloading both data sources
            await Promise.all([
                this.loadDashboardData(),
                this.loadFlowOptions()
            ]);
            
            // Only show toast after successful completion
            this.showToast('Success', 'Dashboard refreshed successfully', 'success');
        } catch (error) {
            console.error('Error during refresh:', error);
            this.showToast('Error', 'Failed to refresh dashboard: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoading = false;
            this.isRefreshing = false;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'view_details':
                this.viewFlowDetails(row);
                break;
            case 'analyze':
                this.analyzeFlow(row);
                break;
        }
    }

    viewFlowDetails(row) {
        this.loadFlowDetails(row.flowName);
    }

    async loadFlowDetails(flowName) {
        try {
            this.isLoading = true;
            const details = await getFlowDetails({ flowName: flowName });
            this.selectedFlowDetails = details;
            this.showFlowDetailModal = true;
        } catch (error) {
            this.showToast('Error', `Failed to load details for ${flowName}: ` + error.body?.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async analyzeFlow(row) {
        try {
            this.isAnalyzing = true;
            const result = await triggerFlowAnalysis({ flowName: row.flowName });
            this.showToast('Success', result, 'success');
            
            setTimeout(() => {
                this.loadDashboardData();
            }, 2000);
            
        } catch (error) {
            this.showToast('Error', `Failed to analyze ${row.flowName}: ` + error.body?.message, 'error');
        } finally {
            this.isAnalyzing = false;
        }
    }

    handleCloseModal() {
        this.showFlowDetailModal = false;
        this.selectedFlowDetails = null;
    }

    get modalTitle() {
        return this.selectedFlowDetails ? `Flow Details - ${this.selectedFlowDetails.flowName}` : 'Flow Details';
    }

    get riskLevelClass() {
        if (!this.selectedFlowDetails?.riskLevel) return 'risk-indicator';
        return 'risk-indicator ' + this.getRiskLevelClass(this.selectedFlowDetails.riskLevel);
    }

    get riskIndicatorClass() {
        if (!this.selectedFlowDetails?.riskLevel) return 'risk-indicator';
        return 'risk-indicator ' + this.getRiskLevelClass(this.selectedFlowDetails.riskLevel);
    }

    get performanceClass() {
        if (!this.selectedFlowDetails?.performanceScore) return 'performance-medium';
        return this.getPerformanceScoreClass(this.selectedFlowDetails.performanceScore);
    }

    get performanceIndicatorClass() {
        if (!this.selectedFlowDetails?.performanceScore) return 'risk-indicator performance-medium';
        return 'risk-indicator ' + this.getPerformanceScoreClass(this.selectedFlowDetails.performanceScore);
    }

    get performanceLabel() {
        if (!this.selectedFlowDetails?.performanceScore) return 'No Data';
        const score = this.selectedFlowDetails.performanceScore;
        if (score >= 80) return 'Excellent';
        if (score >= 60) return 'Good';
        return 'Needs Improvement';
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    // Export functionality
    exportData() {
        try {
            if (!this.flowAnalysisData || this.flowAnalysisData.length === 0) {
                this.showToast('Warning', 'No data available to export', 'warning');
                return;
            }

            // Prepare data for export
            const exportData = this.flowAnalysisData.map(row => ({
                'Flow Name': row.flowName,
                'Last Execution': row.lastExecution ? new Date(row.lastExecution).toLocaleString() : 'N/A',
                'Performance Score': row.performanceScore || 'N/A',
                'Risk Level': row.riskLevel || 'N/A',
                'Average Duration (ms)': row.averageDuration || 'N/A',
                'Execution Count': row.executionCount || 'N/A',
                'Time Range': this.selectedTimeRange + ' days',
                'Export Date': new Date().toLocaleString()
            }));

            // Convert to CSV
            const csvContent = this.convertToCSV(exportData);
            
            // Create data URI for download (LWS compatible)
            const dataUri = 'data:text/plain;charset=utf-8,' + encodeURIComponent(csvContent);
            
            // Create and download file
            const element = document.createElement('a');
            element.href = dataUri;
            
            // Generate filename with timestamp
            const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, '-');
            element.download = `FlowSense_Analytics_${timestamp}.csv`;
            element.style.display = 'none';
            
            // Trigger download
            document.body.appendChild(element);
            element.click();
            document.body.removeChild(element);
            
            this.showToast('Success', 'Data exported successfully', 'success');
            
        } catch (error) {
            console.error('Export error:', error);
            this.showToast('Error', 'Failed to export data: ' + error.message, 'error');
        }
    }

    // Helper method to convert JSON to CSV
    convertToCSV(data) {
        if (!data || data.length === 0) {
            return '';
        }
        
        const headers = Object.keys(data[0]);
        const csvHeaders = headers.join(',');
        
        const csvRows = data.map(row => 
            headers.map(header => {
                let value = row[header] || '';
                // Escape quotes and wrap in quotes if contains comma or quote
                if (typeof value === 'string' && (value.includes(',') || value.includes('"') || value.includes('\n'))) {
                    value = '"' + value.replace(/"/g, '""') + '"';
                }
                return value;
            }).join(',')
        );
        
        return [csvHeaders, ...csvRows].join('\n');
    }
}