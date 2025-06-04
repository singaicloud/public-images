import os
import json
import logging
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
import uvicorn
from rag_engine import RAGEngine

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Get environment variables with strict checking
VLLM_HOST = os.getenv("VLLM_HOST", "localhost")
if not VLLM_HOST:
    VLLM_HOST = "localhost"  # Hardcoded default value
    
VLLM_PORT = os.getenv("VLLM_PORT", "8000")
if not VLLM_PORT:
    VLLM_PORT = "8000"  # Hardcoded default value

# Ensure URL is correctly formatted
VLLM_URL = f"http://{VLLM_HOST}:{VLLM_PORT}/v1/completions"
logger.info(f"Using vLLM service URL: {VLLM_URL}")

# Initialize FastAPI application
app = FastAPI(title="RAG Service")

# Initialize RAG engine
rag_engine = RAGEngine(
    model_path="/app/models/contriever",
    data_path="/app/data/squad.json"
)

class QueryRequest(BaseModel):
    query: str
    max_tokens: int = 512
    temperature: float = 0.7
    model: str = "facebook/opt-6.7b"  # Default model, can be overridden by request

class RAGRequest(BaseModel):
    query: str
    max_tokens: int = 512
    temperature: float = 0.7
    model: str = "facebook/opt-6.7b"
    top_k: int = 3

@app.get("/")
async def health_check():
    return {"status": "healthy", "service": "RAG"}

@app.post("/query")
async def query(request: QueryRequest):
    """Direct query to LLM without RAG functionality"""
    try:
        # Prepare request
        payload = {
            "model": request.model,
            "prompt": request.query,
            "max_tokens": request.max_tokens,
            "temperature": request.temperature
        }
        
        # Send request to vLLM service
        async with httpx.AsyncClient() as client:
            response = await client.post(
                VLLM_URL,
                json=payload,
                timeout=60.0
            )
            
        # Check if successful
        if response.status_code != 200:
            logger.error(f"vLLM service response error: {response.status_code} - {response.text}")
            raise HTTPException(status_code=500, detail="vLLM service response error")
            
        # Parse result
        result = response.json()
        return result
        
    except Exception as e:
        logger.error(f"Error during query processing: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Service error: {str(e)}")

@app.post("/rag")
async def rag_query(request: RAGRequest):
    """Query LLM with RAG enhancement"""
    try:
        # Get relevant contexts
        contexts = rag_engine.retrieve(request.query, k=request.top_k)
        context_str = "\n".join(contexts)
        
        # Build RAG prompt
        rag_prompt = f"""Answer the question using the following information:

Context information:
{context_str}

Question: {request.query}
Answer:"""
        
        # Prepare request
        payload = {
            "model": request.model,
            "prompt": rag_prompt,
            "max_tokens": request.max_tokens,
            "temperature": request.temperature
        }
        
        # Send request to vLLM service
        async with httpx.AsyncClient() as client:
            response = await client.post(
                VLLM_URL,
                json=payload,
                timeout=60.0
            )
            
        # Check if successful
        if response.status_code != 200:
            logger.error(f"vLLM service response error: {response.status_code} - {response.text}")
            raise HTTPException(status_code=500, detail="vLLM service response error")
            
        # Parse result
        llm_result = response.json()
        
        # Add RAG information
        result = {
            "llm_response": llm_result,
            "contexts": contexts[:request.top_k],
            "query": request.query
        }
        
        return result
        
    except Exception as e:
        logger.error(f"Error during RAG query processing: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Service error: {str(e)}")

if __name__ == "__main__":
    import os
    service_port = int(os.getenv("SERVICE_PORT", "3456"))
    logger.info(f"Starting RAG service, connecting to vLLM service: {VLLM_URL}")
    uvicorn.run(app, host="0.0.0.0", port=service_port)
