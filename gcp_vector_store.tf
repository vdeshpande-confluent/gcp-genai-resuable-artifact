# resource "google_vertex_ai_endpoint" "endpoint" {
#   name         = "${var.identifier}-endpoint"
#   display_name = "${var.identifier}-endpoint"
#   description  = "A sample vertex endpoint"
#   location     = "us-central1"
#   region       = "us-central1"
# }

resource "google_storage_bucket" "bucket" {
  name     = "${var.identifier}-index-bucket"
  location = "us-central1"
  uniform_bucket_level_access = true
}


resource "google_vertex_ai_index" "index" {
  region   = "us-central1"
  display_name = "${var.identifier}-index"
  description = "index for test"
  
  metadata {
    contents_delta_uri = "gs://${google_storage_bucket.bucket.name}/contents"
    config {
      
      dimensions = 1408
      approximate_neighbors_count = 20
      shard_size = "SHARD_SIZE_MEDIUM"
      distance_measure_type = "DOT_PRODUCT_DISTANCE"
      algorithm_config {
        tree_ah_config {
          leaf_node_embedding_count = 1000
          leaf_nodes_to_search_percent = 5
        }
      }
    }
  }
  
  index_update_method = "STREAM_UPDATE"
}

# Define Vertex AI Index Endpoint
resource "google_vertex_ai_index_endpoint" "index_endpoint" {

  display_name = "${var.identifier}-endpoint"
  description  = "A sample vertex endpoint"
  region       = "us-central1"
  
  public_endpoint_enabled = true
  
}

# Deploy the Vertex AI Index to the Endpoint using gcloud
resource "null_resource" "deploy_index" {
  provisioner "local-exec" {
    command = <<EOT
    gcloud ai index-endpoints deploy-index ${google_vertex_ai_index_endpoint.index_endpoint.id} --deployed-index-id=gcp_genai_demo_deployed_index --display-name=DEPLOYED_INDEX_ENDPOINT_NAME  --index=${google_vertex_ai_index.index.id} --region=${google_vertex_ai_index.index.region} --project=${data.external.env_vars.result.PROJECT_ID}
    EOT
  }
  
  # Ensure the null_resource runs after the endpoint is created
  depends_on = [
    google_vertex_ai_index.index,
    google_vertex_ai_index_endpoint.index_endpoint
  ]
}