import kaggle
import os
from google.cloud import storage
import logging

gcp_bucket = os.getenv('GCP_CONTEXT_BUCKET')
context_data_size = os.getenv('CONTEXT_DATA_SIZE')
dataset_name = 'usman8/khaadis-clothes-data-with-images'

#  
logger = logging.getLogger(__name__)
def download_and_upload():
    
    # Download dataset
    logger.info(kaggle.api.dataset_download_files(dataset_name, path='/tmp', unzip=True))
    
    # Upload to GCP bucket
    client = storage.Client()
    bucket = client.bucket(gcp_bucket)
    
    base_path = '/tmp/Khaadi_Data'
    logger.info("Uploading the dataset to storage bucket")
    count = 0
    exit_loops=False
    for root, _, files in os.walk('/tmp/Khaadi_Data'):
        if exit_loops:
            break
        for file in files :
            if count>context_data_size:
                exit_loops = True
                break
            logger.info(f"Uploading file no {file}")
            local_path = os.path.join(root, file)
            relative_path = os.path.relpath(local_path, base_path)
            blob = bucket.blob(f'raw-dataset/{relative_path}')
            blob.upload_from_filename(local_path)
            count = count + 1

    
    return f'Dataset {dataset_name} downloaded and uploaded to GCP bucket {gcp_bucket}'