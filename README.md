# genai-confluent-gcp-artifact
# Overview

This is the 2.0 version of what we did at current 2023 with GCP, where we built a streaming RAG pipeline powered by Flink SQL on confluent cloud for real time contextual processing on the other hand using Gemini's multimodality for Image+Text based question/answering chat pipeline for domain specific knowledge bots. References: [Architecture](https://lucid.app/lucidchart/ce1acdc5-08d1-4f26-88fb-f75c435331bc/edit?referringApp=google+drive&beaconFlowId=728bd107b5478196&invitationId=inv_ec0df969-af71-42e8-8b97-7040187b9dd9&page=hIEhqJj~tzIJ#), [Google Blog](https://cloud.google.com/blog/topics/partners/confluent-brings-real-time-capabilities-to-google-cloud-gen-ai), [Webinar](https://event.on24.com/wcc/r/4513309/FECC83DA71BA6716B67A5CF262D9C6B0), [Deck](https://docs.google.com/presentation/d/1enlFaFB9ft4893Y07pW2fi5cw1LvJyctG9l8w3Y0qKI/edit#slide=id.g23d1fe316c8_0_3960).

# Before you begin









# Pre-requisites
- User account on [Confluent Cloud](https://www.confluent.io/confluent-cloud/tryfree)
- Local install of [Terraform](https://www.terraform.io) (details below)
- Env ,Cluster and Schema registry setup on confluent cloud env

# Installation (only need to do that once)

## Install Terraform
```
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew update
brew upgrade hashicorp/tap/terraform
```


## Authenticate your Google Cloud account
```
gcloud auth login

gcloud auth application-default login  

```


## Create VectorSearch Index Endpoint on your Google Cloud account
```
https://cloud.google.com/vertex-ai/docs/vector-search/deploy-index-vpc

```


# Provision services for the demo

## Set environment variables
- Create file `.env` from `.env_example`
```
CONFLUENT_CLOUD_API_KEY=<SPECIFY YOUR CONFLUENT_CLOUD_API_KEY >
CONFLUENT_CLOUD_API_SECRET=<SPECIFY YOUR CONFLUENT_CLOUD_API_SECRET >
CC_ENV_ID=<SPECIFY YOUR ENVIRONMENT ID>
CC_SR_ID=<SPECIFY YOUR SCHEMA REGISTRY ID>
CC_CLUSTER_ID=<SPECIFY YOUR KAFKA CLUSTER ID>
PROJECT_ID=<SPECIFY YOUR GCP PROJECT_ID>
INDEX_NAME=<SPECIFY YOUR GCP INDEX_NAME>
REGION=<SPECIFY YOUR REGION>
INDEX_ENDPOINT=<SPECIFY YOUR INDEX_ENDPOINT>
DEPLOYED_INDEX_ID=<SPECIFY YOUR DEPLOYED_INDEX_ID>
```

## Setup the env for demo 
- Run command: `./demo_start.sh`

The Terraform code will also create resources onto your confluent cloud and gcp account.




![image](docs/lineage.png)

# Terraform files
- `vars.tf`: Main system variables (change it as needed)
- `providers.tf`:
  - confluentinc/confluen
  - hashicorp/external (To read env variables)
- `main.tf`: 
  - Confluent Cloud Environment
  - Schema Registry
  - Apache Kafka Cluster
  - Service Accounts (app_manager, sr, clients)
  - Role Bindings (app_manager, sr, clients)
  - Credentials / API Keys (app_manager, sr, clients)
- `connectors.tf`:
  - Service Accounts (Connectors)
  - Access Control List
  - Credentials / API Keys
  - Create Kafka topics for the DataGen Connectors
  - DataGen Connectors
- `data_portal.tf`:
  - Create tags and business metadata after creation of KSQL queries.
  - Create tags and business  bindings for the topics


