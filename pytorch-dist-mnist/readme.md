# Distributed PyTorch Training User Guide

```
pytorch-dist-mnist
├── Dockerfile  # the example dockerfile to build the distributed training image
└── dist.py    # the example python code for distributed training
```

## Running Job

Please use the default entrypoint to start the image:
```
python dist.py
```
After the job is submitted, it should be completed within 3 minutes. 

---

## How to Set Up Cross-Node Communication in a Distributed Setting


When running distributed training jobs, several environment variables are automatically set to simplify communication across multiple nodes (processes). This guide explains these variables and how to utilize them effectively.

### Constructing Host Addresses for Communication

Nodes communicate using a unique host address format constructed from environment variables:

```markdown
SING_HOST_ADDR="${JOB_NAME}-${RANK}.${HOSTNAME_SUFFIX}"
```

This host address uniquely identifies each node within your cluster.


### Environment Variables

These environment variables can be directly used in Python scripts or shell commands:

| Variable Name     | Description                                                                           |
| ----------------- | ------------------------------------------------------------------------------------- |
| `SING_RANK`            | Unique identifier for each node within the distributed group.                         |
| `SING_WORLD_SIZE`      | Total number of nodes participating in the distributed job.                           |
| `SING_JOB_NAME`        | Name of your distributed job.                                                         |
| `SING_HOSTNAME_SUFFIX` | Automatically generated host domain suffix provided by the scheduler.                 |
| `SING_MASTER_ADDR`     | Shortcut host address for the node with rank 0 (often designated as the master node). |

> **Tip:** The only variable that differs among nodes is `SING_RANK`. All other variables remain consistent across nodes.


### Example Configuration

Consider a distributed job named `test` with two nodes and a `SING_HOSTNAME_SUFFIX` of `test-service.demo-project.svc.cluster.local`:

#### Node 0

```markdown
SING_RANK=0
SING_WORLD_SIZE=2
SING_JOB_NAME=test
SING_HOSTNAME_SUFFIX=test-service.demo-project.svc.cluster.local
SING_MASTER_ADDR=test-0.test-service.demo-project.svc.cluster.local
SING_HOST_ADDR=test-0.test-service.demo-project.svc.cluster.local
```

#### Node 1

```markdown
SING_RANK=1
SING_WORLD_SIZE=2
SING_JOB_NAME=test
SING_HOSTNAME_SUFFIX=test-service.demo-project.svc.cluster.local
SING_MASTER_ADDR=test-0.test-service.demo-project.svc.cluster.local
SING_HOST_ADDR=test-1.test-service.demo-project.svc.cluster.local
```

