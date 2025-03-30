
# 分布式 PyTorch DDP 训练任务使用说明

本文档旨在指导用户如何在 Kubernetes 环境中，利用 StatefulSet 与 Headless Service 构建的分布式部署，实现 PyTorch DDP 训练任务。系统会在每个 Pod 启动时自动注入一系列基础环境变量，用户可通过解析这些变量，灵活配置分布式训练参数，从而实现跨 Pod 通信与任务启动。

---

## 1. 环境概述

在该系统中，每个 **Pod** 均为任务的基本组织单元，每个 Pod 中运行着用户自定义的容器，该容器负责启动一个 PyTorch DDP 进程。为确保跨 Pod 通信，我们采用了以下两种机制：

- **StatefulSet：**  
  StatefulSet 会为每个 Pod 分配一个稳定的 DNS 名称。例如，第一个 Pod 的名称为 `statefulset_name-0`。

- **Headless Service：**  
  将 Service 的 `clusterIP` 配置为 `None` 后，所有携带指定标签的 Pod 将直接注册至 DNS。当其他 Pod 查询该 Service 域名时，会返回所有匹配 Pod 的 IP 地址列表，从而实现 Pod 之间的互联。  
  因此，每个 Pod 的完整 DNS 域名格式为：  
  ```
  statefulset_name-n.service_name.namespace.svc.cluster.local
  ```  
  例如，`statefulset_name-0.service_name.namespace.svc.cluster.local` 表示第一个 Pod 的 DNS 域名。

---

## 2. 注入的环境变量

在 Pod 启动过程中，系统会自动注入以下基础环境变量，供容器内部使用：

- **POD_NAME：** 当前 Pod 的名称（例如 `statefulset_name-n`）。
- **SVC_NAME：** 对应的 Service 名称，用于 DNS 解析。
- **POD_NUMS：** 集群中 Pod 的总数，表示任务整体规模。
- **POD_PORT：** 分布式任务通信所使用的端口号。
- **POD_NAMESPACE：** Pod 所在的命名空间，用于构成完整的 DNS 域名。

这些变量为组装分布式训练任务所需的参数提供了基础信息。

---

## 3. 环境变量处理与启动脚本示例

为了便于用户在镜像启动时动态配置分布式训练参数，建议在容器启动命令中加入如下脚本，对自动注入的环境变量进行处理，从而提取出分布式训练所必需的参数：

```bash
#!/bin/sh

# 从 POD_NAME 中提取 Pod 的数字标识，例如从 "statefulset_name-n" 中提取出 "n"
export MYRANK="${POD_NAME##*-}"

# 去除 POD_NAME 中的数字后缀，提取任务基础名称
export JOBNAME="${POD_NAME%-*}"

# 设置 Python 输出无缓冲，便于日志实时显示（对 PyTorch 训练有帮助）
export PYTHONUNBUFFERED='1'

# 继承由系统注入的通信端口
export MASTER_PORT=$POD_PORT
export PET_MASTER_PORT=$POD_PORT

# 构造主节点地址：默认设定序号为 0 的 Pod 为主节点
export MASTER_ADDR="${JOBNAME}-0.${SVC_NAME}.${POD_NAMESPACE}.svc.cluster.local"
export PET_MASTER_ADDR="${JOBNAME}-0.${SVC_NAME}.${POD_NAMESPACE}.svc.cluster.local"

# 设置分布式训练的全局进程数、当前进程编号等参数
export WORLD_SIZE=$POD_NUMS
export RANK=$MYRANK
export PET_NODE_RANK=$MYRANK

# 如有需要，可自动设定每个节点内的进程数（此处默认设置为 'auto'）
export PET_NPROC_PER_NODE='auto'
export PET_NNODES=$WORLD_SIZE

# 输出当前配置信息，便于调试验证
echo "Port is $PET_MASTER_PORT, master addr is $MASTER_ADDR, world size is $WORLD_SIZE, rank is $RANK"

# 执行用户自定义命令（例如启动分布式训练任务）
user_command
```

**脚本说明：**  
- **MYRANK：** 从 `POD_NAME` 中提取尾部数字，确定当前 Pod 的编号。  
- **JOBNAME：** 去除 `POD_NAME` 的数字部分，作为任务的基础名称。  
- **MASTER_ADDR / MASTER_PORT：** 构造分布式训练主节点的 DNS 地址和端口（默认主节点为编号为 0 的 Pod）。  
- 其余变量（如 `WORLD_SIZE`、`RANK`、`PET_NODE_RANK` 等）用于配置整个分布式训练框架。

用户可以根据自身需求，自定义或扩展该脚本以适应特定场景。

---

## 4. 使用步骤

1. **构建容器镜像：**  
   请确保您的镜像包含所有必要的依赖以及上述启动脚本。通常，可在 Dockerfile 中通过 `ENTRYPOINT` 或 `CMD` 指令指定启动脚本。

2. **配置 Kubernetes 清单：**  
   在 StatefulSet 配置文件中加入上述环境变量的设置。可参照平台提供的示例 YAML 文件进行配置。

3. **调试与验证：**  
   部署后，请检查 Pod 日志，确认诸如 `MASTER_ADDR`、`RANK`、`WORLD_SIZE` 等环境变量是否正确解析与配置。

4. **启动分布式训练任务：**  
   利用解析后的环境变量启动 PyTorch DDP 或其他分布式训练框架，确保程序能正确构建跨 Pod 的通信结构。

5. **验证 DNS 解析：**  
   在 Pod 内通过 `nslookup`、`dig` 等工具验证 DNS 是否正确。例如：
   ```bash
   nslookup ${JOBNAME}-0.${SVC_NAME}.${POD_NAMESPACE}.svc.cluster.local
   ```
   应返回主节点的正确 IP 地址列表。

