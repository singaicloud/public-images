# SingAI Public Images Repository

## 📦 What are Public Images?

Images are pre-configured computing environments that include various software tools, libraries, and frameworks. By using these images, you can start working immediately without having to configure complex environments yourself.

## 🧰 Available Public Images

This repository provides various pre-configured public images suitable for different AI and machine learning tasks:

### Large Language Models (LLM)

- **codellama-7b**: Code Llama 7B parameter model, ideal for code generation tasks
- **deepseek-7b**: DeepSeek 7B parameter model, bilingual Chinese-English large model
- **llama2-7b**: Meta's Llama2 7B parameter model
- **qwen-7b**: Qwen 7B parameter model, supporting both Chinese and English.

### Frameworks and Tools

- **ollama-unified**: Ollama environment integrating multiple open-source models
- **pytorch-dist-mnist**: Example environment for learning distributed PyTorch training
- **vllm**: A fast and efficient LLM inference engine

## 🚀 How to Use These Images

1. **Log in to the platform**: Visit [SingAI Cloud Computing Platform](https://my.singaicloud.com)
2. **Create a task**: Select the desired image on the "Launch Task" page
3. **Configure resources**: Choose appropriate GPU types and quantities based on task requirements
4. **Start using**: After the task launches, you can connect via SSH or web terminal

## 🔍 Detailed Image Information

Each image directory contains a detailed README file including:
- Software and versions included in the image
- Usage examples and commands
- Specific configuration instructions

For example, check [pytorch-dist-mnist/readme.md](pytorch-dist-mnist/readme.md) to learn about distributed training examples.

## 📝 Important Notes

- All images have SSH service enabled by default, accessible via platform-assigned ports
- Each image will mount the `/private_data` directory to save your private data.
- After a task ends, storage within the container will be cleared, so please save important data to your `/private_data` directory