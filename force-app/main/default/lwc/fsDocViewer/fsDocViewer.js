import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getRecord } from 'lightning/uiRecordApi';
import getDemoDocuments from '@salesforce/apex/FS_SimpleDocumentService.getDemoDocuments';
import getDemoDocumentContent from '@salesforce/apex/FS_SimpleDocumentService.getDemoDocumentContent';

export default class FsDocViewer extends LightningElement {
    @api height = '600px';
    @api flowId;
    @api documentId;
    @api readOnly = false;

    @track selectedFlowId;
    @track selectedDocumentType = 'all';
    @track searchTerm = '';
    @track selectedDocument = null;
    @track documentContent = '';
    @track isEditMode = false;
    @track isLoading = false;
    @track hasUnsavedChanges = false;

    // Document list and filtering
    @track allDocuments = [];
    @track filteredDocuments = [];
    flowOptions = [];

    // Document types
    documentTypeOptions = [
        { label: 'All Types', value: 'all' },
        { label: 'Flow Documentation', value: 'flow_doc' },
        { label: 'Analysis Report', value: 'analysis_report' },
        { label: 'Performance Report', value: 'performance_report' },
        { label: 'Best Practices', value: 'best_practices' },
        { label: 'Troubleshooting Guide', value: 'troubleshooting' },
        { label: 'AI Insights', value: 'ai_insights' }
    ];

    // Wired method to get flow list (demo data)
    get flowOptionsList() {
        return [
            { label: 'All Flows', value: 'all' },
            { label: 'Demo Flow 1', value: 'demo1' },
            { label: 'Demo Flow 2', value: 'demo2' },
            { label: 'Demo Flow 3', value: 'demo3' }
        ];
    }

    // Wired method to get documents
    connectedCallback() {
        this.loadDemoDocuments();
    }

    async loadDemoDocuments() {
        try {
            const data = await getDemoDocuments();
            this.allDocuments = data.map(doc => ({
                ...doc,
                iconName: this.getDocumentIcon(doc.DocumentType),
                hasAttachments: false
            }));
            this.filterDocuments();
        } catch (error) {
            this.showError('Error loading documents: ' + error.message);
        }
    }

    get containerStyle() {
        return `height: ${this.height}`;
    }

    get editButtonIcon() {
        return this.isEditMode ? 'utility:preview' : 'utility:edit';
    }

    get editButtonLabel() {
        return this.isEditMode ? 'Preview' : 'Edit';
    }

    get saveDisabled() {
        return !this.hasUnsavedChanges || this.isLoading || this.readOnly;
    }

    get noDocuments() {
        return this.filteredDocuments.length === 0 && !this.isLoading;
    }

    get aiAnalysisAvailable() {
        return this.selectedDocument && 
               this.selectedDocument.DocumentType === 'ai_insights' &&
               this.selectedDocument.aiAnalysis;
    }

    connectedCallback() {
        // Set initial flow ID if provided
        if (this.flowId) {
            this.selectedFlowId = this.flowId;
        }

        // Load specific document if ID provided
        if (this.documentId) {
            this.loadDocument(this.documentId);
        }

        // Set edit mode based on readOnly prop
        if (this.readOnly) {
            this.isEditMode = false;
        }

        // Load demo documents and flow options
        this.loadDemoDocuments();
        this.flowOptions = this.flowOptionsList;
    }

    // Event handlers
    handleFlowChange(event) {
        this.selectedFlowId = event.detail.value === 'all' ? null : event.detail.value;
        this.selectedDocument = null; // Clear selection when flow changes
    }

    handleDocumentTypeChange(event) {
        this.selectedDocumentType = event.detail.value;
    }

