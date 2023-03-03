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
        from google.cloud import bigquery

        PROJECT_ID = os.environ.get("PROJECT_ID")
        DATASET_ID = os.environ.get("DATASET_ID")
        TABLE_NAME = os.environ.get("TABLE_NAME")
        REGION = os.environ.get("TABLE_NAME")
        CONN_NAME = os.environ.get("CONN_NAME")

        client = bigquery.Client(project=PROJECT_ID)

        s = """
            CREATE EXTERNAL TABLE `{}.{}.{}`
            WITH CONNECTION `{}.{}.{}`
            OPTIONS (
            format ="PARQUET",
            uris = ["gs://da-solutions-assets-1484658051840/thelook_ecommerce/orders-*.Parquet"],
            max_staleness = INTERVAL 30 MINUTE,
            metadata_cache_mode = 'AUTOMATIC')
        """.format(PROJECT_ID,DATASET_ID, TABLE_NAME, PROJECT_ID,REGION, CONN_NAME )

        query_job = client.query(s)

    except Exception as err:
        message = "Error: " + str(err)
        print(message)

