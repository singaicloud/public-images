#!/usr/bin/env python3
"""
RAG Service Test Script
Used to test if the RAG service is functioning properly
"""

import requests
import json
import sys
import argparse

def test_health(base_url):
    """Test the health check endpoint"""
    try:
        response = requests.get(f"{base_url}/")
        if response.status_code == 200:
            print("✅ Health check endpoint test passed")
            print(f"   Response: {response.json()}")
            return True
        else:
            print(f"❌ Health check endpoint test failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Health check endpoint test error: {str(e)}")
        return False

def test_direct_query(base_url):
    """Test the direct query endpoint"""
    payload = {
        "query": "What is artificial intelligence?",
        "max_tokens": 100,
        "temperature": 0.7
    }
    
    try:
        print("Testing direct query endpoint...")
        response = requests.post(f"{base_url}/query", json=payload)
        if response.status_code == 200:
            print("✅ Direct query endpoint test passed")
            result = response.json()
            print(f"   Query: {payload['query']}")
            print(f"   Response content snippet: {result['choices'][0]['text'][:100]}...")
            return True
        else:
            print(f"❌ Direct query endpoint test failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Direct query endpoint test error: {str(e)}")
        return False

def test_rag_query(base_url):
    """Test the RAG query endpoint"""
    payload = {
        "query": "Who is Einstein?",
        "max_tokens": 100,
        "temperature": 0.7,
        "top_k": 2
    }
    
    try:
        print("Testing RAG query endpoint...")
        response = requests.post(f"{base_url}/rag", json=payload)
        if response.status_code == 200:
            print("✅ RAG query endpoint test passed")
            result = response.json()
            print(f"   Query: {payload['query']}")
            print(f"   Number of retrieved contexts: {len(result['contexts'])}")
            print(f"   Response content snippet: {result['llm_response']['choices'][0]['text'][:100]}...")
            return True
        else:
            print(f"❌ RAG query endpoint test failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"❌ RAG query endpoint test error: {str(e)}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Test RAG service')
    parser.add_argument('--host', default='localhost', help='RAG service hostname')
    parser.add_argument('--port', default=8000, type=int, help='RAG service port')
    
    args = parser.parse_args()
    base_url = f"http://{args.host}:{args.port}"
    
    print(f"Starting RAG service test: {base_url}")
    
    # Test health check
    if not test_health(base_url):
        print("Health check failed, terminating test")
        sys.exit(1)
    
    # Test direct query
    test_direct_query(base_url)
    
    # Test RAG query
    test_rag_query(base_url)
    
    print("Testing complete!")

if __name__ == "__main__":
    main()
