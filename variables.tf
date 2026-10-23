variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "repositories" {
  description = "Artifact Registry repositories to create, keyed by repository ID."

  type = map(object({
    location      = string
    format        = string
    description   = optional(string, "Managed by Terraform")
    labels        = optional(map(string), {})
    kms_key_name  = optional(string)
    immutable_tags = optional(bool, false)

    maven_version_policy = optional(string, "VERSION_POLICY_UNSPECIFIED")
    allow_snapshot_overwrites = optional(bool, false)

    cleanup_policy_dry_run = optional(bool, true)

    cleanup_policies = optional(map(object({
      action = string

      condition = optional(object({
        tag_state             = optional(string, "ANY")
        tag_prefixes          = optional(list(string), [])
        version_name_prefixes = optional(list(string), [])
        package_name_prefixes = optional(list(string), [])
        older_than            = optional(string)
        newer_than            = optional(string)
      }))

      most_recent_versions = optional(object({
        package_name_prefixes = optional(list(string), [])
        keep_count            = number
      }))
    })), {})
  }))

  validation {
    condition = alltrue([
      for repository in values(var.repositories) :
      contains(["DOCKER", "MAVEN", "NPM"], upper(repository.format))
    ])
    error_message = "Supported repository formats are DOCKER, MAVEN, and NPM."
  }

  validation {
    condition = alltrue([
      for repository in values(var.repositories) :
      contains([
        "VERSION_POLICY_UNSPECIFIED",
        "RELEASE",
        "SNAPSHOT"
      ], repository.maven_version_policy)
    ])
    error_message = "Invalid Maven version policy."
  }

  validation {
    condition = alltrue(flatten([
      for repository in values(var.repositories) : [
        for policy in values(repository.cleanup_policies) :
        contains(["DELETE", "KEEP"], upper(policy.action))
      ]
    ]))
    error_message = "Cleanup policy action must be DELETE or KEEP."
  }
}

variable "repository_iam" {
  description = "Repository-level IAM grants, keyed by repository ID."

  type = map(list(object({
    role   = string
    member = string
  })))

  default = {}
}
