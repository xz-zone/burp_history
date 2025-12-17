<div align="center">

# HTTP Traffic Recorder

[English](README_EN.md) | [简体中文](README.md)

</div>

## ⚠️ Disclaimer
All techniques, ideas, and tools are for security learning/research only. Do not use them for illegal purposes or profit. You bear all consequences for misuse.

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration Details](#configuration-details)
- [Database Support](#database-support)
- [Changelog](#changelog)
- [License](#license)
- [Support](#support)

## Overview
- **Author**: xiaozhou  
- **Team**: xz-zone / burp_history  
- **Positioning**: Burp Suite HTTP traffic monitoring & management extension for security testers  
- **Language**: Java (JDK 17+), UI in Chinese  
- **Summary**: Multi-tool traffic capture, domain tree filtering, history import, fast/advanced search, config & DB management, logging.

## ✨ Features
### 🔍 Traffic Monitoring
- Multi-tool: Proxy, Intruder, Repeater, Logger, Scanner, Target, etc.
- Real-time capture of HTTP requests/responses
- Smart filtering: blacklist/whitelist by host or extension; wildcard matching

### 💾 Data Storage
- Databases: SQLite (single, default), MySQL (team), PostgreSQL (team)
- Persistence for long-term analysis; connection pooling; team sharing

### 🔎 Search & Query
- Quick search by host/method/URL/path/status
- Advanced multi-condition queries
- Tool filter; paginated loading for large datasets

### 🌳 Domain Tree
- Tree view: root domain (level 1), subdomain (level 2)
- Root click: fuzzy match (contains root domain); subdomain click: exact match host = subdomain
- Search within tree; manual refresh; auto expansion

### 📥 History Import
- Import Target history; import Proxy HTTP history
- Progress/status display; applies filters during import

### ⚙️ Configuration
- Monitor tools, save options, filters
- Import/export configs; changes take effect immediately

### 📊 Data View
- Table view, detail pane, batch select/delete, CSV export

### 📝 Logging
- Levels INFO/WARN/ERROR/DEBUG; file/console output; configurable paths

## 🔧 Requirements
- Burp Suite 2025.3+
- Java JDK 17+
- OS: Windows / Linux / macOS

## 📦 Installation
### Prebuilt JAR
1. Download the latest `burp-http-monitor.jar`.
2. Open Burp Suite → `Extensions` → `Installed`.
3. Click `Add`, choose `Extension type: Java`.
4. Select the JAR and `Next` to install.

### Team Mysql/PostgreSQL database deployment
1. MySQL. sh Liunx deploys MySQL Docker version
2. Postgres.sh Liunx deploys Postgres Docker version

## 📖 Usage
### First time
1. Load the extension (see Installation) to get the `Traffic Recorder` tab.  
2. (Optional) DB: SQLite works out of the box; for MySQL/PostgreSQL use **Database Configuration**.  
3. Monitoring: in **Monitoring Configuration** pick tools, save options, blacklist/whitelist.  
4. Start monitoring: capture is automatic; view data in **Traffic Monitoring**.

### Traffic Monitoring page
- **Search**: keyword + field (All/Host/Method/URL/Path/Status); tool filter; Advanced Query for multi-condition search.
- **Domain tree**: root = fuzzy match, subdomain = exact host; search box; refresh tree.
- **Data ops**: view details; batch select/delete; export CSV.

### History Import
- In **Traffic Monitoring** action bar: `Import Target History`, `Import Proxy History`; progress & status shown; data auto-appears.

### Configuration
- Monitoring: tools, request/response saving, filters (black/white, wildcard)
- Database: SQLite/MySQL/PostgreSQL; pool size; teamId (optional)
- Logging: level, output (file/console), file path

## ⚙️ Configuration Details
- Config path: `~/.config/burp_monitor/` (`C:\Users\<user>\.config\burp_monitor\` on Windows)
- File: `config.json` (monitoring, filters, database)
- Import/export/reload in **Monitoring Configuration**

## 🗄️ Database Support
- **SQLite**: single-user, zero config
- **MySQL**: team mode; host/port/db/user/pass/pool/teamId
- **PostgreSQL**: team mode; host/port/db/user/pass/pool/teamId

## 📝 Changelog
### v1.0.0
- Initial release; multi-tool capture; SQLite/MySQL/PostgreSQL; search & advanced query; domain tree; history import; config & logging.

## 📄 License
MIT License (see LICENSE).

## 🙏 Support
- Issues: [GitHub Issues](https://github.com/xz-zone/burp_history/issues)  
- Email: see GitHub profile
# HTTP Traffic Recorder

A powerful Burp Suite extension for monitoring, recording, and managing HTTP traffic data.

## 📋 Table of Contents

- [Features](#features)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [User Guide](#user-guide)
- [Configuration](#configuration)
- [Database Support](#database-support)
- [Project Structure](#project-structure)
- [Development](#development)
- [Changelog](#changelog)
- [License](#license)

## ✨ Features

### 🔍 Traffic Monitoring
- **Multi-Tool Support**: Monitor traffic from Proxy, Intruder, Repeater, Logger, Scanner, Target, and other Burp Suite tools
- **Real-time Recording**: Automatically capture and record all HTTP requests and responses
- **Smart Filtering**: Support blacklist/whitelist filtering rules based on hostnames and file extensions
- **Wildcard Matching**: Support wildcard pattern matching for flexible filter configuration

### 💾 Data Storage
- **Multiple Database Support**:
  - SQLite (Standalone mode, default)
  - MySQL (Team mode)
  - PostgreSQL (Team mode)
- **Data Persistence**: All traffic data is automatically saved to the database for long-term storage and analysis
- **Connection Pool Management**: Support database connection pooling for improved performance
- **Team Collaboration**: Support team mode for multi-user data sharing

### 🔎 Search & Query
- **Quick Search**: Search by host, method, URL, path, status code, and other fields
- **Advanced Query**: Support multi-condition combination queries for flexible data filtering
- **Tool Filtering**: Filter traffic records by tool type
- **Pagination**: Support pagination loading for better performance with large datasets

### 🌳 Domain Tree
- **Tree View**: Display all domains in a tree structure, with root domains as level 1 and subdomains as level 2
- **Quick Filtering**: Click domain tree nodes to quickly filter traffic for corresponding domains
- **Smart Matching**:
  - Click level 1 node (root domain): Fuzzy match, show all records containing the root domain
  - Click level 2 node (subdomain): Exact match, show only records for that subdomain
- **Search Function**: Support searching in the domain tree, filter matching domain nodes in real-time
- **Auto Refresh**: Support manual refresh of the domain tree to update domain statistics in real-time

### 📥 History Data Import
- **Target History Import**: One-click import of all historical data from Burp Suite Target tab
- **Proxy History Import**: One-click import of all historical data from Burp Suite Proxy HTTP History
- **Progress Display**: Real-time display of import progress and status
- **Auto Filtering**: Automatically apply configured filter rules during import

### ⚙️ Configuration Management
- **Flexible Configuration**: Support configuration of monitoring tools, data saving options, filter rules, etc.
- **Config Import/Export**: Support import and export of configuration files for easy backup and migration
- **Real-time Effect**: Configuration changes take effect immediately without restart

### 📊 Data Display
- **Table View**: Clear table display of all traffic records
- **Detail View**: Click records to view complete request and response details
- **Batch Operations**: Support batch selection and deletion of records
- **Data Export**: Support exporting search results to files

### 📝 Log Management
- **Log Levels**: Support INFO, WARN, ERROR, DEBUG and other log levels
- **Log Output**: Support output to files and console
- **Log Configuration**: Configurable log level and output method

## 🔧 System Requirements

- **Burp Suite**: Version 2025.3 or higher
- **Java**: JDK 17 or higher
- **Operating System**: Windows, Linux, macOS

## 📦 Installation

### Method 1: Using Pre-compiled JAR File

1. Download the latest version of `burp-http-monitor.jar` file
2. Open Burp Suite
3. Go to `Extensions` → `Installed` tab
4. Click the `Add` button
5. Select `Extension type: Java`
6. Select the downloaded JAR file
7. Click `Next` to complete installation

### Method 2: Build from Source

```bash
# Clone the project
git clone https://github.com/xz-zone/burp_history.git
cd burp_history

# Build with Gradle
./gradlew build

# The generated JAR file is located at
# build/libs/burp-http-monitor.jar
```

## 📖 User Guide

### First Time Use

1. **Load Extension**: After loading the extension according to the installation instructions, a `Traffic Recorder` tab will appear in Burp Suite

2. **Configure Database** (Optional):
   - By default, SQLite database is used and requires no configuration
   - To use MySQL or PostgreSQL, go to the `Database Configuration` tab

3. **Configure Monitoring Options**:
   - Go to the `Monitoring Configuration` tab
   - Select the tools to monitor (Proxy, Intruder, Repeater, etc.)
   - Configure data saving options (whether to save requests/responses)
   - Set filter rules (blacklist/whitelist)

4. **Start Monitoring**:
   - After configuration, the extension will automatically start monitoring and recording traffic
   - View all records in the `Traffic Monitoring` tab

### Traffic Monitoring Page

#### Search Function
- **Keyword Search**: Enter keywords in the search box, select search field (All Fields, Host, Method, URL, Path, Status Code)
- **Tool Filter**: Use the tool dropdown to filter traffic from specific tools
- **Advanced Query**: Click the `Advanced Query` button to set multiple query conditions for combination queries

#### Domain Tree
- **View Domains**: The domain tree on the left displays all domains, with root domains as level 1 and subdomains as level 2
- **Quick Filtering**:
  - Click level 1 node (root domain): Show all records containing the root domain
  - Click level 2 node (subdomain): Show only records for that subdomain
- **Search Domains**: Enter keywords in the search box below the domain tree to filter domain nodes in real-time
- **Refresh Tree**: Click the `Refresh Tree` button to update domain statistics

#### Data Operations
- **View Details**: Click records in the table to view complete request and response details below
- **Batch Selection**: Use checkboxes to select multiple records
- **Delete Records**: Select records and click the `Delete Selected` button
- **Export Data**: Click the `Export` button to export search results to a file

### History Data Import

1. In the `Traffic Monitoring` tab's action panel, click the `Import Target History` or `Import Proxy History` button
2. Wait for the import to complete, the progress bar will show the import progress
3. After import, data will automatically appear in the traffic monitoring table

### Configuration Management

#### Monitoring Configuration
- **Monitoring Tools**: Select Burp Suite tools to monitor
- **Data Saving**: Configure whether to save requests and responses
- **Filter Rules**:
  - **Blacklist Mode**: Do not record traffic matching blacklist rules
  - **Whitelist Mode**: Only record traffic matching whitelist rules
  - Support hostname and wildcard patterns

#### Database Configuration
- **Standalone Mode**: Use SQLite database, data stored in local files
- **Team Mode**: Use MySQL or PostgreSQL, support multi-user data sharing
- **Connection Pool**: Configurable connection pool size for improved performance

#### Log Settings
- **Log Level**: Set log output level (INFO, WARN, ERROR, DEBUG)
- **Output Method**: Choose to output logs to file or console
- **File Path**: Configure log file save path

## ⚙️ Configuration

### Configuration File Location

Configuration files are saved in the `.config/burp_monitor/` directory under the user's home directory:
- **Windows**: `C:\Users\<username>\.config\burp_monitor\`
- **Linux/macOS**: `~/.config/burp_monitor/`

### Configuration Files

- `config.json`: Main configuration file, contains monitoring configuration, filter rules, etc.
- `database_config.json`: Database configuration file

### Configuration Import/Export

- **Export Configuration**: Click the `Export Configuration` button in the `Monitoring Configuration` tab
- **Import Configuration**: Click the `Import Configuration` button and select a configuration file to import
- **Reload**: Click the `Reload` button to reload configuration from file

## 🗄️ Database Support

### SQLite (Default)

- **Mode**: Standalone mode
- **Features**: No configuration required, ready to use out of the box
- **Use Cases**: Personal use, local storage

### MySQL

- **Mode**: Team mode
- **Features**: Support multi-user data sharing
- **Configuration**:
  - Host address
  - Port (default 3306)
  - Database name
  - Username and password
  - Connection pool size
  - Team ID (optional)

### PostgreSQL

- **Mode**: Team mode
- **Features**: Support multi-user data sharing
- **Configuration**:
  - Host address
  - Port (default 5432)
  - Database name
  - Username and password
  - Connection pool size
  - Team ID (optional)

## 📁 Project Structure

```
burp_history/
├── src/
│   └── main/
│       └── java/
│           └── com/
│               └── burp/
│                   └── monitor/
│                       ├── BurpExtender.java          # Extension entry point
│                       ├── database/                  # Database related
│                       │   ├── DatabaseManager.java  # Database manager
│                       │   ├── DatabaseConfig.java    # Database configuration
│                       │   ├── HttpRecord.java        # HTTP record entity
│                       │   ├── SearchCondition.java  # Search condition
│                       │   └── SqlQueryBuilder.java   # SQL builder
│                       ├── monitor/                   # Monitoring related
│                       │   ├── TrafficMonitor.java    # Traffic monitor
│                       │   └── Config.java            # Configuration class
│                       ├── ui/                        # UI related
│                       │   └── MainPanel.java         # Main interface
│                       └── utils/                     # Utility classes
│                           ├── ConfigManager.java     # Configuration manager
│                           ├── LogManager.java         # Log manager
│                           ├── HttpParser.java         # HTTP parser
│                           ├── WildcardMatcher.java   # Wildcard matcher
│                           └── ...
├── build.gradle.kts                                   # Gradle build configuration
└── README.md                                          # Project documentation
```

## 🛠️ Development

### Requirements

- JDK 17+
- Gradle 7.0+
- Burp Suite 2025.3+

### Build Project

```bash
# Compile project
./gradlew build

# Generate JAR file
./gradlew jar

# Generate Fat JAR with all dependencies
./gradlew fatJar
```

### Code Structure

- **BurpExtender**: Extension entry point, responsible for initializing components
- **TrafficMonitor**: HTTP traffic monitor, handles requests and responses
- **DatabaseManager**: Database manager, responsible for data persistence
- **MainPanel**: Main interface, contains all UI components and interaction logic
- **ConfigManager**: Configuration manager, responsible for loading and saving configuration

## 📝 Changelog

### v1.0.0

- ✨ Initial release
- ✅ Support multi-tool traffic monitoring
- ✅ Support SQLite, MySQL, PostgreSQL databases
- ✅ Traffic search and advanced query functionality
- ✅ Domain tree display and quick filtering
- ✅ History data import functionality
- ✅ Configuration management and import/export
- ✅ Log management functionality

## 📄 License

This project is licensed under the MIT License. See the LICENSE file for details.

## 🙏 Acknowledgments

Thanks to all developers and users who have contributed to this project.

## 📞 Support

For questions or suggestions, please contact:

- Submit Issue: [GitHub Issues](https://github.com/xz-zone/burp_history/issues)
- Email: Please check GitHub homepage

## Stargazers over time

[![Stargazers over time](https://starchart.cc/xz-zone/burp_history.svg?variant=adaptive)](https://starchart.cc/xz-zone/burp_history)

