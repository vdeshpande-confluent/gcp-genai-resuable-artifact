
import json
import os
from google.cloud import aiplatform
import vertexai
from vertexai.vision_models import (
    Image,
    MultiModalEmbeddingModel,
    MultiModalEmbeddingResponse,
)

def get_image_embeddings(
    project_id: str,
    location: str,
    image_path: str,
    contextual_text,
    dimension: int = 1408,
) -> MultiModalEmbeddingResponse: 
  vertexai.init(project=project_id, location=location)
  model = MultiModalEmbeddingModel.from_pretrained("multimodalembedding")
  image = Image.load_from_file(image_path)
  embeddings = model.get_embeddings(
    image=image,
    contextual_text=contextual_text
    )
    #print(f"Image Embedding: {embeddings.image_embedding}")
    #print(f"Text Embedding: {embeddings.text_embedding}")
  return embeddings


def stream_update_vector_search_index(datapoints) -> None:

  aiplatform.init(project=project_id, location=location)
  # Create the index instance from an existing index with stream_update
  my_index = aiplatform.MatchingEngineIndex(index_name=index_name)
  # Upsert the datapoints to the index
  my_index.upsert_datapoints(datapoints=datapoints)



##############################################################################################
# main

index_name=os.environ.get("INDEX_NAME")
project_id = os.environ.get("PROJECT_ID")
location = os.environ.get("REGION")


def context(request):

  request_json = request.get_json()
  
  product_details = request_json[0]['value']

  

  ProductId = product_details["ProductId"]
  image_path = product_details["ProductImageGCSUri"]
  ProductDescription = product_details["ProductDescription"]
  ProductAttributes = product_details["ProductAttributes"]
  ProductImageIndexID = product_details["ProductImageIndexID"]
  ProductTextIndexID = product_details["ProductTextIndexID"]
  
  contextual_text = "Product Description: {} Product Attributes: {}".format(ProductDescription,ProductAttributes)
  
  try:
    get_embedding_response=get_image_embeddings(
      project_id=project_id,
      location=location,
      image_path=image_path,
      contextual_text=contextual_text,
      dimension=1408
      )
    # Update Vector
    datapoints = [
    {"datapoint_id": ProductTextIndexID, "feature_vector": get_embedding_response.text_embedding},
    {"datapoint_id": ProductImageIndexID, "feature_vector": get_embedding_response.image_embedding}
    ]
    stream_update_vector_search_index(datapoints)
    return 'This is in the return {}'.format(datapoints)
  except Exception as e:
    return e
  
  

