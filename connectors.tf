# --------------------------------------------------------
# Service Accounts (Connectors)
# --------------------------------------------------------
resource "confluent_service_account" "connectors" {
  display_name = "connectors-${random_id.id.hex}"
  description  = local.description
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Access Control List (ACL)
# --------------------------------------------------------
resource "confluent_kafka_acl" "connectors_source_describe_cluster" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  resource_type = "CLUSTER"
  resource_name = "kafka-cluster"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.connectors.id}"
  operation     = "DESCRIBE"
  permission    = "ALLOW"
  host          = "*"
  rest_endpoint = data.confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}
# Demo topics
resource "confluent_kafka_acl" "connectors_source_create_topic_demo" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.connectors.id}"
  operation     = "CREATE"
  permission    = "ALLOW"
  host          = "*"
  rest_endpoint = data.confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_kafka_acl" "connectors_source_write_topic_demo" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.connectors.id}"
  operation     = "WRITE"
  permission    = "ALLOW"
  host          = "*"
  rest_endpoint = data.confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_kafka_acl" "connectors_source_read_topic_demo" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "*"
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.connectors.id}"
  operation     = "READ"
  permission    = "ALLOW"
  host          = "*"
  rest_endpoint = data.confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}
# DLQ topics (for the connectors)
resource "confluent_kafka_acl" "connectors_source_create_topic_dlq" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "dlq-"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  operation     = "CREATE"
  permission    = "ALLOW"
  host          = "*"
  rest_endpoint = data.confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_kafka_acl" "connectors_source_write_topic_dlq" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "dlq-"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  operation     = "WRITE"
  permission    = "ALLOW"
  host          = "*"
  rest_endpoint = data.confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_kafka_acl" "connectors_source_read_topic_dlq" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  resource_type = "TOPIC"
  resource_name = "dlq-"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  operation     = "READ"
  permission    = "ALLOW"
  host          = "*"
  rest_endpoint = data.confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}
# Consumer group
resource "confluent_kafka_acl" "connectors_source_consumer_group" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  resource_type = "GROUP"
  resource_name = "connect"
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.connectors.id}"
  operation     = "READ"
  permission    = "ALLOW"
  host          = "*"
  rest_endpoint = data.confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}

# --------------------------------------------------------
# Credentials / API Keys
# --------------------------------------------------------
resource "confluent_api_key" "connector_key" {
  display_name = "connector-${data.confluent_kafka_cluster.cc_kafka_cluster.display_name}-key-${random_id.id.hex}"
  description  = local.description
  owner {
    id          = confluent_service_account.connectors.id
    api_version = confluent_service_account.connectors.api_version
    kind        = confluent_service_account.connectors.kind
  }
  managed_resource {
    id          = data.confluent_kafka_cluster.cc_kafka_cluster.id
    api_version = data.confluent_kafka_cluster.cc_kafka_cluster.api_version
    kind        = data.confluent_kafka_cluster.cc_kafka_cluster.kind
    environment {
      id = data.confluent_environment.cc_demo_env.id
    }
  }
  depends_on = [
    confluent_kafka_acl.connectors_source_create_topic_demo,
    confluent_kafka_acl.connectors_source_write_topic_demo,
    confluent_kafka_acl.connectors_source_read_topic_demo,
    confluent_kafka_acl.connectors_source_create_topic_dlq,
    confluent_kafka_acl.connectors_source_write_topic_dlq,
    confluent_kafka_acl.connectors_source_read_topic_dlq,
    confluent_kafka_acl.connectors_source_consumer_group,
  ]
  lifecycle {
    prevent_destroy = false
  }
}

output "connector_key" {
  sensitive = true
  value = confluent_api_key.connector_key.id
}
output "connector_key_value" {
  sensitive = true
  value = confluent_api_key.connector_key.secret
}


# --------------------------------------------------------
# Connectors
# --------------------------------------------------------


