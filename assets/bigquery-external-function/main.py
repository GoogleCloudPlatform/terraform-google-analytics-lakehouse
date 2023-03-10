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
        DESTINATION_BUCKET_ID = "gcp-lakehouse-edw-export-" + os.environ.get("PROJECT_ID") #os.environ.get("DESTINATION_BUCKET_ID")
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

def call_workflow():

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


def create_gcp_view_ecommerce():

  try:
    from google.cloud import bigquery

    client = bigquery.Client(project=os.environ.get("PROJECT_ID"))

    sql = """
            CREATE OR REPLACE VIEW `gcp_lakehouse_ds.gcp_view_ecommerce` AS 
            SELECT
            o.order_id, o.user_id order_user_id, o.status order_status,  o.created_at order_created_at, o.returned_at order_returned_at,
            o.shipped_at order_shipped_at, o.delivered_at order_delivered_at, o.num_of_item order_number_of_items, i.id AS order_items_id,
            i.product_id AS order_items_product_id, i.status order_items_status, i.sale_price order_items_sale_price, p.id AS product_id,
            p.cost product_cost, p.category product_category, p.name product_name,p.brand product_brand, p.retail_price product_retail_price,
            p.department product_department, p.sku product_sku, p.distribution_center_id, d.name AS dist_center_name,
            d.latitude dist_center_lat, d.longitude dist_center_long, u.id AS user_id, u.first_name user_first_name, u.last_name user_last_name,
            u.age user_age, u.gender user_gender, u.state user_state,  u.postal_code user_postal_code, u.city user_city, u.country user_country,                                        u.latitude user_lat,                                        u.longitude user_long,
            u.traffic_source user_traffic_source
            FROM
                gcp_lakehouse_ds.gcp_tbl_orders o
            INNER JOIN
                gcp_lakehouse_ds.gcp_tbl_order_items i
            ON
                o.order_id = i.order_id
            INNER JOIN
                `gcp_lakehouse_ds.gcp_tbl_products` p
            ON
                i.product_id = p.id
            INNER JOIN
                `gcp_lakehouse_ds.gcp_tbl_distribution_centers` d
            ON
                p.distribution_center_id = d.id
            INNER JOIN
                `gcp_lakehouse_ds.gcp_tbl_users` u
            ON
                o.user_id = u.id";
        """

    query_job = client.query(sql)
    results = query_job.result()
  except Exception as e:
    if str(e).lower().find('409 already exists') >= 0:
        pass    
    else:
        raise Exception(str(e))


