# Trivy介绍

Trivy 是一个开源的安全扫描工具，主要用于容器镜像、文件系统、Git 仓库、Kubernetes 等的漏洞和配置风险检测。使用简单，扫描速度快，支持多种平台

主要功能包括：

* 漏洞扫描：检测镜像、文件系统、代码仓库中的已知安全漏洞（CVE）
* 配置检查：检查 Dockerfile、Kubernetes、Terraform 等配置文件的安全合规性
* 支持多种目标：可扫描本地镜像、远程镜像、容器、文件夹、Git 仓库等
* 数据库自动更新：Trivy 会自动下载最新的漏洞数据库，保证扫描结果的时效性
* 易于集成：可与 CI/CD 流程、DevOps 工具链集成，支持命令行和 API

适合开发者、运维、安全团队在开发和部署阶段快速发现安全隐患，提升软件供应链安全

# 使用说明

镜像构建

```sh
docker build -t trivy-alpine:0.51.2 .
```

容器构建

```sh
docker run --name trivy-alpine -it -v ./scan:/scan -v ./report:/report -v /root/.cache/trivy trivy-alpine:0.51.2 sh
```

以扫描 `python:3.11.7-slim`镜像压缩包为例，首次会自动下载漏洞数据库DB，在构建容器时已经把 `/root/.cache/trivy`漏洞数据库匿名挂载到宿主机中，避免扫描时多次重复下载数据库

```bash
docker exec -it trivy-alpine sh
trivy image --input /scan/python_3.11.7-slim.tar -o /report/python_3.11.7-slim-report.txt
```

该容器无法直接访问Windows主机上Docker Desktop的镜像目录，所以采用 `docker save`命令将 `python:3.11.7-slim`镜像导出为tar文件放到scan目录下来进行扫描，如果本地没有该镜像先 `docker pull`

```bash
docker save python:3.11.7-slim -o ./scan/python_3.11.7-slim.tar
```

扫描结果默认以表格形式输出，考虑后续处理也可以输出为JSON格式

```bash
trivy image --input /scan/python_3.11.7-slim.tar -o /report/python_3.11.7-slim-report.json --format json
```

还支持其他输出格式，具体查询官方文档；如果想直接扫描本地的image，可以直接安装Trivy的主机版

也可以直接基于官方镜像构建容器运行，但是由于这样构建的容器内没有sh或者bash，只能每次构建临时容器处理一个镜像压缩包，结果输出可能无法持久保存

Trivy的默认扫描时间为10分钟，如果镜像较大可能会导致未在默认时间内完成分析从而失败

- 增加超时时间 `--timeout 15m`
- 只扫描漏洞不扫描依赖 `--scanners vuln`
- 输出详细调试日志 `--debug`，这个命令和-o冲突，如果需要同时输出到终端和日志可以使用 `tee`
  ```sh
  trivy image --input /scan/python_3.11.7-slim.tar --timeout 1h --debug | tee /report/python_3.11.7-slim-report.txt
  ```

# 结果解析

以生成的 `python_3.11.7-slim-report.txt`为例

1. 报告头部

```txt
/scan/python_3.11.7-slim.tar (debian 12.4)
==========================================
Total: 203 (UNKNOWN: 1, LOW: 87, MEDIUM: 77, HIGH: 29, CRITICAL: 9)
```

* 显示扫描的镜像文件和基础系统（如 debian 12.4）
* 总共发现 203 个漏洞，按严重等级分类（CRITICAL、HIGH、MEDIUM、LOW、UNKNOWN）

2. 漏洞详情表格

| 字段              | 说明                                              |
| ----------------- | ------------------------------------------------- |
| Library           | 受影响的软件包名称，如 apt、bash、coreutils 等    |
| Vulnerability     | 漏洞编号（如 CVE-2024-28085），可用于查找详细信息 |
| Severity          | 严重等级（LOW、MEDIUM、HIGH、CRITICAL、UNKNOWN）  |
| Status            | 漏洞状态（affected、fixed、will_not_fix 等）      |
| Installed Version | 镜像中安装的软件包版本                            |
| Fixed Version     | 已修复漏洞的软件包版本（如有）                    |
| Title             | 漏洞简要描述及参考链接                            |

3. 漏洞状态解读

* **affected** ：镜像中的软件包受该漏洞影响，尚未修复
* **fixed** ：该漏洞已被修复，报告会显示可升级到的修复版本（Fixed Version）
* **will_not_fix** ：官方决定不修复该漏洞，通常是因为影响较小或已弃用
* **unknown** ：漏洞状态不明确，可能是新发现或信息不全
