import functions_framework
import os


# Triggered by a change in a storage bucket
@functions_framework.cloud_event
def gcs_copy(cloud_event):

    try:
        DESTINATION_BUCKET_ID = os.environ.get("DESTINATION_BUCKET_ID")
        SOURCE_BUCKET_ID = os.environ.get("SOURCE_BUCKET_ID")
        from google.cloud import storage

        storage_client = storage.Client()

        source_bucket = storage_client.bucket(SOURCE_BUCKET_ID)
        destination_bucket = storage_client.bucket(DESTINATION_BUCKET_ID)

        blobs = storage_client.list_blobs(SOURCE_BUCKET_ID)

        blob_list = []
        for blob in blobs:
            blob_list.append(blob.name)

        for blob in blob_list:
            source_blob = source_bucket.blob(blob)

            source_bucket.copy_blob(
                source_blob, destination_bucket, blob,
            )
    except Exception as err:
        message = "Error: " + str(err)
        print(message)
