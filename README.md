# FlowSense - Salesforce Flow Analytics & Performance Monitoring

🚀 **Advanced Flow Performance Monitoring and Analytics Platform for Salesforce**

## 📋 Overview

FlowSense is a comprehensive Salesforce solution that provides real-time monitoring, performance analytics, and optimization insights for Salesforce Flows. Built with Lightning Web Components and Apex, it offers enterprise-grade flow governance and performance management capabilities.

## ✨ Key Features

### 📊 **Dashboard & Analytics**
- **Real-time Performance Monitoring** - Track flow execution metrics in real-time
- **Performance Scoring** - Automated scoring based on CPU time, SOQL queries, and DML operations
- **Risk Assessment** - Intelligent risk level categorization (Low, Medium, High, Critical)
- **Export Functionality** - Download performance data as CSV for further analysis
- **Interactive Filters** - Filter by time range, risk level, flow type, and search flows

### 🔍 **Flow Analysis & Insights**
- **Execution History** - Detailed logging of every flow execution
- **Step-by-step Tracking** - Monitor individual flow element performance
- **Error Detection** - Capture and analyze flow failures and exceptions
- **Performance Trends** - Historical analysis and trend identification

### 📈 **Performance Metrics**
- **CPU Time Monitoring** - Track processor usage per flow execution
- **SOQL Query Analysis** - Monitor database query efficiency
- **DML Operations** - Track data manipulation operations
- **Memory Usage** - Heap size monitoring and optimization

### 🎛️ **Management Tools**
- **Flow Documentation** - Auto-generated flow documentation
- **Version Comparison** - Compare different versions of flows
- **Settings Management** - Configurable thresholds and parameters
- **Data Retention** - Automated cleanup and archival processes

## 🏗️ Architecture

### **Components**
- **Lightning Web Components (LWC)**
  - `flowSenseDashboard` - Main dashboard interface
  - `flowVersionCompare` - Flow version comparison tool
  - `fsRunExplorer` - Execution history explorer
  - `fsPerfHeatmap` - Performance heatmap visualization
  - `fsSettings` - Configuration management

- **Apex Classes**
  - `FS_DashboardController` - Dashboard data provider
  - `FS_PerformanceService` - Performance calculation engine
  - `FS_LoggingService` - Execution logging service
  - `FS_NotifyService` - Alert and notification system

### **Custom Objects**
- `FS_Flow_Run__c` - Flow execution records
- `FS_Flow_Step__c` - Individual step tracking
- `FS_Flow_Analysis__c` - Performance analysis results
- `FS_Flow_Change__c` - Version change tracking

## 🚀 Installation

### Prerequisites
- Salesforce org with Lightning Experience enabled
- System Administrator access
- Flows feature enabled in your org

### Deploy to Salesforce
1. **Clone the repository**
   ```bash
   git clone https://github.com/mayankukey/FlowSense.git
   cd FlowSense
   ```

2. **Deploy using Salesforce CLI**
   ```bash
   sf project deploy start -d force-app/ -o your-org-alias
   ```

3. **Assign Permission Sets**
   - `FlowSense_Admin` - Full access for administrators
   - `FlowSense_Analyst` - Read/analyze access for analysts
   - `FlowSense_User` - Basic user access

## 📱 Usage

### Accessing FlowSense
1. Navigate to the **FlowSense** application in your Salesforce org
2. Click on the **Dashboard** tab to view the main analytics interface

### Dashboard Features
- **Real-time Metrics** - View total executions, performance scores, and risk indicators
- **Flow Analysis Table** - Browse detailed execution data with sorting and filtering
- **Export Data** - Download filtered results as CSV files
- **Performance Insights** - Analyze trends and identify optimization opportunities

## 👥 Authors

- **Mayank Ukey** - *Lead Developer* - [mayankukey15@gmail.com](mailto:mayankukey15@gmail.com)

---

**Built with ❤️ for the Salesforce Community**

Now that you’ve created a Salesforce DX project, what’s next? Here are some documentation resources to get you started.

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)
