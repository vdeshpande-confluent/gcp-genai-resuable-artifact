from typing import Optional
import vertexai
from vertexai.vision_models import (
    Image,
    MultiModalEmbeddingModel,
    MultiModalEmbeddingResponse,
)


class EmbeddingPredictionClient:

    def __init__(self,project_id: str,location: str = "us-central1"):
        
        self.location = location
        self.project_id = project_id
        vertexai.init(project=self.project_id, location=self.location)

    def get_embeddings(self,image_file_path: str,contextual_text:str) -> MultiModalEmbeddingResponse:
        if not contextual_text and not image_file_path:
                raise ValueError("At least one of text or image_file must be specified.")

        model = MultiModalEmbeddingModel.from_pretrained("multimodalembedding@001")
        image = Image.load_from_file(image_file_path)
        embeddings = model.get_embeddings(
            image=image,
            contextual_text=contextual_text
        )
        return embeddings