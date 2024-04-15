#!/bin/bash   

# Update timestamp on credit_card AVRO schema
UTC_NOW=`date -u +%s000`

terraform init
terraform plan
terraform apply --auto-approve
terraform output -json
