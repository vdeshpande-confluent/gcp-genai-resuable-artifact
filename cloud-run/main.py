import os
import uvicorn
import sys
import json
from fastapi import FastAPI,Response,Request
from pydantic import BaseModel
from typing import List ,Dict
from google.cloud import aiplatform
from vertexai.generative_models import GenerativeModel,Part
import vertexai.generative_models as generative_models
import vertexai
from google.cloud import storage
from models.model import GeminiResponse , HumanRequest


PROJECT_ID = os.environ.get("PROJECT_ID")
PORT = 8080
REGION = os.environ.get("REGION", "us-central1")
os.environ["GOOGLE_APPLICATION_CREDENTIALS"]="./service_account_key.json"
client = storage.Client()


app = FastAPI(
    title="REST API for Vertex AI",
    description="REST API for Vertex AI"
)
vertexai.init(project=PROJECT_ID, location=REGION)
model = GenerativeModel("gemini-1.0-pro-vision")



@app.get("/")
async def hello():
    return "Hello world one!"

@app.post("/recommend",response_model=GeminiResponse)
async def recommend(request: Request):
    
    try:
        json_body = await request.json()
        humanRequest = HumanRequest(prompt_id=json_body[0]["prompt_id"],prompt_text=json_body[0]["prompt_text"],session_id=json_body[0]["session_id"],
                                    prompt_image_url=json_body[0]["prompt_image_url"],product_attributes=json_body[0]["product_attributes"],
                                    product_description=json_body[0]["product_description"],product_gcs_uri=json_body[0]["product_gcs_uri"])
        content= generate_prompt(humanRequest)
        responses = model.generate_content(
        content,
        generation_config={
            "max_output_tokens": 2048,
            "temperature": 0.4,
            "top_p": 1,
            "top_k": 32
        },
        safety_settings={
            generative_models.HarmCategory.HARM_CATEGORY_HATE_SPEECH: generative_models.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            generative_models.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT: generative_models.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            generative_models.HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT: generative_models.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
            generative_models.HarmCategory.HARM_CATEGORY_HARASSMENT: generative_models.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
        },
        stream=False,
    )   
        print(responses.candidates[0].content.parts[0].text)
        gemini_response = GeminiResponse(prompt_id=humanRequest.prompt_id,prompt_text=humanRequest.prompt_text,prompt_image_url=humanRequest.prompt_image_url,generatedAnswer=responses.candidates[0].content.parts[0].text)
        print('gemini_response')
        print('run_producer')
        return gemini_response
    except Exception as e:
        error_message = "Error encounterred " + str(e)
        return GeminiResponse(generatedAnswer=str(e))   
    

def generate_prompt(humanRequest):
    try:
    
        promptContent = f"You are an expert in the clothing market. You are tasked to assist user in the following clothing related query/request. Request from User: {humanRequest.prompt_text}"
        supportingDescriptions = f"Similar Products description for hints generated from RAG pipeline: {humanRequest.product_description[0:5]}"
        supportingAttributes = f"Similar Products attributes for hints generated from RAG pipeline: {humanRequest.product_attributes[0:5]}"
        supportingImagePrompt = f"Similar Products Images for hints generated from RAG pipeline:"
        relatedImages = list(map(lambda x :  Part.from_uri(x,mime_type="image/jpeg"),humanRequest.product_gcs_uri))

        if humanRequest.prompt_image_url != "":

            prompt_image_text = f"\n User has also given you a reference image/ product image to support the task. Image:"
            prompt_image = Part.from_uri(humanRequest.prompt_image_url,mime_type="image/jpeg")    

            content = [promptContent,prompt_image_text,prompt_image,supportingDescriptions,supportingAttributes,supportingImagePrompt]
        else:
            content = [promptContent,supportingDescriptions,supportingAttributes,supportingImagePrompt]

        n = len(humanRequest.product_gcs_uri)
        for i in range(n):
            content.append(f"Gcs uri for the attached base64 image {humanRequest.product_gcs_uri[i]}")
            content.append(relatedImages[i])
        # for relatedImage in relatedImages[0:5]:
        #     content.append(relatedImage) 
            # Persona , task , step by step ,1. evaluate the  context , use the format , <template>response example</template> , <context></context> , format specification, do not use markdown 
        content.append(f"Guidelines for the product recommendation \n 1.I have given two arrays of length 5 as part of Similar Products Images context , one is gcs uri and it's corresponding base64 image . \n I want you to return me one best matched gcs uri of the image as a response \n 2. I want response to be a clothing guide which consists of clothing recommendation along with gcs uri mentioned in point 1.")
    except Exception as e:
        raise e
    return content
# gcloud auth application-default login 

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=PORT)
"""
You are an expert musical instrument technician your job is to extract for every page a description of the product depicted.

To achieve your task follow these steps:

1. Carefully analyze every page of the catalog, you will create a single entry per item presented.
2. Look at the item image and carefully read the text.
3. Annotate the results in JSON format, using the format below.
4. Always think step by step, and NEVER make up information.
<format>
```json
{
"item_name": ,
"item_type": ,
"col


"""