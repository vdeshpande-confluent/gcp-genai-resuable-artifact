from pydantic import BaseModel
from typing import List ,Dict

class HumanRequest(BaseModel):
    prompt_id: str
    prompt_text: str | None = None
    prompt_image_url: str 
    session_id: int | None = None
    product_description: List[str]
    product_gcs_uri: List[str]
    product_attributes:List[str]


class GeminiResponse(BaseModel):
    prompt_id: str | None = None
    prompt_text: str | None = None
    prompt_image_url: str | None = None
    generatedAnswer: str