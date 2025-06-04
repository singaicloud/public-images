import json
import logging
import numpy as np
from typing import List, Dict, Any
from transformers import AutoTokenizer, AutoModel
import torch
from tqdm import tqdm

logger = logging.getLogger(__name__)

class RAGEngine:
    def __init__(self, model_path: str, data_path: str):
        """
        Initialize RAG engine
        
        Args:
            model_path: Path to the Contriever model
            data_path: Path to the dataset
        """
        logger.info(f"Initializing RAG engine, loading model: {model_path}")
        self.device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info(f"Using device: {self.device}")
        
        # Load model and tokenizer
        self.tokenizer = AutoTokenizer.from_pretrained(model_path)
        self.model = AutoModel.from_pretrained(model_path).to(self.device)
        
        # Load and process data
        self.documents, self.embeddings = self._process_dataset(data_path)
        logger.info(f"Successfully loaded {len(self.documents)} documents")
    
    def _process_dataset(self, data_path: str) -> tuple:
        """Process dataset and create document embeddings"""
        logger.info(f"Processing dataset: {data_path}")
        
        # Load SQuAD dataset
        with open(data_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        documents = []
        
        # Extract paragraphs from SQuAD dataset
        for article in data['data']:
            title = article.get('title', '')
            for paragraph in article['paragraphs']:
                context = paragraph['context']
                # Create a document for each paragraph
                documents.append({
                    'id': len(documents),
                    'title': title,
                    'text': context
                })
        
        # Process only the first 10 documents to keep image size reasonable
        documents = documents[:10]
        logger.info(f"Generating embedding vectors (total {len(documents)} documents)")
        
        # Calculate document embeddings
        embeddings = []
        batch_size = 16
        
        for i in tqdm(range(0, len(documents), batch_size)):
            batch_docs = documents[i:i+batch_size]
            batch_texts = [doc['text'] for doc in batch_docs]
            
            # Encode text
            inputs = self.tokenizer(
                batch_texts, 
                max_length=512, 
                padding=True, 
                truncation=True, 
                return_tensors="pt"
            ).to(self.device)
            
            # Calculate embeddings
            with torch.no_grad():
                outputs = self.model(**inputs)
                
            # Use [CLS] embedding as document embedding
            batch_embeddings = outputs.last_hidden_state[:, 0, :].cpu().numpy()
            embeddings.extend(batch_embeddings)
        
        # Convert to numpy array for fast retrieval
        embeddings = np.vstack(embeddings)
        
        return documents, embeddings
    
    def _get_query_embedding(self, query: str) -> np.ndarray:
        """Calculate query embedding"""
        inputs = self.tokenizer(
            query, 
            max_length=512, 
            padding=True, 
            truncation=True, 
            return_tensors="pt"
        ).to(self.device)
        
        with torch.no_grad():
            outputs = self.model(**inputs)
        
        # Use [CLS] embedding as query embedding
        query_embedding = outputs.last_hidden_state[:, 0, :].cpu().numpy()
        return query_embedding
    
    def retrieve(self, query: str, k: int = 3) -> List[str]:
        """Retrieve relevant documents based on query"""
        # Calculate query embedding
        query_embedding = self._get_query_embedding(query)
        
        # Calculate cosine similarity
        scores = np.dot(self.embeddings, query_embedding.T).flatten()
        
        # Get top k relevant documents
        top_indices = np.argsort(scores)[::-1][:k]
        
        # Return relevant document texts
        contexts = [self.documents[idx]['text'] for idx in top_indices]
        return contexts
