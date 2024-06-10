

# --------------------------------------------------------
# Create Kafka topics for the  Connectors
# --------------------------------------------------------
resource "confluent_kafka_topic" "gcp_genai_demo_prompt" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  topic_name    = "${var.identifier}-prompt"
  
  rest_endpoint = data.confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
}
resource "confluent_schema" "avro-gcp_genai_demo_prompt" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.cc_sr_cluster.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.cc_sr_cluster.rest_endpoint
  subject_name = "${var.identifier}-prompt-value"
  format = "AVRO"
  schema = file("./schemas/prompt/prompt.avsc")
  credentials {
    key    = confluent_api_key.app-manager-schema-api-key.id
    secret = confluent_api_key.app-manager-schema-api-key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
  depends_on = [ confluent_api_key.app-manager-schema-api-key ]
}

resource "confluent_kafka_topic" "gcp_genai_demo_context" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  topic_name    = "${var.identifier}-context"
  rest_endpoint = data.confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
  depends_on = [ confluent_api_key.app-manager-kafka-api-key ]
}
resource "confluent_schema" "avro-gcp_genai_demo_context" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.cc_sr_cluster.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.cc_sr_cluster.rest_endpoint
  subject_name = "${var.identifier}-context-value"
  format = "AVRO"
  schema = file("./schemas/context/context.avsc")
  credentials {
    key    = confluent_api_key.app-manager-schema-api-key.id
    secret = confluent_api_key.app-manager-schema-api-key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
  depends_on = [ confluent_api_key.app-manager-schema-api-key ]

}

resource "confluent_kafka_topic" "gcp_genai_demo_prompt_embedding" {
  kafka_cluster {
    id = data.confluent_kafka_cluster.cc_kafka_cluster.id
  }
  topic_name    = "${var.identifier}-prompt-embedding"
  rest_endpoint = data.confluent_kafka_cluster.cc_kafka_cluster.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }
  lifecycle {
    prevent_destroy = false
  }
  depends_on = [ confluent_api_key.app-manager-kafka-api-key ]
}
resource "confluent_schema" "avro-gcp_genai_demo_prompt_embedding" {
  schema_registry_cluster {
    id = data.confluent_schema_registry_cluster.cc_sr_cluster.id
  }
  rest_endpoint = data.confluent_schema_registry_cluster.cc_sr_cluster.rest_endpoint
  subject_name = "${var.identifier}-prompt-embedding-value"
  format = "AVRO"
  schema = file("./schemas/prompt_embedding/prompt_embedding.avsc")
  credentials {
    key    = confluent_api_key.app-manager-schema-api-key.id
    secret = confluent_api_key.app-manager-schema-api-key.secret
  }

  lifecycle {
    prevent_destroy = false
  }
  depends_on = [ confluent_api_key.app-manager-schema-api-key ]
}




resource "local_file" "kafka_config" {
  content  = <<EOF
bootstrap.servers=${data.confluent_kafka_cluster.cc_kafka_cluster.bootstrap_endpoint}
sasl.username=${confluent_api_key.app-manager-kafka-api-key.id}
sasl.password=${confluent_api_key.app-manager-kafka-api-key.secret}
security.protocol=SASL_SSL
sasl.mechanisms=PLAIN

context_topic_name=${confluent_kafka_topic.gcp_genai_demo_context.topic_name}
prompt_topic_name=${confluent_kafka_topic.gcp_genai_demo_prompt.topic_name}
prompt_context_topic_name=gcp_genai_demo_prompt_context
session.timeout.ms=45000

schema.registry.url=${data.confluent_schema_registry_cluster.cc_sr_cluster.rest_endpoint}
schema.registry.basic.auth.credentials.source=USER_INFO
schema.registry.basic.auth.user.info=${confluent_api_key.app-manager-schema-api-key.id}:${confluent_api_key.app-manager-schema-api-key.secret}
EOF

  filename = "${path.module}/demo/client.properties"
  depends_on = [ confluent_api_key.app-manager-kafka-api-key,confluent_api_key.app-manager-schema-api-key,confluent_kafka_topic.gcp_genai_demo_context,confluent_kafka_topic.gcp_genai_demo_prompt,confluent_flink_statement.gcp_genai_demo_prompt_context_table ]
}

output "kafka_config_file" {
  value = local_file.kafka_config.filename
}
