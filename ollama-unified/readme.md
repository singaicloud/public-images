# Ollama Universal Container

This container provides a universal Ollama runtime environment supporting multiple 7B-sized language models.

## Supported Models

| Model Name | Ollama Library Name | Description |
|------------|-------------------|-------------|
| llama2:7b | llama2:7b | General-purpose conversational model |
| deepseek:7b | deepseek-llm:7b | Advanced language model with strong reasoning |
| codellama:7b | codellama:7b | High-performance code generation model |
| qwen:7b | qwen:7b | Versatile multilingual model |

## Usage Instructions

### Running the Container

```bash
# Run container with specified model
docker run -d -p 11434:11434 -p 22:22 \
  -e MODEL_NAME="llama2:7b" \
  -e SSH_PASSWORD="your_password" \
  --name ollama-llama2 \
  192.168.1.215:5001/ollama-unified:1.0
