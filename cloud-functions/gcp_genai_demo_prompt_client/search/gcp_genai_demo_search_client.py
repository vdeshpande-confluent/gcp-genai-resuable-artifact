from google.cloud import aiplatform

class VectorSearchClient:

    def __init__(
        self,
        project_id: str,
        index_endpoint:str,
        deployed_index_id:str,
        location: str = "us-central1"
    ):

        self.location = location
        self.project_id = project_id
        self.INDEX_ENDPOINT=index_endpoint
        self.DEPLOYED_INDEX_ID = deployed_index_id
        aiplatform.init(project=project_id, location=location)

    def query_vector_search(self,embeddings,num_neighbors):
        my_index_endpoint = aiplatform.MatchingEngineIndexEndpoint(
        index_endpoint_name=self.INDEX_ENDPOINT
        )
        query = [embeddings.text_embedding,embeddings.image_embedding]
        # Query the index endpoint for the nearest neighbors.
        resp = my_index_endpoint.find_neighbors(
            deployed_index_id=self.DEPLOYED_INDEX_ID,
            queries=query,
            num_neighbors=num_neighbors,
            return_full_datapoint=True,
        )
        print(resp[0])
        return resp
    

#     KAFKA_TOPIC_URL = 'https://pkc-n3603.us-central1.gcp.confluent.cloud:443/kafka/v3/clusters/lkc-z62yw7/topics/gcp_genai_demo_prompt_embedding/records'
# KAFKA_API_KEY = "OQIHQU2ZB73IPGB7"
# KAFKA_API_SECRET = "sz3W4e5ATxB23Hl5SlDfN67FBrzsDO2tSyYwkxf6qV0sl68EN7lMn3pssA/v2Hrc"
# INDEX_ENDPOINT="projects/92466927170/locations/us-central1/indexEndpoints/7431471548789161984"
# # DEPLOYED_INDEX_ID="gcp_genai_demo_vector_1709930174451"
# PROJECT_ID=sales-engineering-206314
# REGION=us-central1