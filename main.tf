
data "confluent_organization" "cc_demo_org" {}


output "cc_demo_org" {
  description = "CC Organization"
  value       = data.confluent_organization.cc_demo_org.id
}




data "confluent_environment" "cc_demo_env" {
  id = data.external.env_vars.result.CC_ENV_ID
}


output "cc_demo_env" {
  description = "CC Environment"
  value       = data.confluent_environment.cc_demo_env.id
}
data "confluent_schema_registry_cluster" "cc_sr_cluster" {
  id = data.external.env_vars.result.CC_SR_ID
  environment {
    id = data.external.env_vars.result.CC_ENV_ID
  }
}

output "cc_sr_cluster" {
  value = data.confluent_schema_registry_cluster.cc_sr_cluster.id
}


data "confluent_kafka_cluster" "cc_kafka_cluster" {
  id = data.external.env_vars.result.CC_CLUSTER_ID
  environment {
    id = data.confluent_environment.cc_demo_env.id
  }
}
output "cc_kafka_cluster" {
  description = "CC Kafka Cluster ID"
  value       = data.confluent_kafka_cluster.cc_kafka_cluster.id
}


resource "confluent_service_account" "app-manager-genai" {
  display_name = "app-manager-genai"
  description  = "Service account to manage 'inventory' Kafka cluster"
}


resource "confluent_role_binding" "app-manager-environment-admin" {
  principal   = "User:${confluent_service_account.app-manager-genai.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = data.confluent_environment.cc_demo_env.resource_name
}



resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager-genai.id
    api_version = confluent_service_account.app-manager-genai.api_version
    kind        = confluent_service_account.app-manager-genai.kind
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
    confluent_role_binding.app-manager-environment-admin
  ]
}
output "app-manager-kafka-api-key" {
  sensitive = true
  value = confluent_api_key.app-manager-kafka-api-key.id
}
output "app-manager-kafka-api-ke-value" {
  sensitive = true
  value = confluent_api_key.app-manager-kafka-api-key.secret
}


resource "confluent_api_key" "app-manager-schema-api-key" {
  display_name = "app-manager-schema-api-key"
  description  = "Schema manager API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager-genai.id
    api_version = confluent_service_account.app-manager-genai.api_version
    kind        = confluent_service_account.app-manager-genai.kind
  }

  managed_resource {
    id          = data.confluent_schema_registry_cluster.cc_sr_cluster.id
    api_version = data.confluent_schema_registry_cluster.cc_sr_cluster.api_version
    kind        = data.confluent_schema_registry_cluster.cc_sr_cluster.kind

    environment {
      id = data.confluent_environment.cc_demo_env.id
    }
  }
}


output "app-manager-schema-api-key" {
  sensitive = true
  value = confluent_api_key.app-manager-schema-api-key.id
}
output "app-manager-schema-api-key-value" {
  sensitive = true
  value = confluent_api_key.app-manager-schema-api-key.secret
}


