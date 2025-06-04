# Basic RAG Service

This project implements a basic Retrieval-Augmented Generation (RAG) service that uses an external vLLM service as the large language model backend.

## Features

- Lightweight RAG implementation
- Uses Contriever as the retrieval model
- Includes preprocessed SQuAD dataset
- Supports configurable external vLLM service connection
- Supports custom models and datasets from private data paths
- Provides HTTP API interface

## Project Structure

```
rag-service/
├── Dockerfile          # Docker image build file
├── requirements.txt    # Python dependencies list
├── build.sh            # Build script
├── run.sh              # Run script
├── test.py             # Test script
└── src/                # Source code directory
    ├── main.py         # Main application
    └── rag_engine.py   # RAG engine implementation
```

## Usage

### 1. Build the Image

Execute the following command to build the Docker image:

```bash
./build.sh
```

### 2. Run the Service

Use the following command to run the service:

```bash
VLLM_HOST=localhost VLLM_PORT=8000 ./run.sh
```

Or run directly (will use default values):

```bash
./run.sh
```

### 3. Test the Service

Use the provided test script to test the service:

```bash
python test.py
```

Or test manually using curl:

```bash
# Test health check
curl http://localhost:8000/

# Test direct query
curl -X POST http://localhost:8000/query \
  -H "Content-Type: application/json" \
  -d '{"query": "What is artificial intelligence?", "max_tokens": 100}'

# Test RAG query
curl -X POST http://localhost:8000/rag \
  -H "Content-Type: application/json" \
  -d '{"query": "Who is Einstein?", "max_tokens": 100, "top_k": 3}'
```

## API Endpoints

### Health Check

```
GET /
```

Returns the service status.

### Direct Query

```
POST /query
```

Parameters:
- `query`: Query text
- `max_tokens`: (Optional) Maximum number of tokens to generate, default is 512
- `temperature`: (Optional) Generation temperature, default is 0.7
- `model`: (Optional) Model name to use, default is "facebook/opt-6.7b"

### RAG Query

```
POST /rag
```

Parameters:
- `query`: Query text
- `max_tokens`: (Optional) Maximum number of tokens to generate, default is 512
- `temperature`: (Optional) Generation temperature, default is 0.7
- `model`: (Optional) Model name to use, default is "facebook/opt-6.7b"
- `top_k`: (Optional) Number of contexts to retrieve, default is 3

## Environment Variables

- `VLLM_HOST`: vLLM service host address, default is "localhost"
- `VLLM_PORT`: vLLM service port, default is "8000"
- `SERVICE_PORT`: RAG service port, default is "3456"
- `MODEL_PATH`: Contriever model path, default is "/app/models/contriever"
- `DATA_PATH`: Dataset path, default is "/app/data/squad.json"

## Custom Data and Models

To use your own dataset, replace the `squad.json` file in the data path.
To use another embedding model, replace the contents of the `contriever` directory in the model path.

The dataset format should be compatible with the SQuAD dataset, or you need to modify the `_process_dataset` method in `rag_engine.py` to support other formats.
