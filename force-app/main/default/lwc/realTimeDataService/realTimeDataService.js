import { LightningElement, api, track } from 'lwc';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RealTimeDataService extends LightningElement {
    @api sourceType = 'flows';
    @api updateInterval = 5000; // 5 seconds
    @api enableRealTime = false;
    @api maxDataPoints = 100;

    @track realtimeData = [];
    @track connectionStatus = 'disconnected';
    @track lastUpdate = null;
    @track isLoading = false;
    @track error = null;

    // Platform event channels
    channelName = '/event/FlowSense_Data_Update__e';
    subscription = {};
    
    // Polling interval
    pollingInterval = null;

    // WebSocket connection (future enhancement)
    websocketUrl = null;
    websocket = null;

    connectedCallback() {
        this.initializeRealTimeConnection();
        this.startDataPolling();
        
        // Set up error handling
        onError(error => {
            this.handleConnectionError(error);
        });
    }

    disconnectedCallback() {
        this.cleanup();
    }

    // ===== Real-time Connection Management =====
    initializeRealTimeConnection() {
        if (this.enableRealTime && isEmpEnabled) {
            this.subscribeToDataUpdates();
        } else {
            console.log('Real-time updates not enabled or EMP API not available');
        }
    }

    subscribeToDataUpdates() {
        this.connectionStatus = 'connecting';
        
        const messageCallback = (response) => {
            this.handleRealTimeUpdate(response.data.payload);
        };

        subscribe(this.channelName, -1, messageCallback).then(response => {
            this.subscription = response;
            this.connectionStatus = 'connected';
            this.lastUpdate = new Date().toISOString();
            console.log('Successfully subscribed to real-time data updates');
            
            this.dispatchConnectionEvent('connected');
        }).catch(error => {
            this.connectionStatus = 'error';
            this.error = 'Failed to subscribe to real-time updates: ' + error.message;
            console.error('Real-time subscription error:', error);
            
            this.dispatchConnectionEvent('error', error);
        });
    }

    unsubscribeFromDataUpdates() {
        if (this.subscription) {
            unsubscribe(this.subscription, response => {
                this.connectionStatus = 'disconnected';
                console.log('Unsubscribed from real-time data updates');
                
                this.dispatchConnectionEvent('disconnected');
            });
        }
    }

    // ===== Data Polling =====
    startDataPolling() {
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
        }

        this.pollingInterval = setInterval(() => {
            this.fetchLatestData();
        }, this.updateInterval);

        // Initial data fetch
        this.fetchLatestData();
    }

    stopDataPolling() {
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
            this.pollingInterval = null;
        }
    }

    async fetchLatestData() {
        if (this.isLoading) return; // Prevent overlapping requests

        this.isLoading = true;
        this.error = null;

        try {
            // Simulate API call - replace with actual Apex method call
            const newData = await this.simulateDataFetch();
            this.updateRealtimeData(newData);
            this.lastUpdate = new Date().toISOString();
            
            this.dispatchDataEvent('dataupdate', newData);
        } catch (error) {
            this.error = error.message;
            this.dispatchDataEvent('error', { error: error.message });
        } finally {
            this.isLoading = false;
        }
    }

    async simulateDataFetch() {
        // Simulate network delay
        await new Promise(resolve => setTimeout(resolve, Math.random() * 500 + 200));

        // Generate sample real-time data based on data source
        const timestamp = new Date().toISOString();
        const baseData = {
            timestamp,
            source: this.sourceType
        };

        switch (this.sourceType) {
            case 'flows':
                return {
                    ...baseData,
                    data: {
                        totalExecutions: Math.floor(Math.random() * 1000) + 5000,
                        activeFlows: Math.floor(Math.random() * 50) + 100,
                        averagePerformance: Math.floor(Math.random() * 30) + 70,
                        newExecutions: Math.floor(Math.random() * 20) + 5
                    }
                };
                
            case 'performance':
                return {
                    ...baseData,
                    data: {
                        cpuUsage: Math.random() * 100,
                        memoryUsage: Math.random() * 100,
                        responseTime: Math.random() * 2000 + 500,
                        throughput: Math.floor(Math.random() * 100) + 200
                    }
                };
                
            case 'notifications':
                return {
                    ...baseData,
                    data: {
                        newAlerts: Math.floor(Math.random() * 5),
                        criticalAlerts: Math.floor(Math.random() * 2),
                        totalUnread: Math.floor(Math.random() * 20) + 5
                    }
                };
                
            default:
                return {
                    ...baseData,
                    data: {
                        value: Math.random() * 100,
                        trend: Math.random() > 0.5 ? 'up' : 'down',
                        change: (Math.random() * 10 - 5).toFixed(2)
                    }
                };
        }
    }

    // ===== Real-time Event Handling =====
    handleRealTimeUpdate(payload) {
        try {
            const updateData = {
                timestamp: payload.CreatedDate || new Date().toISOString(),
                source: payload.Data_Source__c || this.sourceType,
                data: JSON.parse(payload.Data__c || '{}'),
                eventType: payload.Event_Type__c || 'update'
            };

            this.updateRealtimeData(updateData);
            this.lastUpdate = updateData.timestamp;
            
            this.dispatchDataEvent('realtimeupdate', updateData);
            
            // Show notification for critical updates
            if (payload.Priority__c === 'Critical') {
                this.showCriticalUpdateNotification(updateData);
            }
            
        } catch (error) {
            console.error('Error processing real-time update:', error);
            this.error = 'Failed to process real-time update';
        }
    }

    handleConnectionError(error) {
        this.connectionStatus = 'error';
        this.error = 'Real-time connection error: ' + error.message;
        
        // Attempt to reconnect after delay
        setTimeout(() => {
            if (this.enableRealTime) {
                this.initializeRealTimeConnection();
            }
        }, 5000);
    }

    // ===== Data Management =====
    updateRealtimeData(newData) {
        // Add new data point
        this.realtimeData = [newData, ...this.realtimeData];
        
        // Trim to max data points
        if (this.realtimeData.length > this.maxDataPoints) {
            this.realtimeData = this.realtimeData.slice(0, this.maxDataPoints);
        }

        // Update aggregated metrics
        this.updateAggregatedMetrics();
    }

    updateAggregatedMetrics() {
        if (this.realtimeData.length === 0) return;

        // Calculate trending metrics from recent data
        const recentData = this.realtimeData.slice(0, 10); // Last 10 data points
        const metrics = {
            lastUpdate: this.lastUpdate,
            dataPoints: this.realtimeData.length,
            trend: this.calculateTrend(recentData),
            averageValue: this.calculateAverage(recentData),
            changeRate: this.calculateChangeRate(recentData)
        };

        this.dispatchDataEvent('metricsupdate', metrics);
    }

    calculateTrend(data) {
        if (data.length < 2) return 'stable';
        
        const first = this.extractNumericValue(data[data.length - 1]);
        const last = this.extractNumericValue(data[0]);
        
        const change = ((last - first) / first) * 100;
        
        if (change > 5) return 'increasing';
        if (change < -5) return 'decreasing';
        return 'stable';
    }

    calculateAverage(data) {
        if (data.length === 0) return 0;
        
        const values = data.map(item => this.extractNumericValue(item));
        return values.reduce((sum, val) => sum + val, 0) / values.length;
    }

    calculateChangeRate(data) {
        if (data.length < 2) return 0;
        
        const current = this.extractNumericValue(data[0]);
        const previous = this.extractNumericValue(data[1]);
        
        return previous !== 0 ? ((current - previous) / previous) * 100 : 0;
    }

    extractNumericValue(dataPoint) {
        // Extract a primary numeric value from data point for calculations
        if (dataPoint.data) {
            const data = dataPoint.data;
            
            // Try to find the most relevant numeric value
            if (typeof data.value === 'number') return data.value;
            if (typeof data.averagePerformance === 'number') return data.averagePerformance;
            if (typeof data.totalExecutions === 'number') return data.totalExecutions;
            if (typeof data.cpuUsage === 'number') return data.cpuUsage;
            if (typeof data.responseTime === 'number') return data.responseTime;
            
            // Get first numeric property
            const numericProps = Object.values(data).filter(val => typeof val === 'number');
            return numericProps.length > 0 ? numericProps[0] : 0;
        }
        
        return 0;
    }

    // ===== Event Dispatching =====
    dispatchDataEvent(eventType, data) {
        this.dispatchEvent(new CustomEvent(eventType, {
            detail: {
                timestamp: new Date().toISOString(),
                source: this.sourceType,
                data,
                connectionStatus: this.connectionStatus
            }
        }));
    }

    dispatchConnectionEvent(status, error = null) {
        this.dispatchEvent(new CustomEvent('connectionchange', {
            detail: {
                status,
                error,
                timestamp: new Date().toISOString(),
                sourceType: this.sourceType
            }
        }));
    }

    // ===== Notifications =====
    showCriticalUpdateNotification(updateData) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Critical Data Update',
                message: `${updateData.source} data has been updated with critical changes`,
                variant: 'warning',
                mode: 'sticky'
            })
        );
    }

    // ===== Public Methods =====
    @api
    refreshData() {
        this.fetchLatestData();
    }

    @api
    clearData() {
        this.realtimeData = [];
        this.dispatchDataEvent('dataclear', {});
    }

    @api
    toggleRealTime(enabled) {
        this.enableRealTime = enabled;
        
        if (enabled) {
            this.initializeRealTimeConnection();
        } else {
            this.unsubscribeFromDataUpdates();
        }
    }

    @api
    getLatestData() {
        return this.realtimeData.length > 0 ? this.realtimeData[0] : null;
    }

    @api
    getHistoricalData(count = 10) {
        return this.realtimeData.slice(0, count);
    }

    // ===== Cleanup =====
    cleanup() {
        this.stopDataPolling();
        this.unsubscribeFromDataUpdates();
        
        if (this.websocket) {
            this.websocket.close();
        }
    }

    // ===== Getters =====
    get isConnected() {
        return this.connectionStatus === 'connected';
    }

    get hasData() {
        return this.realtimeData.length > 0;
    }

    get latestDataPoint() {
        return this.hasData ? this.realtimeData[0] : null;
    }

    get formattedLastUpdate() {
        if (!this.lastUpdate) return 'Never';
        
        const updateTime = new Date(this.lastUpdate);
        const now = new Date();
        const diffMs = now - updateTime;
        const diffSeconds = Math.floor(diffMs / 1000);
        
        if (diffSeconds < 60) return `${diffSeconds}s ago`;
        if (diffSeconds < 3600) return `${Math.floor(diffSeconds / 60)}m ago`;
        return updateTime.toLocaleTimeString();
    }
}