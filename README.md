<div align="center">

# HTTP Traffic Recorder

[English](README_EN.md) | [简体中文](README.md)

</div>

## ⚠️ 郑重声明

文中所涉及的技术、思路和工具仅供以安全为目的的学习交流使用，任何人不得将其用于非法用途以及盈利等目的，否则后果自行承担。

## 📋 目录
- [介绍](#介绍)
- [功能特性](#功能特性)
- [系统要求](#系统要求)
- [安装说明](#安装说明)
- [使用指南](#使用指南)
- [配置说明](#配置说明)
- [数据库支持](#数据库支持)
- [更新日志](#更新日志)
- [许可证](#许可证)
- [支持](#支持)

## 介绍

- **作者**：[小洲](https://github.com/xz-zone)
- **团队**：[横戈安全团队](imgs/logo.jpg)，未来一段时间将陆续开源工具，欢迎关注微信公众号：

  ![logo](imgs/logo.jpg)
- **定位**：面向安全测试人员的 Burp Suite HTTP 流量监控与管理扩展，方便广大测试人员/团队人员共同协作查看流量日志
- **语言**：Java（JDK 17+），界面中文
- **功能简介**：多工具流量监控、域名树筛选、历史导入、快速/高级查询、配置与数据库管理、日志管理

## ✨ 功能特性

### 🔍 流量监控
- 支持 Proxy、Intruder、Repeater、Logger、Scanner、Target 等多工具流量
- 实时捕获请求/响应
- 主机名/后缀黑白名单，支持通配符

### 💾 数据存储
- 数据库：SQLite（默认，单机）、MySQL（团队）、PostgreSQL（团队）
- 持久化存储，支持连接池与团队共享

### 🔎 搜索与查询
- 快速搜索（主机/方法/URL/路径/状态码等）
- 多条件高级查询；工具过滤；分页加载

### 🌳 域名树
- 树形展示：一级主域名，二级子域名
- 主域名：模糊匹配包含；子域名：精确匹配 host
- 支持搜索、手动刷新、自动展开

### 📥 历史数据导入
- 一键导入 Target 历史、Proxy HTTP History
- 显示进度/状态，导入时应用过滤

### ⚙️ 配置管理
- 监控工具、保存选项、过滤规则
- 配置导入/导出，修改实时生效

### 📊 数据展示
- 表格视图、详情面板、批量选择/删除、导出 CSV

### 📝 日志管理
- 日志级别：INFO / WARN / ERROR / DEBUG
- 输出：文件 / 控制台，可配置路径

## 🔧 系统要求

- Burp Suite 2025.3 或更高版本
- Java JDK 17 或更高版本
- 操作系统：Windows / Linux / macOS

## 📦 安装说明

### 使用预编译 JAR
1. 下载最新版 `burp-http-monitor.jar`
2. 打开 Burp Suite → `Extensions` → `Installed`
3. 点击 `Add`，选择 `Extension type: Java`
4. 选择 JAR 并 `Next` 安装

### 团队Mysql/PostgreSQL 数据库部署
1. Mysql.sh Liunx部署Mysql docker版本
2. Postgres.sh  Liunx部署Postgres docker版本

## 📖 使用指南

### 首次使用
1) 按安装说明加载插件，出现 `Traffic Recorder` 标签页
2) （可选）数据库：默认 SQLite 即可；MySQL/PostgreSQL 请在 **数据库配置** 标签页设置
3) 监控选项：在 **监控配置** 选择工具、保存选项、黑白名单
4) 开始监控：自动捕获，数据在 **流量监控** 展示

### 流量监控页面
- 搜索：关键词 + 字段（全部/Host/Method/URL/Path/状态码）；工具过滤；高级查询支持多条件
- 域名树：左侧；主域名模糊匹配，子域名精确匹配；可搜索与刷新
- 数据操作：查看详情、批量选择/删除、导出 CSV

### 历史导入
- 在 **流量监控** 操作栏：`导入Target历史`、`导入Proxy历史`；显示进度，导入后自动展示

### 配置
- 监控：工具、请求/响应保存、黑白名单/通配符
- 数据库：SQLite/MySQL/PostgreSQL，连接池、团队ID（可选）
- 日志：级别、输出（文件/控制台）、路径

## ⚙️ 配置说明

- 配置路径：`~/.config/burp_monitor/`（Windows 为 `C:\Users\<用户名>\.config\burp_monitor\`）
- 文件：`config.json`（监控、过滤、数据库）
- 在 **监控配置** 标签页导入/导出/重新加载

## 🗄️ 数据库支持

- **SQLite**：单机零配置
- **MySQL**：团队模式；主机/端口/库/用户/密码/连接池/团队ID
- **PostgreSQL**：团队模式；主机/端口/库/用户/密码/连接池/团队ID

## 📝 更新日志

### v1.0.0
- ✨ 初始版本
- ✅ 支持多工具流量监控
- ✅ 支持SQLite、MySQL、PostgreSQL数据库
- ✅ 流量搜索和高级查询功能
- ✅ 域树显示和快速过滤
- ✅ 历史数据导入功能
- ✅ 配置管理和导入/导出
- ✅ 日志管理功能

### v1.0.1
- ✅ 优化不适配burp dark配色 问题
- ✅ 增加请求方法过滤

### v1.0.2
- ✅ 优化域名树
- ✅ 优化删除筛选结果
- ✅ 优化数据包详情加载卡死问题
- ✅ 增加数据包存储问题，API去重设置
  ```
  Hash 计算逻辑：
    基础 hash：host + "|" + path + "|" + method
    如果启用“考虑请求体”（includeRequestBody = true），且请求方法是 POST/PUT/PATCH/DELETE：
    计算 requestBody 的 hash
    将 body hash 追加到基础 hash：apiKey + "|" + bodyHash
    最终对整个字符串计算 SHA-256
  ```

### v1.0.3
- ✅ 增加 每个接口的备注
- ✅ 增加 请求包、响应包 搜索
- ✅ 增加 数据库配置->显示最大数
- ✅ 优化 单机模式 删除数据库 增加提示 删除数据库咨讯框
- ✅ 优化 右键菜单
- ✅ 优化 导出CSV，备注字段
- ✅ 优化 域名树 点击查询问题
- ✅ 优化 上下文存储问题

## 📄 许可证

MIT 许可证（详见 LICENSE）。

## 📞 支持

- 提交 Issue: [GitHub Issues](https://github.com/xz-zone/burp_history/issues)
- 邮箱：参见 GitHub 主页

## Stargazers over time

[![Stargazers over time](https://starchart.cc/xz-zone/burp_history.svg?variant=adaptive)](https://starchart.cc/xz-zone/burp_history)
