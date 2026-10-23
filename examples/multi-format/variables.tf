
variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "location" {
  description = "Artifact Registry location."
  type        = string
  default     = "asia-south1"
}

variable "reader_service_account" {
  description = "Email of the service account granted read access."
  type        = string
}

variable "kms_key_name" {
  description = "Optional full Cloud KMS crypto key resource name."
  type        = string
  default     = null
  nullable    = true
}
