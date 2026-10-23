
resource "google_artifact_registry_repository" "this" {
  for_each = var.repositories

  project       = var.project_id
  location      = each.value.location
  repository_id = each.key
  description   = each.value.description
  format        = upper(each.value.format)
  labels        = each.value.labels
  kms_key_name  = each.value.kms_key_name

  cleanup_policy_dry_run = (
    length(each.value.cleanup_policies) > 0
    ? each.value.cleanup_policy_dry_run
    : null
  )

  dynamic "docker_config" {
    for_each = upper(each.value.format) == "DOCKER" ? [1] : []

    content {
      immutable_tags = each.value.immutable_tags
    }
  }

  dynamic "maven_config" {
    for_each = upper(each.value.format) == "MAVEN" ? [1] : []

    content {
      version_policy            = each.value.maven_version_policy
      allow_snapshot_overwrites = each.value.allow_snapshot_overwrites
    }
  }

  dynamic "cleanup_policies" {
    for_each = each.value.cleanup_policies
    iterator = policy

    content {
      id     = policy.key
      action = upper(policy.value.action)

      dynamic "condition" {
        for_each = policy.value.condition == null ? [] : [policy.value.condition]

        content {
          tag_state             = condition.value.tag_state
          tag_prefixes          = condition.value.tag_prefixes
          version_name_prefixes = condition.value.version_name_prefixes
          package_name_prefixes = condition.value.package_name_prefixes
          older_than            = condition.value.older_than
          newer_than            = condition.value.newer_than
        }
      }

      dynamic "most_recent_versions" {
        for_each = policy.value.most_recent_versions == null ? [] : [policy.value.most_recent_versions]

        content {
          package_name_prefixes = most_recent_versions.value.package_name_prefixes
          keep_count            = most_recent_versions.value.keep_count
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition = alltrue([
        for policy in values(each.value.cleanup_policies) :
        (
          (policy.condition != null) !=
          (policy.most_recent_versions != null)
        ) &&
        (
          upper(policy.action) != "DELETE" ||
          policy.most_recent_versions == null
        )
      ])
      error_message = "Each cleanup policy must define exactly one of condition or most_recent_versions. DELETE policies must use condition."
    }

    precondition {
      condition = (
        upper(each.value.format) == "MAVEN" ||
        (
          each.value.maven_version_policy == "VERSION_POLICY_UNSPECIFIED" &&
          !each.value.allow_snapshot_overwrites
        )
      )
      error_message = "Maven-specific settings must use their defaults for non-Maven repositories."
    }

    precondition {
      condition = (
        upper(each.value.format) == "DOCKER" ||
        !each.value.immutable_tags
      )
      error_message = "immutable_tags can only be enabled for Docker repositories."
    }
  }
}

locals {
  repository_iam_bindings = flatten([
    for repository_id, grants in var.repository_iam : [
      for grant in grants : {
        key           = "${repository_id}|${grant.role}|${grant.member}"
        repository_id = repository_id
        role          = grant.role
        member        = grant.member
      }
    ]
  ])

  repository_iam_bindings_by_key = {
    for binding in local.repository_iam_bindings :
    binding.key => binding
  }
}

resource "google_artifact_registry_repository_iam_member" "this" {
  for_each = local.repository_iam_bindings_by_key

  project    = var.project_id
  location   = google_artifact_registry_repository.this[each.value.repository_id].location
  repository = google_artifact_registry_repository.this[each.value.repository_id].repository_id
  role       = each.value.role
  member     = each.value.member
}
