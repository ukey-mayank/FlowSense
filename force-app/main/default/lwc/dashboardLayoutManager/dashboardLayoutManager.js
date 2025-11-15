import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DashboardLayoutManager extends LightningElement {
    @api layoutId;
    @api enableDragDrop = false;
    @api enableCustomization = false;
    
    @track widgets = [];
    @track availableWidgets = [];
    @track layoutConfig = {};
    @track isEditMode = false;
    @track draggedWidget = null;
    @track dropZoneActive = false;

    // Layout configuration options
    layoutOptions = [
        { label: '2 Columns', value: '2-col', columns: 2 },
        { label: '3 Columns', value: '3-col', columns: 3 },
        { label: '4 Columns', value: '4-col', columns: 4 },
        { label: 'Grid Layout', value: 'grid', columns: 'auto' },
        { label: 'Masonry', value: 'masonry', columns: 'masonry' }
    ];

    // Available widget types
    widgetTypes = [
        {
            type: 'chart',
            label: 'Performance Chart',
            icon: 'utility:chart',
            component: 'c-performance-chart',
            defaultConfig: {
                title: 'Flow Performance',
                chartType: 'line',
                height: '300px',
                dataSource: 'flows'
            }
        },
        {
            type: 'notifications',
            label: 'Smart Notifications',
            icon: 'utility:notification',
            component: 'c-smart-notifications',
            defaultConfig: {
                height: '400px',
                maxNotifications: 10
            }
        },
        {
            type: 'metrics',
            label: 'Key Metrics',
            icon: 'utility:metrics',
            component: 'c-metrics-widget',
            defaultConfig: {
                metrics: ['executions', 'performance', 'risk'],
                layout: 'horizontal'
            }
        },
        {
            type: 'recent-flows',
            label: 'Recent Flows',
            icon: 'utility:flow',
            component: 'c-recent-flows-widget',
            defaultConfig: {
                maxItems: 5,
                showThumbnails: true
            }
        },
        {
            type: 'quick-actions',
            label: 'Quick Actions',
            icon: 'utility:apps',
            component: 'c-quick-actions-widget',
            defaultConfig: {
                actions: ['create-flow', 'run-analysis', 'view-reports'],
                layout: 'grid'
            }
        }
    ];

    connectedCallback() {
        this.loadLayoutConfiguration();
        this.initializeWidgets();
        this.loadAvailableWidgets();
    }

    // ===== Layout Management =====
    loadLayoutConfiguration() {
        const savedConfig = localStorage.getItem(`flowsense_layout_${this.layoutId || 'default'}`);
        if (savedConfig) {
            this.layoutConfig = JSON.parse(savedConfig);
        } else {
            this.layoutConfig = {
                type: '3-col',
                columns: 3,
                widgets: this.getDefaultWidgets()
            };
        }
    }

    saveLayoutConfiguration() {
        localStorage.setItem(
            `flowsense_layout_${this.layoutId || 'default'}`, 
            JSON.stringify(this.layoutConfig)
        );
        
        this.showToast('Success', 'Layout saved successfully', 'success');
    }

    getDefaultWidgets() {
        return [
            {
                id: 'widget-1',
                type: 'metrics',
                column: 1,
                order: 1,
                config: this.widgetTypes.find(w => w.type === 'metrics').defaultConfig
            },
            {
                id: 'widget-2',
                type: 'chart',
                column: 2,
                order: 1,
                config: { 
                    ...this.widgetTypes.find(w => w.type === 'chart').defaultConfig,
                    title: 'Execution Trends'
                }
            },
            {
                id: 'widget-3',
                type: 'notifications',
                column: 3,
                order: 1,
                config: this.widgetTypes.find(w => w.type === 'notifications').defaultConfig
            }
        ];
    }

    // ===== Widget Management =====
    initializeWidgets() {
        this.widgets = this.layoutConfig.widgets || this.getDefaultWidgets();
        this.sortWidgetsByColumn();
    }

    loadAvailableWidgets() {
        this.availableWidgets = this.widgetTypes.map(widget => ({
            ...widget,
            isAvailable: true,
            id: this.generateWidgetId()
        }));
    }

    addWidget(widgetType) {
        const widgetConfig = this.widgetTypes.find(w => w.type === widgetType);
        if (!widgetConfig) return;

        const newWidget = {
            id: this.generateWidgetId(),
            type: widgetType,
            column: 1, // Default to first column
            order: this.getNextOrderForColumn(1),
            config: { ...widgetConfig.defaultConfig }
        };

        this.widgets = [...this.widgets, newWidget];
        this.sortWidgetsByColumn();
        this.saveLayoutConfiguration();
    }

    removeWidget(widgetId) {
        this.widgets = this.widgets.filter(widget => widget.id !== widgetId);
        this.reorderWidgets();
        this.saveLayoutConfiguration();
    }

    duplicateWidget(widgetId) {
        const widget = this.widgets.find(w => w.id === widgetId);
        if (!widget) return;

        const duplicatedWidget = {
            ...widget,
            id: this.generateWidgetId(),
            order: this.getNextOrderForColumn(widget.column)
        };

        this.widgets = [...this.widgets, duplicatedWidget];
        this.sortWidgetsByColumn();
        this.saveLayoutConfiguration();
    }

    // ===== Drag and Drop =====
    handleDragStart(event) {
        if (!this.enableDragDrop || !this.isEditMode) return;

        const widgetId = event.target.dataset.widgetId;
        this.draggedWidget = this.widgets.find(w => w.id === widgetId);
        
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', widgetId);
        
        // Add visual feedback
        event.target.classList.add('dragging');
    }

    handleDragEnd(event) {
        event.target.classList.remove('dragging');
        this.draggedWidget = null;
        this.dropZoneActive = false;
    }

    handleDragOver(event) {
        if (!this.enableDragDrop || !this.isEditMode) return;
        
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
        this.dropZoneActive = true;
    }

    handleDragLeave(event) {
        // Only remove drop zone highlight if leaving the container
        if (!event.currentTarget.contains(event.relatedTarget)) {
            this.dropZoneActive = false;
        }
    }

    handleDrop(event) {
        if (!this.enableDragDrop || !this.isEditMode) return;

        event.preventDefault();
        this.dropZoneActive = false;

        const widgetId = event.dataTransfer.getData('text/plain');
        const dropZone = event.currentTarget;
        const targetColumn = parseInt(dropZone.dataset.column);
        const targetOrder = parseInt(dropZone.dataset.order || '1');

        this.moveWidget(widgetId, targetColumn, targetOrder);
    }

    moveWidget(widgetId, targetColumn, targetOrder) {
        const widgetIndex = this.widgets.findIndex(w => w.id === widgetId);
        if (widgetIndex === -1) return;

        // Update widget position
        const updatedWidgets = [...this.widgets];
        updatedWidgets[widgetIndex] = {
            ...updatedWidgets[widgetIndex],
            column: targetColumn,
            order: targetOrder
        };

        // Reorder other widgets in the target column
        updatedWidgets.forEach((widget, index) => {
            if (widget.column === targetColumn && widget.id !== widgetId && widget.order >= targetOrder) {
                updatedWidgets[index] = {
                    ...widget,
                    order: widget.order + 1
                };
            }
        });

        this.widgets = updatedWidgets;
        this.reorderWidgets();
        this.saveLayoutConfiguration();
    }

    // ===== Layout Utilities =====
    sortWidgetsByColumn() {
        this.widgets.sort((a, b) => {
            if (a.column !== b.column) return a.column - b.column;
            return a.order - b.order;
        });
    }

    reorderWidgets() {
        // Reorganize widgets to eliminate gaps in ordering
        const columnGroups = {};
        
        this.widgets.forEach(widget => {
            if (!columnGroups[widget.column]) {
                columnGroups[widget.column] = [];
            }
            columnGroups[widget.column].push(widget);
        });

        Object.keys(columnGroups).forEach(column => {
            columnGroups[column]
                .sort((a, b) => a.order - b.order)
                .forEach((widget, index) => {
                    widget.order = index + 1;
                });
        });

        this.layoutConfig.widgets = this.widgets;
    }

    getNextOrderForColumn(column) {
        const columnWidgets = this.widgets.filter(w => w.column === column);
        return columnWidgets.length > 0 
            ? Math.max(...columnWidgets.map(w => w.order)) + 1 
            : 1;
    }

    generateWidgetId() {
        return 'widget-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
    }

    // ===== Event Handlers =====
    handleEditModeToggle() {
        this.isEditMode = !this.isEditMode;
        
        if (this.isEditMode) {
            this.showToast('Info', 'Edit mode enabled. Drag widgets to rearrange.', 'info');
        }
    }

    handleLayoutChange(event) {
        const newLayoutType = event.detail.value;
        const layoutOption = this.layoutOptions.find(opt => opt.value === newLayoutType);
        
        this.layoutConfig.type = newLayoutType;
        this.layoutConfig.columns = layoutOption.columns;
        
        this.redistributeWidgets();
        this.saveLayoutConfiguration();
    }

    redistributeWidgets() {
        if (typeof this.layoutConfig.columns === 'number') {
            // Redistribute widgets across available columns
            this.widgets.forEach((widget, index) => {
                widget.column = (index % this.layoutConfig.columns) + 1;
            });
            this.reorderWidgets();
        }
    }

    handleWidgetAdd(event) {
        const widgetType = event.detail.type;
        this.addWidget(widgetType);
    }

    handleWidgetRemove(event) {
        const widgetId = event.currentTarget.dataset.widgetId;
        this.removeWidget(widgetId);
    }

    handleWidgetDuplicate(event) {
        const widgetId = event.currentTarget.dataset.widgetId;
        this.duplicateWidget(widgetId);
    }

    handleWidgetConfigure(event) {
        const widgetId = event.currentTarget.dataset.widgetId;
        // Open widget configuration modal
        this.openWidgetConfiguration(widgetId);
    }

    handleSaveLayout() {
        this.saveLayoutConfiguration();
    }

    handleResetLayout() {
        this.layoutConfig.widgets = this.getDefaultWidgets();
        this.widgets = [...this.layoutConfig.widgets];
        this.saveLayoutConfiguration();
        this.showToast('Success', 'Layout reset to default', 'success');
    }

    // ===== Widget Configuration =====
    openWidgetConfiguration(widgetId) {
        // Implementation for widget configuration modal
        const widget = this.widgets.find(w => w.id === widgetId);
        if (widget) {
            // Dispatch event to parent or open configuration modal
            this.dispatchEvent(new CustomEvent('widgetconfigure', {
                detail: { widget }
            }));
        }
    }

    // ===== Utility Methods =====
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    // ===== Getters =====
    get layoutClass() {
        const baseClass = 'dashboard-layout';
        const layoutClass = `layout-${this.layoutConfig.type}`;
        const editClass = this.isEditMode ? 'edit-mode' : '';
        const dragClass = this.dropZoneActive ? 'drop-zone-active' : '';
        
        return [baseClass, layoutClass, editClass, dragClass].filter(Boolean).join(' ');
    }

    get columnCount() {
        return typeof this.layoutConfig.columns === 'number' 
            ? this.layoutConfig.columns 
            : 3;
    }

    get columnStyle() {
        if (this.layoutConfig.type === 'grid') {
            return 'grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));';
        } else if (typeof this.layoutConfig.columns === 'number') {
            return `grid-template-columns: repeat(${this.layoutConfig.columns}, 1fr);`;
        }
        return 'grid-template-columns: repeat(3, 1fr);';
    }

    get widgetsByColumn() {
        const columns = {};
        for (let i = 1; i <= this.columnCount; i++) {
            columns[i] = this.widgets
                .filter(widget => widget.column === i)
                .sort((a, b) => a.order - b.order);
        }
        return columns;
    }

    get hasWidgets() {
        return this.widgets && this.widgets.length > 0;
    }

    get editButtonLabel() {
        return this.isEditMode ? 'Exit Edit Mode' : 'Edit Layout';
    }

    get editButtonVariant() {
        return this.isEditMode ? 'neutral' : 'brand';
    }

    get editButtonIcon() {
        return this.isEditMode ? 'utility:close' : 'utility:edit';
    }

    get emptyStateMessage() {
        return this.enableCustomization 
            ? 'Start customizing your dashboard by adding widgets.' 
            : 'No widgets configured for this dashboard.';
    }

    get columnArray() {
        const columns = [];
        for (let i = 1; i <= this.columnCount; i++) {
            columns.push(i);
        }
        return columns;
    }

    get isDraggable() {
        return this.enableDragDrop && this.isEditMode;
    }

    get showRealTimeStatus() {
        return true; // Can be configured based on real-time connection status
    }
}