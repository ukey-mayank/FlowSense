import { LightningElement, api, track, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CHART_JS from '@salesforce/resourceUrl/chartjs';

export default class PerformanceChart extends LightningElement {
    @api chartType = 'line';
    @api chartTitle = 'Performance Metrics';
    @api chartHeight = '400';
    @api data;
    @api showLegend = false;
    @api responsive = false;
    
    @track isChartJsLoaded = false;
    @track chartConfig;
    @track currentTheme = 'light';
    
    chart;
    
    connectedCallback() {
        // Load saved theme
        this.currentTheme = localStorage.getItem('flowsense-theme') || 'light';
        
        // Listen for theme changes
        document.addEventListener('themechange', this.handleThemeChange.bind(this));
    }
    
    get containerStyle() {
        return `height: ${this.chartHeight}px;`;
    }
    
    disconnectedCallback() {
        document.removeEventListener('themechange', this.handleThemeChange.bind(this));
        if (this.chart) {
            this.chart.destroy();
        }
    }
    
    renderedCallback() {
        if (!this.isChartJsLoaded) {
            Promise.all([
                loadScript(this, CHART_JS + '/Chart.min.js')
            ]).then(() => {
                this.isChartJsLoaded = true;
                this.initializeChart();
            }).catch(error => {
                console.error('Error loading Chart.js', error);
            });
        } else if (this.data && this.chart) {
            this.updateChart();
        }
    }
    
    handleThemeChange(event) {
        if (event.detail && event.detail.theme) {
            this.currentTheme = event.detail.theme;
            if (this.chart) {
                this.updateChartTheme();
            }
        }
    }
    
    initializeChart() {
        const canvas = this.template.querySelector('canvas');
        if (!canvas || !this.data) return;
        
        const ctx = canvas.getContext('2d');
        
        this.chartConfig = this.buildChartConfig();
        
        this.chart = new window.Chart(ctx, this.chartConfig);
    }
    
    buildChartConfig() {
        const themeColors = this.getThemeColors();
        
        return {
            type: this.chartType,
            data: this.formatChartData(),
            options: {
                responsive: this.responsive,
                maintainAspectRatio: false,
                plugins: {
                    title: {
                        display: !!this.chartTitle,
                        text: this.chartTitle,
                        color: themeColors.text,
                        font: {
                            family: 'Salesforce Sans, Arial, sans-serif',
                            size: 16,
                            weight: '600'
                        }
                    },
                    legend: {
                        display: this.showLegend,
                        labels: {
                            color: themeColors.text,
                            font: {
                                family: 'Salesforce Sans, Arial, sans-serif',
                                size: 12
                            }
                        }
                    },
                    tooltip: {
                        backgroundColor: themeColors.tooltipBg,
                        titleColor: themeColors.tooltipText,
                        bodyColor: themeColors.tooltipText,
                        borderColor: themeColors.border,
                        borderWidth: 1,
                        cornerRadius: 8,
                        displayColors: true,
                        font: {
                            family: 'Salesforce Sans, Arial, sans-serif'
                        }
                    }
                },
                scales: this.getScaleConfig(themeColors),
                elements: {
                    point: {
                        radius: 4,
                        hoverRadius: 6,
                        borderWidth: 2
                    },
                    line: {
                        borderWidth: 3,
                        tension: 0.4
                    }
                },
                interaction: {
                    intersect: false,
                    mode: 'index'
                },
                animation: {
                    duration: 800, // Moderate animation
                    easing: 'easeInOutQuart'
                }
            }
        };
    }
    
    formatChartData() {
        if (!this.data) return { datasets: [] };
        
        const themeColors = this.getThemeColors();
        
        // Handle different data formats
        if (this.data.datasets) {
            return {
                ...this.data,
                datasets: this.data.datasets.map((dataset, index) => ({
                    ...dataset,
                    backgroundColor: dataset.backgroundColor || this.getDatasetColors(index).background,
                    borderColor: dataset.borderColor || this.getDatasetColors(index).border,
                    pointBackgroundColor: dataset.pointBackgroundColor || this.getDatasetColors(index).point,
                    pointBorderColor: dataset.pointBorderColor || themeColors.background,
                    fill: dataset.fill !== undefined ? dataset.fill : false
                }))
            };
        }
        
        // Handle simple array data
        return {
            labels: this.data.labels || [],
            datasets: [{
                label: this.data.label || 'Performance',
                data: this.data.values || [],
                backgroundColor: this.getDatasetColors(0).background,
                borderColor: this.getDatasetColors(0).border,
                pointBackgroundColor: this.getDatasetColors(0).point,
                pointBorderColor: themeColors.background,
                fill: false
            }]
        };
    }
    
    getThemeColors() {
        const isDark = this.currentTheme === 'dark';
        const isCorporate = this.currentTheme === 'corporate';
        const isNature = this.currentTheme === 'nature';
        
        if (isDark) {
            return {
                text: '#ffffff',
                background: '#1a1a1a',
                border: '#404040',
                grid: '#404040',
                tooltipBg: '#2d2d2d',
                tooltipText: '#ffffff'
            };
        } else if (isCorporate) {
            return {
                text: '#212529',
                background: '#f8f9fa',
                border: '#dee2e6',
                grid: '#e9ecef',
                tooltipBg: '#ffffff',
                tooltipText: '#212529'
            };
        } else if (isNature) {
            return {
                text: '#1b5e20',
                background: '#f0f8f0',
                border: '#c8e6c9',
                grid: '#e8f5e8',
                tooltipBg: '#ffffff',
                tooltipText: '#1b5e20'
            };
        } else {
            return {
                text: '#181818',
                background: '#ffffff',
                border: '#e5e5e5',
                grid: '#f6f6f5',
                tooltipBg: '#ffffff',
                tooltipText: '#181818'
            };
        }
    }
    
    getDatasetColors(index) {
        const colors = [
            {
                background: 'rgba(1, 118, 211, 0.1)',
                border: '#0176d3',
                point: '#0176d3'
            },
            {
                background: 'rgba(4, 132, 75, 0.1)', 
                border: '#04844b',
                point: '#04844b'
            },
            {
                background: 'rgba(254, 147, 57, 0.1)',
                border: '#fe9339',
                point: '#fe9339'
            },
            {
                background: 'rgba(234, 0, 30, 0.1)',
                border: '#ea001e',
                point: '#ea001e'
            },
            {
                background: 'rgba(1, 68, 134, 0.1)',
                border: '#014486',
                point: '#014486'
            }
        ];
        
        return colors[index % colors.length];
    }
    
    getScaleConfig(themeColors) {
        const baseConfig = {
            x: {
                grid: {
                    color: themeColors.grid,
                    borderColor: themeColors.border
                },
                ticks: {
                    color: themeColors.text,
                    font: {
                        family: 'Salesforce Sans, Arial, sans-serif',
                        size: 11
                    }
                }
            },
            y: {
                grid: {
                    color: themeColors.grid,
                    borderColor: themeColors.border
                },
                ticks: {
                    color: themeColors.text,
                    font: {
                        family: 'Salesforce Sans, Arial, sans-serif',
                        size: 11
                    }
                }
            }
        };
        
        // Chart-specific configurations
        if (this.chartType === 'line' || this.chartType === 'bar') {
            baseConfig.y.beginAtZero = true;
        }
        
        return baseConfig;
    }
    
    updateChart() {
        if (this.chart) {
            this.chart.data = this.formatChartData();
            this.chart.update();
        }
    }
    
    updateChartTheme() {
        if (this.chart) {
            const themeColors = this.getThemeColors();
            
            // Update chart options
            this.chart.options.plugins.title.color = themeColors.text;
            this.chart.options.plugins.legend.labels.color = themeColors.text;
            this.chart.options.plugins.tooltip.backgroundColor = themeColors.tooltipBg;
            this.chart.options.plugins.tooltip.titleColor = themeColors.tooltipText;
            this.chart.options.plugins.tooltip.bodyColor = themeColors.tooltipText;
            this.chart.options.plugins.tooltip.borderColor = themeColors.border;
            
            // Update scales
            this.chart.options.scales = this.getScaleConfig(themeColors);
            
            // Update data colors
            this.chart.data = this.formatChartData();
            
            this.chart.update();
        }
    }
    
    @api
    updateData(newData) {
        this.data = newData;
        if (this.chart) {
            this.updateChart();
        }
    }
    
    @api
    addDataPoint(label, value, datasetIndex = 0) {
        if (this.chart && this.chart.data.labels && this.chart.data.datasets[datasetIndex]) {
            this.chart.data.labels.push(label);
            this.chart.data.datasets[datasetIndex].data.push(value);
            this.chart.update();
        }
    }
    
    @api
    removeDataPoint(index) {
        if (this.chart && this.chart.data.labels) {
            this.chart.data.labels.splice(index, 1);
            this.chart.data.datasets.forEach(dataset => {
                dataset.data.splice(index, 1);
            });
            this.chart.update();
        }
    }
    
    @api
    destroy() {
        if (this.chart) {
            this.chart.destroy();
            this.chart = null;
        }
    }
}