
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
  description = "Email of the service account that reads artifacts."
  type        = string
}

variable "writer_service_account" {
  description = "Email of the service account that publishes artifacts."
  type        = string
}
