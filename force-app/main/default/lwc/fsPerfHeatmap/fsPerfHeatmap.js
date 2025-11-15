import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getFlowPerformanceData from '@salesforce/apex/FS_FlowStepSelector.getFlowPerformanceData';
import getFlowTrendData from '@salesforce/apex/FS_FlowStepSelector.getFlowTrendData';
import { loadScript } from 'lightning/platformResourceLoader';
import chartjs from '@salesforce/resourceUrl/chartjs';

export default class FsPerfHeatmap extends LightningElement {
    @api height = '600px';
    @api timeRange = '7';
    @api flowType = 'all';

    @track selectedTimeRange = '7';
    @track selectedFlowType = 'all';
    @track selectedMetric = 'duration';
    @track searchTerm = '';
    @track selectedFlow = null;
    @track isLoading = true;

    // Performance overview metrics
    @track criticalFlows = 0;
    @track warningFlows = 0;
    @track healthyFlows = 0;
    @track averagePerformance = 0;

    // Chart instances
    heatmapChart = null;
    trendChart = null;
    chartjsInitialized = false;

    // Options for filters
    timeRangeOptions = [
        { label: 'Last 24 Hours', value: '1' },
        { label: 'Last 7 Days', value: '7' },
        { label: 'Last 30 Days', value: '30' },
        { label: 'Last 90 Days', value: '90' }
    ];

    flowTypeOptions = [
        { label: 'All Flows', value: 'all' },
        { label: 'Screen Flows', value: 'screen' },
        { label: 'Autolaunched', value: 'autolaunched' },
        { label: 'Platform Events', value: 'platform_event' },
        { label: 'Record Triggered', value: 'record_triggered' }
    ];

    metricOptions = [
        { label: 'Duration', value: 'duration' },
        { label: 'CPU Time', value: 'cpu_time' },
        { label: 'DML Operations', value: 'dml_statements' },
        { label: 'SOQL Queries', value: 'soql_queries' },
        { label: 'Heap Size', value: 'heap_size' }
    ];

    // Wired method to get performance data
    @wire(getFlowPerformanceData, {
        days: '$selectedTimeRange',
        flowType: '$selectedFlowType',
        searchTerm: '$searchTerm'
    })
    wiredPerformanceData({ error, data }) {
        if (data) {
            this.processPerformanceData(data);
            this.isLoading = false;
        } else if (error) {
            this.showError('Error loading performance data: ' + error.body.message);
            this.isLoading = false;
        }
    }

    get containerStyle() {
        return `height: ${this.height}`;
    }

    connectedCallback() {
        this.loadChartJS();
    }

    disconnectedCallback() {
        // Clean up chart instances
        if (this.heatmapChart) {
            this.heatmapChart.destroy();
        }
        if (this.trendChart) {
            this.trendChart.destroy();
        }
    }

    async loadChartJS() {
        try {
            await loadScript(this, chartjs);
            this.chartjsInitialized = true;
            // Initialize heatmap after Chart.js is loaded
            this.initializeHeatmap();
        } catch (error) {
            this.showError('Error loading Chart.js: ' + error.message);
        }
    }

    processPerformanceData(data) {
        // Update overview metrics
        this.criticalFlows = data.criticalFlows || 0;
        this.warningFlows = data.warningFlows || 0;
        this.healthyFlows = data.healthyFlows || 0;
        this.averagePerformance = data.averagePerformance || 0;

        // Process heatmap data
        this.flowPerformanceData = data.flowData || [];
        
        if (this.chartjsInitialized) {
            this.renderHeatmap();
        }
    }

    initializeHeatmap() {
        if (!this.chartjsInitialized) return;

        const heatmapContainer = this.template.querySelector('.heatmap-grid');
        if (!heatmapContainer) return;

        // Create heatmap visualization using D3-like approach
        this.createHeatmapGrid(heatmapContainer);
    }

