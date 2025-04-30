# Beginner's Guide to Distributed PyTorch Training

This guide will help you run machine learning tasks across multiple computers (nodes) using PyTorch, even if you're new to distributed training!

## What's Included

```
pytorch-dist-mnist
├── Dockerfile  # Recipe for building the training environment
└── dist.py     # Example code that shows how to train across multiple nodes
```

## Getting Started

Running this example is simple! Choose the `pytorch-dist-mnist` image from the `Create Job` page and use the default entrypoint to start the image:
```
python dist.py
```

The training process should finish shortly after submission. You can check the logs after job completion.

---

## Understanding Multi-Node Communication

### What is Distributed Training?

Distributed training lets you split your machine learning workload across multiple computers (or nodes) to train models faster. SING Cloud automatically sets up several helpful environment variables to make this easier.

### How Nodes Talk to Each Other

Each node has a unique address that follows this pattern:

```
SING_HOST_ADDR="${SING_JOB_NAME}-${SING_RANK}.${SING_HOSTNAME_SUFFIX}"
```

This host address uniquely identifies each node within your cluster.

### Important Environment Variables Explained

These variables are automatically set up for you and can be used in your code:

| Variable Name | What It Does |
|---------------|--------------|
| `SING_RANK` | Unique identifier for each node within the distributed group (starting from 0) |
| `SING_WORLD_SIZE` | Total number of nodes participating in your training job |
| `SING_JOB_NAME` | Name of your distributed job |
| `SING_HOSTNAME_SUFFIX` | Automatically generated host domain suffix provided by the scheduler. |
| `SING_MASTER_ADDR` | Shortcut host address for the node with rank 0 (often designated as the master node). |

> **Helpful Tip:** Among these variables, only `SING_RANK` is different for each node. All other variables stay the same across all nodes.

### Example: A Two-Node Training Job

Let's look at how this works with a real example. If you run a job named `test` with two nodes:

Consider a distributed job named `test` with two nodes and a `SING_HOSTNAME_SUFFIX` of `test-service.demo-project.svc.cluster.local`:
#### Master Node (Node 0)

```
SING_RANK=0
SING_WORLD_SIZE=2
SING_JOB_NAME=test
SING_HOSTNAME_SUFFIX=test-service.demo-project.svc.cluster.local
SING_MASTER_ADDR=test-0.test-service.demo-project.svc.cluster.local
SING_HOST_ADDR=test-0.test-service.demo-project.svc.cluster.local
```

#### Worker Node (Node 1)

```
SING_RANK=1
SING_WORLD_SIZE=2
SING_JOB_NAME=test
SING_HOSTNAME_SUFFIX=test-service.demo-project.svc.cluster.local
SING_MASTER_ADDR=test-0.test-service.demo-project.svc.cluster.local
SING_HOST_ADDR=test-1.test-service.demo-project.svc.cluster.local
```