    handleSearchChange(event) {
        // Debounce search
        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.searchTerm = event.target.value;
        }, 500);
    }

    handleDocumentSelect(event) {
        const docId = event.currentTarget.dataset.docId;
        this.loadDocument(docId);
    }

    handlePreview(event) {
        event.stopPropagation();
        const docId = event.currentTarget.dataset.docId;
        this.loadDocument(docId, true); // Force preview mode
    }

    handleDownload(event) {
        event.stopPropagation();
        const docId = event.currentTarget.dataset.docId;
        this.downloadDocument(docId);
    }

    handleTitleChange(event) {
        this.selectedDocument = {
            ...this.selectedDocument,
            Title: event.target.value
        };
        this.hasUnsavedChanges = true;
    }

    handleContentChange(event) {
        this.documentContent = event.target.value;
        this.hasUnsavedChanges = true;
    }

    // Document operations
    async loadDocument(docId, previewMode = false) {
        this.isLoading = true;
        try {
            const docData = await getDemoDocumentContent({ documentId: docId });
            this.selectedDocument = {
                ...docData,
                Id: docId,
                LastModifiedDate: this.formatDate(new Date()),
                hasAttachments: false
            };
            this.documentContent = docData.Content || '';
            this.isEditMode = previewMode ? false : !this.readOnly;
            this.hasUnsavedChanges = false;
            
            // Render content
            this.renderDocumentContent();
            
            // Load AI analysis if available
            if (this.aiAnalysisAvailable) {
                this.renderAIAnalysis();
            }
        } catch (error) {
            this.showError('Error loading document: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }

    async saveDocument() {
        if (!this.hasUnsavedChanges) return;

        this.isLoading = true;
        try {
            // For demo purposes, just simulate saving
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            this.hasUnsavedChanges = false;
            this.showSuccess('Document saved successfully (demo mode)');
        } catch (error) {
            this.showError('Error saving document: ' + error.message);
        } finally {
            this.isLoading = false;
        }
    }

    async createNewDocument() {
        try {
            // For demo purposes, just simulate creation
            this.selectedDocument = {
                Id: 'demo_new',
                Title: 'New Document',
                DocumentType: 'flow_doc',
                FlowName: 'New Flow',
                hasAttachments: false,
                LastModifiedDate: this.formatDate(new Date())
            };
            this.documentContent = '# New Document\n\nStart writing your documentation here...';
            this.isEditMode = true;
            this.hasUnsavedChanges = true;
            
            this.showSuccess('New document created (demo mode)');
        } catch (error) {
            this.showError('Error creating document: ' + error.message);
        }
    }

    toggleEditMode() {
        if (this.readOnly) return;
        
        if (this.hasUnsavedChanges && this.isEditMode) {
            // Ask user to save or discard changes
            if (confirm('You have unsaved changes. Save before switching to preview?')) {
                this.saveDocument().then(() => {
                    this.isEditMode = !this.isEditMode;
                    this.renderDocumentContent();
                });
                return;
            }
        }
        
        this.isEditMode = !this.isEditMode;
        if (!this.isEditMode) {
            this.renderDocumentContent();
        }
    }

    exportDocument() {
        if (!this.selectedDocument) return;

        const content = this.documentContent;
        const blob = new Blob([content], { type: 'text/plain' });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = url;
        link.download = `${this.selectedDocument.Title}.md`;
        link.click();
        window.URL.revokeObjectURL(url);
    }

    downloadDocument(docId) {
        const doc = this.allDocuments.find(d => d.Id === docId);
        if (!doc) return;

        // Implementation depends on your document storage strategy
        this.showInfo('Download feature will be implemented based on your storage solution');
    }

    downloadAttachment(event) {
        const attachmentId = event.currentTarget.dataset.attachmentId;
        // Implementation depends on your attachment storage strategy
        this.showInfo('Attachment download feature will be implemented');
    }

    goBack() {
        this.selectedDocument = null;
        this.documentContent = '';
        this.isEditMode = false;
        this.hasUnsavedChanges = false;
    }

    // Content rendering
    renderDocumentContent() {
        const contentViewer = this.template.querySelector('.content-viewer');
        if (!contentViewer || this.isEditMode) return;

        // Basic markdown-to-HTML conversion
        let html = this.convertMarkdownToHtml(this.documentContent);
        contentViewer.innerHTML = html;
    }

    renderAIAnalysis() {
        const aiInsights = this.template.querySelector('.ai-insights');
        if (!aiInsights || !this.selectedDocument.aiAnalysis) return;

        // Render AI analysis results
        const analysis = this.selectedDocument.aiAnalysis;
        let html = '<div class="ai-analysis">';
        
        if (analysis.summary) {
            html += `<div class="analysis-section">
                <h4>Summary</h4>
                <p>${analysis.summary}</p>
            </div>`;
        }
        
        if (analysis.recommendations && analysis.recommendations.length > 0) {
            html += '<div class="analysis-section"><h4>Recommendations</h4><ul>';
            analysis.recommendations.forEach(rec => {
                html += `<li>${rec}</li>`;
            });
            html += '</ul></div>';
        }
        
        if (analysis.issues && analysis.issues.length > 0) {
            html += '<div class="analysis-section"><h4>Issues Detected</h4><ul class="issue-list">';
            analysis.issues.forEach(issue => {
                html += `<li class="issue-item ${issue.severity}">${issue.description}</li>`;
            });
            html += '</ul></div>';
        }
        
        html += '</div>';
        aiInsights.innerHTML = html;
    }

    // Utility methods
    convertMarkdownToHtml(markdown) {
        if (!markdown) return '';
        
        let html = markdown
            // Headers
            .replace(/^### (.*$)/gim, '<h3>$1</h3>')
            .replace(/^## (.*$)/gim, '<h2>$1</h2>')
            .replace(/^# (.*$)/gim, '<h1>$1</h1>')
            // Bold
            .replace(/\*\*(.*)\*\*/gim, '<strong>$1</strong>')
            // Italic
            .replace(/\*(.*)\*/gim, '<em>$1</em>')
            // Code blocks
            .replace(/```([\s\S]*?)```/gim, '<pre><code>$1</code></pre>')
            // Inline code
            .replace(/`([^`]*)`/gim, '<code>$1</code>')
            // Links
            .replace(/\[([^\]]*)\]\(([^\)]*)\)/gim, '<a href="$2" target="_blank">$1</a>')
            // Line breaks
            .replace(/\n/gim, '<br>');
            
        return html;
    }

    filterDocuments() {
        this.filteredDocuments = this.allDocuments.filter(doc => {
            // Apply search filter
            if (this.searchTerm) {
                const searchLower = this.searchTerm.toLowerCase();
                if (!doc.Title.toLowerCase().includes(searchLower) &&
                    !doc.Description?.toLowerCase().includes(searchLower)) {
                    return false;
                }
            }
            
            // Apply document type filter
            if (this.selectedDocumentType !== 'all' &&
                doc.DocumentType !== this.selectedDocumentType) {
                return false;
            }
            
            return true;
        });
    }

    getDocumentIcon(documentType) {
        const iconMap = {
            'flow_doc': 'utility:knowledge_base',
            'analysis_report': 'utility:analytics',
            'performance_report': 'utility:metrics',
            'best_practices': 'utility:rules',
            'troubleshooting': 'utility:help',
            'ai_insights': 'utility:einstein'
        };
        return iconMap[documentType] || 'utility:file';
    }

    formatDate(dateString) {
        if (!dateString) return '';
        return new Date(dateString).toLocaleDateString();
    }

    formatSize(sizeInBytes) {
        if (!sizeInBytes) return '0 B';
        const units = ['B', 'KB', 'MB', 'GB'];
        let size = sizeInBytes;
        let unitIndex = 0;
        
        while (size >= 1024 && unitIndex < units.length - 1) {
            size /= 1024;
            unitIndex++;
        }
        
        return `${Math.round(size * 100) / 100} ${units[unitIndex]}`;
    }

    // Text formatting tools
    formatBold() {
        this.insertTextAtCursor('**', '**');
    }

    formatItalic() {
        this.insertTextAtCursor('*', '*');
    }

    formatCode() {
        this.insertTextAtCursor('`', '`');
    }

    insertLink() {
        const url = prompt('Enter URL:');
        if (url) {
            const text = prompt('Enter link text:') || url;
            this.insertTextAtCursor(`[${text}](${url})`);
        }
    }

    insertImage() {
        const url = prompt('Enter image URL:');
        if (url) {
            const alt = prompt('Enter alt text:') || 'Image';
            this.insertTextAtCursor(`![${alt}](${url})`);
        }
    }

    insertTextAtCursor(beforeText, afterText = '') {
        const textarea = this.template.querySelector('.content-textarea');
        if (!textarea) return;

        const start = textarea.selectionStart;
        const end = textarea.selectionEnd;
        const text = textarea.value;
        const selectedText = text.substring(start, end);
        
        const newText = text.substring(0, start) + 
                       beforeText + selectedText + afterText + 
                       text.substring(end);
        
        this.documentContent = newText;
        this.hasUnsavedChanges = true;
        
        // Update textarea and restore cursor position
        setTimeout(() => {
            textarea.value = newText;
            textarea.selectionStart = start + beforeText.length;
            textarea.selectionEnd = start + beforeText.length + selectedText.length;
            textarea.focus();
        }, 0);
    }

    // Toast notifications
    showError(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
        }));
    }

    showSuccess(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        }));
    }

    showInfo(message) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Info',
            message: message,
            variant: 'info'
        }));
    }
}