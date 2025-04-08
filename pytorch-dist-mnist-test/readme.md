# Distributed PyTorch Training User Guide

```
pytorch-dist-mnist-test
├── Dockerfile  # the example dockerfile to build the distributed training image
└── mnist.py    # the example python code for distributed training
```

## Running Job

Please use the default entrypoint to start the image:
```
python /opt/mnist/src/mnist.py --backend nccl --run-training
```
After the job is submitted, it should be completed within 3 minutes. 

## How it works

When a distributed training job starts, several environment variables are automatically set to configure the parameters for the distributed setup.

### Constructing the Communication Address:

The following `POD_ADDR` is the communication address for each Pod (or process):

```
POD_ADDR="${JOB_NAME}-${RANK}.${SVC_NAME}.${POD_NAMESPACE}.svc.cluster.local"
```
This address is used for identifying the communication endpoints between different Pods (or processes).

#### Environment Variables used in constructing the address:

`You can use the following Environment Variables directly in your python code.`

- **`RANK`**  The rank (or ID) of the current Pod (or process) within the distributed group.

- **`POD_NAMESPACE`**  The username of User.

- **`SVC_NAME`**  The service name for the job.

- **`JOB_NAME`**  The name of the current job.

##### Other Environment Variables:

- **`WORLD_SIZE`**  The total number of Pods (or processes) involved in the distributed training.

- **`MASTER_ADDR`**  The address of the master pod (rank 0 pod).

#### Example:

Assume that we submit a job named `test`, use `2 pods`, and the username is `demo-project`, then the environment variables mentioned below are:

```
For pod 0: 
RANK = 0
WORLD_SIZE = 2
JOB_NAME = test
SVC_NAME = test-service
MASTER_ADDR = test-0.test-service.demo-project.svc.cluster.local
POD_ADDR = test-0.test-service.demo-project.svc.cluster.local

For pod 1: 
RANK = 1
WORLD_SIZE = 2
JOB_NAME = test
SVC_NAME = test-service
MASTER_ADDR = test-0.test-service.demo-project.svc.cluster.local
POD_ADDR = test-1.test-service.demo-project.svc.cluster.local
```

### Communication Mechanism:

The **`MASTER_ADDR`** points to the "master" pod (rank 0 pod) for some communication frameworks. In peer-to-peer configurations or other communication strategies, each process might have the information of all other processes, and communication can occur between all processes without relying on a single master pod.

To find the addresses of other processes, each pod can use the **`POD_ADDR`** format to identify other participants based on their rank and job name. The rank is used as a unique identifier for each process, and each rank knows how to address other processes through their respective addresses, which are constructed based on the environment variables.