locals {
  description = "Resource created using terraform for data portal demo"
}

resource "random_id" "id" {
  byte_length = 4
}


variable "identifier" {
  description = "The ID of the GCP project"
  default     = "gcp-genai-demo"
}