resource "confluent_connector" "gcp_genai_demo_prompt_sink" {
  environment {
    id = data.confluent_environment.cc_demo_env.id
  }
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  config_sensitive = {}
  config_nonsensitive = {
      "connector.class"= "GoogleCloudFunctionsSink",
      "name"= "PromptSinkConnector",
      "kafka.auth.mode"          = "SERVICE_ACCOUNT"
      "kafka.service.account.id" = confluent_service_account.connectors.id
      "topics"= confluent_kafka_topic.gcp_genai_demo_prompt.topic_name
      "data.format": "AVRO",
      "function.name": "${var.identifier}-prompt-client",
      "project.id": data.external.env_vars.result.PROJECT_ID,
      "gcf.credentials.json": file("${path.module}/credentials/service_account_key.json"),
      "tasks.max": "1"
  }
  depends_on = [
    confluent_kafka_acl.connectors_source_create_topic_demo,
    confluent_kafka_acl.connectors_source_write_topic_demo,
    confluent_kafka_acl.connectors_source_read_topic_demo,
    confluent_kafka_acl.connectors_source_create_topic_dlq,
    confluent_kafka_acl.connectors_source_write_topic_dlq,
    confluent_kafka_acl.connectors_source_read_topic_dlq,
    confluent_kafka_acl.connectors_source_consumer_group,
    google_cloudfunctions_function.prompt,
    google_service_account_key.gcp_genai_demo_service_account_key
    
  ]
  lifecycle {
    prevent_destroy = false
  }
}
output "gcp_genai_demo_prompt_sink" {
  description = "CC Cloud function Sink Connector ID"
  value       = resource.confluent_connector.gcp_genai_demo_prompt_sink.id
}

resource "confluent_connector" "gcp_genai_demo_context_sink" {
  environment {
    id = data.confluent_environment.cc_demo_env.id
  }
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  config_sensitive = {}
  config_nonsensitive = {
      "connector.class"= "GoogleCloudFunctionsSink",
      "name"= "ContextSinkConnector",
      "kafka.auth.mode"          = "SERVICE_ACCOUNT"
      "kafka.service.account.id" = confluent_service_account.connectors.id
      "topics"= confluent_kafka_topic.gcp_genai_demo_context.topic_name
      "data.format": "AVRO",
      "function.name": "${var.identifier}-context-client",
      "project.id": data.external.env_vars.result.PROJECT_ID,
      "gcf.credentials.json": file("${path.module}/credentials/service_account_key.json"),
      "tasks.max": "1"
  }
  depends_on = [
    confluent_kafka_acl.connectors_source_create_topic_demo,
    confluent_kafka_acl.connectors_source_write_topic_demo,
    confluent_kafka_acl.connectors_source_read_topic_demo,
    confluent_kafka_acl.connectors_source_create_topic_dlq,
    confluent_kafka_acl.connectors_source_write_topic_dlq,
    confluent_kafka_acl.connectors_source_read_topic_dlq,
    confluent_kafka_acl.connectors_source_consumer_group,
    google_cloudfunctions_function.context,
    google_service_account_key.gcp_genai_demo_service_account_key
  ]
  lifecycle {
    prevent_destroy = false
  }
}
output "gcp_genai_demo_context_sink" {
  description = "CC Cloud function Sink Connector ID"
  value       = resource.confluent_connector.gcp_genai_demo_context_sink.id
}


resource "confluent_connector" "gcp_genai_cloud_run_sink" {
  environment {
    id = data.confluent_environment.cc_demo_env.id
  }
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  config_sensitive = {}
  config_nonsensitive = {
      "connector.class": "HttpSink",
      "name": "GenAiCloudRunSink1",
      "kafka.auth.mode"          = "SERVICE_ACCOUNT"
      "kafka.service.account.id" = confluent_service_account.connectors.id
      "topics"= "gcp_genai_demo_prompt_context"
      "input.data.format": "AVRO",
      "http.api.url": "${google_cloud_run_service.genai_run_service.status.0.url}/recommend",
      "request.method": "POST",
      "tasks.max": "1",
      "request.body.format":"JSON"
    }
  depends_on = [
    confluent_kafka_acl.connectors_source_create_topic_demo,
    confluent_kafka_acl.connectors_source_write_topic_demo,
    confluent_kafka_acl.connectors_source_read_topic_demo,
    confluent_kafka_acl.connectors_source_create_topic_dlq,
    confluent_kafka_acl.connectors_source_write_topic_dlq,
    confluent_kafka_acl.connectors_source_read_topic_dlq,
    confluent_kafka_acl.connectors_source_consumer_group,
    google_cloudfunctions_function.context,
    google_cloud_run_service.genai_run_service,
    confluent_flink_statement.gcp_genai_demo_prompt_context_table
  ]
  lifecycle {
    prevent_destroy = false
  }
}
output "gcp_genai_cloud_run_sink" {
  description = "CC Cloud function Sink Connector ID"
  value       = resource.confluent_connector.gcp_genai_demo_context_sink.id
}



