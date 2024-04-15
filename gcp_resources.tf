#Create a service account
resource "google_service_account" "gcp_genai_demo_service_account" {
  account_id   = "${var.identifier}-service-account"
  display_name = "${var.identifier}-service-account"
}

output "service_account_email" {
  value = google_service_account.gcp_genai_demo_service_account.email
}

# # Assign roles to the service account
resource "google_project_iam_binding" "assign_roles" {
  project = data.external.env_vars.result.PROJECT_ID
  members = ["serviceAccount:${google_service_account.gcp_genai_demo_service_account.email}"]

  role = "roles/artifactregistry.writer"
}

resource "google_project_iam_binding" "cloud_functions_admin" {
  project = data.external.env_vars.result.PROJECT_ID
  members = ["serviceAccount:${google_service_account.gcp_genai_demo_service_account.email}"]

  role = "roles/cloudfunctions.admin"
}


resource "google_project_iam_binding" "logs_writer" {
  project = data.external.env_vars.result.PROJECT_ID
  members = ["serviceAccount:${google_service_account.gcp_genai_demo_service_account.email}"]

  role = "roles/logging.logWriter"
}
resource "google_project_iam_binding" "container_writer" {
  project = data.external.env_vars.result.PROJECT_ID
  members = ["serviceAccount:${google_service_account.gcp_genai_demo_service_account.email}"]

  role = "roles/artifactregistry.repoAdmin"
}


resource "google_project_iam_binding" "storage_object_admin" {
  project = data.external.env_vars.result.PROJECT_ID
  members = ["serviceAccount:${google_service_account.gcp_genai_demo_service_account.email}"]

  role = "roles/storage.objectAdmin"
}

resource "google_project_iam_binding" "storage_admin" {
  project = data.external.env_vars.result.PROJECT_ID
  members = ["serviceAccount:${google_service_account.gcp_genai_demo_service_account.email}"]

  role = "roles/storage.admin"
}

resource "google_project_iam_binding" "vertex_ai_user" {
  project = data.external.env_vars.result.PROJECT_ID
  members = ["serviceAccount:${google_service_account.gcp_genai_demo_service_account.email}"]

  role = "roles/aiplatform.user"
}


