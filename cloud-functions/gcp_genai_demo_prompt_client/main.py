from predict.gcp_genai_demo_embedding_client import EmbeddingPredictionClient
from search.gcp_genai_demo_search_client import VectorSearchClient
from kafka.producer import run_producer
import os


KAFKA_TOPIC_NAME = os.environ.get("KAFKA_TOPIC_NAME")
KAFKA_API_KEY =os.environ.get("KAFKA_API_KEY")
KAFKA_API_SECRET = os.environ.get("KAFKA_API_SECRET")
INDEX_ENDPOINT=os.environ.get("INDEX_ENDPOINT")
DEPLOYED_INDEX_ID=os.environ.get("DEPLOYED_INDEX_ID")
PROJECT_ID = os.environ.get("PROJECT_ID")
REGION = os.environ.get("REGION")
BOOTSTRAP_KAFKA_SERVER = os.environ.get("BOOTSTRAP_KAFKA_SERVER")
SR_URL = os.environ.get("SR_URL")
SR_API_KEY = os.environ.get("SR_API_KEY")
SR_API_SECRET = os.environ.get("SR_API_SECRET")

SCHEMA_CONF =  {
            'url':SR_URL,
    'basic.auth.user.info':f'{SR_API_KEY}:{SR_API_SECRET}'
}

PRODUCER_CONF = {
        'bootstrap.servers': BOOTSTRAP_KAFKA_SERVER,
        'sasl.username': KAFKA_API_KEY,
        'sasl.password':KAFKA_API_SECRET
    }
embeddingPredictionClient = EmbeddingPredictionClient(PROJECT_ID,REGION)

vectorSearchClient = VectorSearchClient(PROJECT_ID,INDEX_ENDPOINT,DEPLOYED_INDEX_ID,REGION)

def invoke_prompt_client(request):
    request_json = request.get_json()
    try:
        prompt_details = request_json[0]['value']
        text = prompt_details['text']
        image_url = prompt_details['image_url']
        embeddings = embeddingPredictionClient.get_embeddings(image_url,text)
        embeddingsJson = {
            'image_embedding' :embeddings.image_embedding,
            'text_embedding':embeddings.text_embedding
            }
        matched_items = vectorSearchClient.query_vector_search(embeddings, 10)
        response_text = run_producer(matched_items,prompt_details,PRODUCER_CONF,SCHEMA_CONF,KAFKA_TOPIC_NAME)
        return response_text
    except Exception as e:
        return e
