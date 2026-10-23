
output "repository_ids" {
  description = "Artifact Registry resource IDs keyed by repository ID."
  value       = { for name, repo in google_artifact_registry_repository.this : name => repo.id }
}

output "repository_urls" {
  description = "Artifact Registry repository URLs keyed by repository ID."
  value       = { for name, repo in google_artifact_registry_repository.this : name => "${repo.location}-docker.pkg.dev/${var.project_id}/${repo.repository_id}" if upper(var.repositories[name].format) == "DOCKER" }
}

output "repository_names" {
  description = "Fully qualified Artifact Registry repository names."
  value       = { for name, repo in google_artifact_registry_repository.this : name => repo.name }
}

output "repository_locations" {
  description = "Repository locations keyed by repository ID."
  value       = { for name, repo in google_artifact_registry_repository.this : name => repo.location }
}