resource "google_service_account_key" "gcp_genai_demo_service_account_key" {
  service_account_id = google_service_account.gcp_genai_demo_service_account.name
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

resource "local_file" "service_account_key_json" {
  content  = base64decode(google_service_account_key.gcp_genai_demo_service_account_key.private_key)
  filename = "./credentials/service_account_key.json"
}

resource "local_file" "cloud_run_service_account_key_json" {
  content  = base64decode(google_service_account_key.gcp_genai_demo_service_account_key.private_key)
  filename = "./cloud-run/service_account_key.json"
}




#Create a code storage bucket
resource "google_storage_bucket" "code_bucket" {
  name = "${var.identifier}_code_bucket" 
  location = "us-central1"
}

# Zip the prompt folder
resource "archive_file" "prompt_folder_zip" {
  type        = "zip"
  source_dir  = "${path.module}/cloud-functions/gcp_genai_demo_prompt_client"
  output_path = "${path.module}/prompt.zip"
}


# Zip the context folder
resource "archive_file" "context_folder_zip" {
  type        = "zip"
  source_dir  = "${path.module}/cloud-functions/gcp_genai_demo_context_client"
  output_path = "${path.module}/context.zip"
}

# Upload the zip file to GCS bucket
resource "google_storage_bucket_object" "prompt_zip" {
  name   = "prompt.zip"
  bucket = resource.google_storage_bucket.code_bucket.name
  source = archive_file.prompt_folder_zip.output_path
}

# Upload the zip file to GCS bucket
resource "google_storage_bucket_object" "context_zip" {
  name   = "context.zip"
  bucket = resource.google_storage_bucket.code_bucket.name
  source = archive_file.context_folder_zip.output_path
}


# Cloud Function 1
resource "google_cloudfunctions_function" "prompt" {
  name        = "${var.identifier}-prompt-client"  
  description = "Prompt Function"
  runtime     = "python39"
  source_archive_bucket = "${var.identifier}_code_bucket"
  source_archive_object = google_storage_bucket_object.prompt_zip.name
  entry_point = "invoke_prompt_client"
  service_account_email = google_service_account.gcp_genai_demo_service_account.email
  trigger_http = true
  environment_variables = {
    "REGION" = data.external.env_vars.result.REGION
    "PROJECT_ID" = data.external.env_vars.result.PROJECT_ID
    "INDEX_ENDPOINT" = data.external.env_vars.result.INDEX_ENDPOINT
    "DEPLOYED_INDEX_ID"= data.external.env_vars.result.DEPLOYED_INDEX_ID
    "KAFKA_TOPIC_NAME" = confluent_kafka_topic.gcp_genai_demo_prompt_embedding.topic_name
    "KAFKA_API_KEY" = confluent_api_key.app-manager-kafka-api-key.id
    "KAFKA_API_SECRET" = confluent_api_key.app-manager-kafka-api-key.secret
    "BOOTSTRAP_KAFKA_SERVER"= data.confluent_kafka_cluster.cc_kafka_cluster.bootstrap_endpoint
    "SR_URL" = data.confluent_schema_registry_cluster.cc_sr_cluster.rest_endpoint
    "SR_API_KEY" = confluent_api_key.app-manager-schema-api-key.id
    "SR_API_SECRET" = confluent_api_key.app-manager-schema-api-key.secret
   }
}

# # Cloud Function 2
resource "google_cloudfunctions_function" "context" {
  name        = "${var.identifier}-context-client"
  description = "Context Function"
  runtime     = "python39"
  source_archive_bucket = "${var.identifier}_code_bucket"
  source_archive_object = google_storage_bucket_object.context_zip.name
  entry_point = "context" 
  service_account_email = google_service_account.gcp_genai_demo_service_account.email
  trigger_http = true
  environment_variables = {
    "INDEX_NAME" = data.external.env_vars.result.INDEX_NAME
    "REGION" = data.external.env_vars.result.REGION
    "PROJECT_ID" = data.external.env_vars.result.PROJECT_ID
  }
}

resource "null_resource" "build_and_push_container" {
  # triggers = {
  #   # This will force the execution of the provisioners on every apply
  #   always_run = "${timestamp()}"
  # }

  # Execute local command to build the Docker container
  provisioner "local-exec" {
    command = "docker buildx build --platform linux/amd64 -t gcr.io/${data.external.env_vars.result.PROJECT_ID}/${var.identifier}-repo ./cloud-run"
  }



  # Execute local command to push the Docker container to GCR
  provisioner "local-exec" {
    command = "docker push gcr.io/${data.external.env_vars.result.PROJECT_ID}/${var.identifier}-repo:latest"
  }

  depends_on = [ local_file.cloud_run_service_account_key_json ]


}


# Cloud Run Service
resource "google_cloud_run_service" "genai_run_service" {
  name     = "${var.identifier}-cloud-run-service"
  location = "us-central1"
  traffic {
    percent         = 100
    latest_revision = true
  }
  template {
    spec {
      containers {
        image = "gcr.io/${data.external.env_vars.result.PROJECT_ID}/${var.identifier}-repo:latest"
        env {
          name = "PROJECT_ID"
          value = "sales-engineering-206314"
        }
      }
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}
# Enable public access on Cloud Run service
resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.genai_run_service.location
  project     = google_cloud_run_service.genai_run_service.project
  service     = google_cloud_run_service.genai_run_service.name
  policy_data = data.google_iam_policy.noauth.policy_data
}
# Return service URL
output "url" {
  value = "${google_cloud_run_service.genai_run_service.status[0].url}"
}





















# Cloud Run Service
# resource "google_cloud_run_service" "genai_run_service" {
#   name     = "${var.identifier}-cloud-run-service"
#   location = "us-central1"

#   template {
#     spec {
#       containers {
#         image = "gcr.io/${data.external.env_vars.result.PROJECT_ID}/webapp"
#       }
#     }
#   }
# }



# Build and push Docker image to Google Container Registry
# resource "google_container_build_trigger" "my_build_trigger" {
#   name         = "my-build-trigger"
#   description  = "Build trigger for FastAPI application"
#   project      = data.external.env_vars.result.PROJECT_ID
#   trigger_template {
#     branch_name = "main"
#     repo_name   = "your-repo-name"
#   }
#   filename = "Dockerfile"
#   included_files = [
#     "main.py",  # Example files to include
#     "requirements.txt"
#   ]
# }

# # # Cloud Run Service
# # resource "google_cloud_run_service" "my_service" {
# #   name     = "my-service"
# #   location = "us-central1"

# #   template {
# #     spec {
# #       containers {
# #         image = "${google_container_registry_docker_image.my_image.image_url}"
# #       }
# #     }
# #   }
# # }





# """

# $ docker build -t gcr.io/terraform-cr/webapp .
# $ docker push gcr.io/terraform-cr/webapp
# """