
terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0.0, < 8.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

module "artifact_registry" {
  source     = "../../"
  project_id = var.project_id

  repositories = {
    "demo-docker" = {
      location       = var.location
      format         = "DOCKER"
      description    = "Docker repository for client demonstrations"
      immutable_tags = true

      cleanup_policy_dry_run = true

      cleanup_policies = {
        delete-old-untagged = {
          action = "DELETE"

          condition = {
            tag_state  = "UNTAGGED"
            older_than = "30d"
          }
        }

        keep-recent-versions = {
          action = "KEEP"

          most_recent_versions = {
            keep_count = 10
          }
        }
      }

      labels = {
        managed_by = "terraform"
        environment = "demo"
      }
    }
  }

  repository_iam = {
    "demo-docker" = [
      {
        role   = "roles/artifactregistry.reader"
        member = "serviceAccount:${var.reader_service_account}"
      },
      {
        role   = "roles/artifactregistry.writer"
        member = "serviceAccount:${var.writer_service_account}"
      }
    ]
  }
}

output "repository_ids" {
  value = module.artifact_registry.repository_ids
}

output "repository_urls" {
  value = module.artifact_registry.repository_urls
}
