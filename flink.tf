resource "confluent_flink_compute_pool" "main" {
  display_name     = "standard_compute_pool"
  cloud            = "GCP"
  region           = data.external.env_vars.result.REGION
  max_cfu          = 5
  environment {
    id = data.confluent_environment.cc_demo_env.id
  }
}
data "confluent_flink_region" "flink_region" {
  cloud   = "GCP"
  region  = data.external.env_vars.result.REGION
}

output "flink_region" {
  value = data.confluent_flink_region.flink_region
}

resource "confluent_api_key" "flink-api-key" {
  display_name = "flink-api-key"
  description  = "Flink API Key that is owned by 'env-manager' service account"
  owner {
    id          = confluent_service_account.app-manager-genai.id
    api_version = confluent_service_account.app-manager-genai.api_version
    kind        = confluent_service_account.app-manager-genai.kind
  }

  managed_resource {
    id          = data.confluent_flink_region.flink_region.id
    api_version = data.confluent_flink_region.flink_region.api_version
    kind        = data.confluent_flink_region.flink_region.kind

    environment {
      id = data.confluent_environment.cc_demo_env.id
    }
  }

}

resource "confluent_flink_statement" "gcp_genai_demo_prompt_context_table" {
  organization {
    id = data.confluent_organization.cc_demo_org.id
  }
  environment {
    id = data.confluent_environment.cc_demo_env.id
  }
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.app-manager-genai.id
  }
  statement  =<<EOF
  CREATE TABLE gcp_genai_demo_prompt_context ( 
  prompt_id STRING,
  prompt_text STRING,
  prompt_image_url STRING,
  session_id INTEGER,
  product_description ARRAY<String>,
  product_gcs_uri ARRAY<String>,
  product_attributes ARRAY<String>
) WITH (
  'changelog.mode' = 'retract')
  EOF
  
  properties = {
    "sql.current-catalog"  = data.confluent_environment.cc_demo_env.display_name
    "sql.current-database" = data.confluent_kafka_cluster.cc_kafka_cluster.display_name
  }
  rest_endpoint = data.confluent_flink_region.flink_region.rest_endpoint
  credentials {
    key    = confluent_api_key.flink-api-key.id
    secret = confluent_api_key.flink-api-key.secret
  }


}
output "flink_statement_1" {
    value = confluent_flink_statement.gcp_genai_demo_prompt_context_table.id
  
}


resource "confluent_flink_statement" "insert_gcp_genai_demo_prompt_context" {
  organization {
    id = data.confluent_organization.cc_demo_org.id
  }
  environment {
    id = data.confluent_environment.cc_demo_env.id
  }
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.app-manager-genai.id
  }
  statement  =<<EOF
  INSERT INTO gcp_genai_demo_prompt_context
SELECT DISTINCT
  pe.prompt_id, 
  pe.text, 
  pe.image_url,
  pe.session_id, 
  ARRAY_AGG(DISTINCT ct.ProductDescription) AS ProductDescription,
  ARRAY_AGG(DISTINCT ct.ProductImageGCSUri) AS ProductImageGCSUri,
  ARRAY_AGG(DISTINCT ct.ProductAttributes) AS ProductAttributes
FROM
  (SELECT DISTINCT
  pe.prompt_id,
  pe.text,
  pe.image_url, 
  pe.session_id,
  matched_index
FROM
  `gcp-genai-demo-prompt-embedding` pe,
  UNNEST(pe.matched_indexes) AS matched_index ) AS pe
JOIN 
  `gcp-genai-demo-context` ct
ON
  ct.ProductImageIndexID = pe.matched_index OR 
  ct.ProductTextIndexID = pe.matched_index
GROUP BY
 pe.prompt_id, 
 pe.text, 
 pe.image_url, 
 pe.session_id;
EOF
  
  properties = {
    "sql.current-catalog"  = data.confluent_environment.cc_demo_env.display_name
    "sql.current-database" = data.confluent_kafka_cluster.cc_kafka_cluster.display_name
  }
  rest_endpoint = data.confluent_flink_region.flink_region.rest_endpoint
  credentials {
    key    = confluent_api_key.flink-api-key.id
    secret = confluent_api_key.flink-api-key.secret
  }
depends_on = [ confluent_kafka_topic.gcp_genai_demo_prompt_embedding,
confluent_kafka_topic.gcp_genai_demo_context, 
confluent_flink_statement.gcp_genai_demo_prompt_context_table]

}
output "flink_statement_2" {
    value = confluent_flink_statement.insert_gcp_genai_demo_prompt_context.id
  
}