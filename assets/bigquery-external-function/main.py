import functions_framework
import os


# Triggered by a change in a storage bucket
@functions_framework.cloud_event
def gcp_main(cloud_event):
    gcs_copy()
    bq_create_biglake_table()

#def gcs_copy(cloud_event):

def gcs_copy():

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

def bq_create_biglake_table():

    try:

        PROJECT_ID = os.environ.get("PROJECT_ID")
        DATASET_ID = os.environ.get("DATASET_ID")
        TABLE_NAME = os.environ.get("TABLE_NAME")

        from google.cloud import bigquery

        client = bigquery.Client()
        query_job = client.query(
            """
            CREATE EXTERNAL TABLE `PROJECT_ID.DATASET.EXTERNAL_TABLE_NAME`
            WITH CONNECTION `PROJECT_ID.REGION.CONNECTION_ID`
            OPTIONS (
                format ="TABLE_FORMAT",
                uris = ['BUCKET_PATH'[,...]],
                max_staleness = STALENESS_INTERVAL,
                metadata_cache_mode = 'CACHE_MODE'
                );
            """
        )

        results = query_job.result()  # Waits for job to complete.

    except Exception as err:
        message = "Error: " + str(err)
        print(message)

