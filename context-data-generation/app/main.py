
import sys
import os

os.environ["APPLIED_AI_CONF"] = "conf/app.toml"

if os.path.abspath("/..") not in sys.path:
    sys.path.insert(0, os.path.abspath("/.."))

from google.cloud.ml.applied.images.image_to_text import image_to_attributes, image_to_product_description , from_gsc_uri
from google.cloud.ml.applied.model.domain_model import ImageRequest
from google.cloud.ml.applied.config import Config
from google.cloud import storage
from google.cloud import aiplatform
from contextproducer import setup_producer,run_producer
from upload_dataset import download_and_upload
import json
from pydantic import BaseModel
import logging
import time
import logging
import sys


logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)


def list_images_in_bucket(bucket_name, folder_name):
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    folders = bucket.list_blobs(prefix=folder_name)
    image_list = list(map(lambda x: str(x.public_url).replace("https://", "gs://").replace("storage.googleapis.com/",""), folders))
    return image_list

def load_image_bytes(image_uri:str):
    image_bytes = from_gsc_uri(image_uri)
    return image_bytes._image.data


class Context(object):
    def __init__(self, ProductImageIndexID, ProductDescription, ProductId, ProductImageGCSUri,ProductAttributes,ProductTextIndexID):
        self.ProductImageIndexID = ProductImageIndexID
        self.ProductDescription = ProductDescription
        self.ProductId = ProductId
        self.ProductImageGCSUri = ProductImageGCSUri
        self.ProductAttributes = ProductAttributes
        self.ProductTextIndexID = ProductTextIndexID

def run():
    
    logger.info("Downloading the dataset from kaggle")
    context_bucket = os.getenv('GCP_CONTEXT_BUCKET')
    download_and_upload()

    images = list_images_in_bucket(context_bucket, "raw-dataset/images")
    index= len(images)-1
    topic,producer,sr=setup_producer()
    
    while index>0:
        """"
        Creating the product description and product attributes from the gcs uri
        """
        try:
            logger.info(f"Genrating product attributes and description for image {index}")
            t_s = time.time()
            image_uri = images[index]
            request = ImageRequest(image=image_uri)
            result_att = image_to_attributes(request)
            result_desc = image_to_product_description(request.image)
            data = Context(ProductId=index,ProductImageIndexID=f"{index}_image",ProductTextIndexID=f"{index}_text", ProductImageGCSUri=image_uri, ProductDescription=str(result_desc), ProductAttributes=json.dumps(result_att)) 
            logger.info(f"Running producer for product no {index}")
            run_producer(topic,producer,sr,str(data.ProductId),data)
            t_e = time.time()
            if 5>t_e-t_s>0:
                d = t_e - t_s
                time.sleep(5-d)
            index = index - 1
        except Exception as e:
            logger.info("An unknown error occured:{}".format(e))
    producer.flush()

if __name__=="__main__":
    logger.info("Application started")
    run()
    logger.info("Application finished")
    
