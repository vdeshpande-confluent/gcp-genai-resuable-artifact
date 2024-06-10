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
    

 