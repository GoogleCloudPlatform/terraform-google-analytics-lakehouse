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
        DESTINATION_BUCKET_ID = "gcp-lakehouse-edw-export" #os.environ.get("DESTINATION_BUCKET_ID")
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
        import time

        from google.cloud import workflows_v1beta
        from google.cloud.workflows import executions_v1beta
        from google.cloud.workflows.executions_v1beta.types import executions

        project = os.environ.get("PROJECT_ID")
        location = os.environ.get("REGION")
        workflow = "workflow-create-gcp-biglake-tables"

        if not project:
            raise Exception('GOOGLE_CLOUD_PROJECT env var is required.')

        execution_client = executions_v1beta.ExecutionsClient()
        workflows_client = workflows_v1beta.WorkflowsClient()

        parent = workflows_client.workflow_path(project, location, workflow)

        response = execution_client.create_execution(request={"parent": parent})
        print(f"Created execution: {response.name}")

        # Wait for execution to finish, then print results.
        execution_finished = False
        backoff_delay = 1  # Start wait with delay of 1 second
        print('Poll every second for result...')
        while (not execution_finished):
            execution = execution_client.get_execution(request={"name": response.name})
            execution_finished = execution.state != executions.Execution.State.ACTIVE

            # If we haven't seen the result yet, wait a second.
            if not execution_finished:
                print('- Waiting for results...')
                time.sleep(backoff_delay)
                backoff_delay *= 2  # Double the delay to provide exponential backoff.
            else:
                print(f'Execution finished with state: {execution.state.name}')
                print(execution.result)
                return execution.result
            
    except Exception as err:
        message = "Error: " + str(err)
        print(message)

