from google.cloud import storage
import logging
logger = logging.getLogger(__name__)
def list_folder_in_bucket(bucket_name, folder_name):
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)
    folders = bucket.list_blobs(prefix=folder_name)
    folders = list(map(lambda x: str(x.public_url).replace("https://", "gs://").replace("storage.googleapis.com/",""), folders))
    logger.info(folders, len(folders))

