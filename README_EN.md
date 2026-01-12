<div align="center">

# HTTP Traffic Recorder

[English](README_EN.md) | [简体中文](README.md)

</div>

## ⚠️ Important Notice

The techniques, ideas, and tools mentioned in this document are intended **only** for learning and security research purposes. Do **not** use them for any illegal activities or for profit. You are solely responsible for any consequences resulting from misuse.

## 📋 Table of Contents
- [Introduction](#introduction)
- [Features](#features)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [Usage Guide](#usage-guide)
- [Configuration](#configuration)
- [Database Support](#database-support)
- [Changelog](#changelog)
- [License](#license)
- [Support](#support)

## Introduction

- **Author**: [小洲](https://github.com/xz-zone)
- **Team**: [横戈安全团队](imgs/logo.jpg). More tools will be open-sourced in the near future. Follow our WeChat official account:

  ![logo](imgs/logo.jpg)
- **Positioning**: A Burp Suite extension for HTTP traffic monitoring and management designed for security testing. It helps testers/teams collaborate when reviewing traffic logs.
- **Language**: Java (JDK 17+), Chinese UI
- **Overview**: Multi-tool traffic monitoring, domain-tree filtering, history import, quick/advanced search, configuration & database management, and log management.

## ✨ Features

### 🔍 Traffic Monitoring
- Supports traffic from multiple Burp tools: Proxy, Intruder, Repeater, Logger, Scanner, Target, etc.
- Real-time capture of requests/responses
- Hostname allow/deny lists and file-suffix filtering with wildcard support

### 💾 Data Storage
- Databases: SQLite (default, single-user), MySQL (team), PostgreSQL (team)
- Persistent storage with connection pooling and team sharing

### 🔎 Search & Query
- Quick search (Host/Method/URL/Path/Status code, etc.)
- Multi-condition advanced queries, tool filter, paginated loading

### 🌳 Domain Tree
- Tree view: top-level root domains and subdomains
- Root domain: fuzzy “contains” match; subdomain: exact host match
- Search, manual refresh, and auto expand

### 📥 History Import
- One-click import from Target history and Proxy HTTP history
- Progress/status display; filtering rules are applied during import

### ⚙️ Configuration Management
- Monitored tools, save options, and filtering rules
- Import/export configuration; changes take effect immediately

### 📊 Data Display
- Table view + detail panel, batch select/delete, export to CSV

### 📝 Logging
- Levels: INFO / WARN / ERROR / DEBUG
- Outputs: file / console, with configurable path

## 🔧 System Requirements

- Burp Suite 2025.3 or later
- Java JDK 17 or later
- OS: Windows / Linux / macOS

## 📦 Installation

### Using the prebuilt JAR
1. Download the latest `burp-http-monitor.jar`
2. Open Burp Suite → `Extensions` → `Installed`
3. Click `Add`, choose `Extension type: Java`
4. Select the JAR and click `Next` to install

### Team database deployment (MySQL/PostgreSQL)
1. `Mysql.sh`: deploy MySQL (Docker) on Linux
2. `Postgres.sh`: deploy PostgreSQL (Docker) on Linux

## 📖 Usage Guide

### First-time setup
1) Load the extension as described above. You should see a `Traffic Recorder` tab  
2) (Optional) Database: SQLite is used by default. Configure MySQL/PostgreSQL in the **Database Configuration** tab if needed  
3) Monitoring options: choose tools, save options, and allow/deny lists in **Monitoring Configuration**  
4) Start monitoring: traffic is captured automatically and displayed in **Traffic Monitoring**

### Traffic Monitoring page
- Search: keyword + field (All/Host/Method/URL/Path/Status code), tool filter; advanced search supports multiple conditions
- Domain tree: on the left; root domain fuzzy match, subdomain exact match; supports search and refresh
- Data operations: view details, batch select/delete, export CSV

### History import
- In **Traffic Monitoring** toolbar: `Import Target History` / `Import Proxy History`. Progress is shown and results appear automatically after import.

### Settings
- Monitoring: tools, request/response saving, allow/deny lists and wildcards
- Database: SQLite/MySQL/PostgreSQL, connection pool, team ID (optional)
- Logging: level, output (file/console), path

## ⚙️ Configuration

- Config directory: `~/.config/burp_monitor/` (Windows: `C:\Users\<username>\.config\burp_monitor\`)
- File: `config.json` (monitoring, filtering, database)
- Import/export/reload in the **Monitoring Configuration** tab

## 🗄️ Database Support

- **SQLite**: single-user, zero config
- **MySQL**: team mode; host/port/db/user/password/pool/team ID
- **PostgreSQL**: team mode; host/port/db/user/password/pool/team ID

## 📝 Changelog

### v1.0.0
- ✨ Initial release
- ✅ Multi-tool traffic monitoring
- ✅ SQLite/MySQL/PostgreSQL support
- ✅ Traffic search and advanced query
- ✅ Domain tree display and fast filtering
- ✅ History import
- ✅ Configuration management and import/export
- ✅ Logging management

### v1.0.1
- ✅ Fixed color adaptation issues in Burp Dark theme
- ✅ Added HTTP method filtering

### v1.0.2
- ✅ Optimize Domain Tree
- ✅ Optimize and delete filtering results
- ✅ Optimize the loading of package details for stuck issues
- ✅ Add packet storage issues, API reset
  ```
  Hash calculation logic:
	Basic hash: host+"|"+path+"|"+method
	If 'Consider RequestBody' is enabled (including RequestBody=true) and the request method is POST/PUT/PATCH/DELETE:
	Calculate the hash of requestBody
	Append the body hash to the base hash: apiKey+"|"+bodyHash
	Finally calculate SHA-256 for the entire string
  ```
### v1.0.3
-  ✅  Add notes for each interface
-  ✅  Add request packet and response packet search
-  ✅  Add database configuration ->Display maximum number
-  ✅  Optimize single machine mode, delete database, add prompt to delete database inquiry box
-  ✅  Optimize right-click menu
-  ✅  Optimize CSV export with remark fields
-  ✅  Optimize domain name tree click query issues
-  ✅  Optimizing context storage issues

### v1.0.4
-  ✅  Add Advanced Query ->Time Filtering
-  ✅  Optimize note input

### v1.0.5
-  ✅  Add encoding conversion
-  ✅  Optimize caching mechanism and context retrieval port

### v1.0.6
-  ✅  Optimize configuration saving
-  ✅  Optimize team mode database field issues

### v1.0.7
-  ✅  Added ability to select fields for CSV export
-  ✅  Optimized to not force selection of time

## 📄 License

MIT License (see LICENSE).

## 📞 Support

- Submit an Issue: [GitHub Issues](https://github.com/xz-zone/burp_history/issues)
- Email: see GitHub profile

## Stargazers over time

[![Stargazers over time](https://starchart.cc/xz-zone/burp_history.svg?variant=adaptive)](https://starchart.cc/xz-zone/burp_history)
