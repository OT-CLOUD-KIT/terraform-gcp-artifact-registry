
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
      location    = var.location
      format      = "DOCKER"
      description = "Docker images for CI/CD"
      immutable_tags = true
      cleanup_policy_dry_run = true

      cleanup_policies = {
        delete-untagged = {
          action = "DELETE"
          condition = {
            tag_state  = "UNTAGGED"
            older_than = "30d"
          }
        }
      }
    }

    "demo-maven" = {
      location           = var.location
      format             = "MAVEN"
      description        = "Java packages for client demos"
      maven_version_policy = "VERSION_POLICY_UNSPECIFIED"
      cleanup_policy_dry_run = true
    }

    "demo-npm" = {
      location    = var.location
      format      = "NPM"
      description = "Node.js packages for client demos"
      cleanup_policy_dry_run = true
    }
  }

  repository_iam = {
    "demo-docker" = [
      {
        role   = "roles/artifactregistry.reader"
        member = "serviceAccount:${var.reader_service_account}"
      }
    ]

    "demo-maven" = [
      {
        role   = "roles/artifactregistry.reader"
        member = "serviceAccount:${var.reader_service_account}"
      }
    ]

    "demo-npm" = [
      {
        role   = "roles/artifactregistry.reader"
        member = "serviceAccount:${var.reader_service_account}"
      }
    ]
  }
}

output "repository_ids" {
  value = module.artifact_registry.repository_ids
}

output "repository_names" {
  value = module.artifact_registry.repository_names
}