    createHeatmapGrid(container) {
        // Clear existing content
        container.innerHTML = '';

        if (!this.flowPerformanceData || this.flowPerformanceData.length === 0) {
            container.innerHTML = '<div class="no-data">No performance data available</div>';
            return;
        }

        // Create grid layout
        const gridSize = Math.ceil(Math.sqrt(this.flowPerformanceData.length));
        container.style.display = 'grid';
        container.style.gridTemplateColumns = `repeat(${gridSize}, 1fr)`;
        container.style.gap = '2px';

        this.flowPerformanceData.forEach(flow => {
            const cell = document.createElement('div');
            cell.className = 'heatmap-cell';
            cell.title = `${flow.FlowName}\nDuration: ${flow.AverageDuration}ms\nRuns: ${flow.TotalRuns}`;
            
            // Set color based on performance
            const performanceClass = this.getPerformanceClass(flow.AverageDuration);
            cell.classList.add(performanceClass);
            
            // Add flow name
            const label = document.createElement('div');
            label.className = 'cell-label';
            label.textContent = flow.FlowName.substring(0, 10) + (flow.FlowName.length > 10 ? '...' : '');
            cell.appendChild(label);

            // Add performance indicator
            const indicator = document.createElement('div');
            indicator.className = 'performance-indicator';
            indicator.textContent = `${flow.AverageDuration}ms`;
            cell.appendChild(indicator);

            // Add click handler
            cell.addEventListener('click', () => {
                this.selectFlow(flow);
            });

            container.appendChild(cell);
        });
    }

    getPerformanceClass(duration) {
        if (duration < 1000) return 'color-excellent';
        if (duration < 3000) return 'color-good';
        if (duration < 10000) return 'color-fair';
        if (duration < 30000) return 'color-poor';
        return 'color-critical';
    }

    selectFlow(flow) {
        this.selectedFlow = flow;
        this.loadTrendData(flow.Id);
    }

    async loadTrendData(flowId) {
        try {
            const trendData = await getFlowTrendData({ flowId, days: 30 });
            this.renderTrendChart(trendData);
        } catch (error) {
            this.showError('Error loading trend data: ' + error.message);
        }
    }

    renderTrendChart(trendData) {
        const chartContainer = this.template.querySelector('.trend-chart');
        if (!chartContainer || !this.chartjsInitialized) return;

        // Destroy existing chart
        if (this.trendChart) {
            this.trendChart.destroy();
        }

        const canvas = document.createElement('canvas');
        canvas.width = 400;
        canvas.height = 200;
        chartContainer.innerHTML = '';
        chartContainer.appendChild(canvas);

        const ctx = canvas.getContext('2d');
        
        this.trendChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: trendData.map(point => point.date),
                datasets: [{
                    label: 'Average Duration (ms)',
                    data: trendData.map(point => point.averageDuration),
                    borderColor: '#0176d3',
                    backgroundColor: 'rgba(1, 118, 211, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Duration (ms)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Date'
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: false
                    }
                }
            }
        });
    }

    // Event handlers
    handleTimeRangeChange(event) {
        this.selectedTimeRange = event.detail.value;
    }

    handleFlowTypeChange(event) {
        this.selectedFlowType = event.detail.value;
    }

    handleMetricChange(event) {
        this.selectedMetric = event.detail.value;
        // Re-render heatmap with new metric
        this.renderHeatmap();
    }

    handleSearchChange(event) {
        // Debounce search
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.searchTerm = event.target.value;
        }, 500);
    }

    closeDetails() {
        this.selectedFlow = null;
    }

    refreshData() {
        this.isLoading = true;
        return refreshApex(this.wiredPerformanceData);
    }

    exportData() {
        // Export performance data as CSV
        if (!this.flowPerformanceData || this.flowPerformanceData.length === 0) {
            this.showWarning('No data to export');
            return;
        }

        const csv = this.convertToCSV(this.flowPerformanceData);
        const blob = new Blob([csv], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `flow-performance-${new Date().toISOString().split('T')[0]}.csv`;
        link.click();
        window.URL.revokeObjectURL(url);
    }

    convertToCSV(data) {
        const headers = ['Flow Name', 'Average Duration (ms)', 'Total Runs', 'Error Rate (%)', 'CPU Time (ms)', 'DML Statements', 'SOQL Queries', 'Heap Size (KB)'];
        const rows = data.map(flow => [
            flow.FlowName,
            flow.AverageDuration,
            flow.TotalRuns,
            flow.ErrorRate,
            flow.AverageCpuTime,
            flow.AverageDmlStatements,
            flow.AverageSoqlQueries,
            flow.AverageHeapSize
        ]);

        return [headers, ...rows].map(row => row.map(field => `"${field}"`).join(',')).join('\n');
    }

    // Utility methods
    showError(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        }));
    }

    showWarning(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Warning',
            message: message,
            variant: 'warning'
        }));
    }

    showSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        }));
    }
}