terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.30.0"
    }
  }
  # Configure the GCS backend for storing Terraform state
  backend "gcs" {
    # The bucket name will be provided by the Cloud Build pipeline
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable the necessary APIs for the project to work
resource "google_project_service" "project_services" {
  for_each = toset([
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "sourcerepo.googleapis.com"
  ])

  project                    = var.project_id
  service                    = each.key
}

# Create a dedicated service account for the function to run as
# This follows the principle of least privilege.
resource "google_service_account" "function_sa" {
  project      = var.project_id
  account_id   = "hello-world-function-sa"
  display_name = "Hello World Function Service Account"
}

# Define the 2nd Gen Cloud Function
resource "google_cloudfunctions2_function" "hello_world" {
  name     = "hello-world-go"
  location = var.region
  project  = var.project_id

  # This configuration tells the function how to build itself
  build_config {
    runtime     = "go122" # Using a recent Go runtime
    entry_point = "HelloWorld" // This must match the function registered in main.go
    source {
      # This points to a repository connected via Cloud Build
      repo_source {
        project_id  = var.project_id
        repo_name   = regex("repositories/([^/]+)$", var.github_repo_name)[0]    // e.g., "your-github-username/your-repo-name"
        branch_name = var.github_branch_name // e.g., "main"
        dir         = "function_source"      // The subdirectory containing the function code
      }
    }
  }

  # This configuration defines how the function runs
  service_config {
    max_instance_count = 1
    available_memory   = "128Mi"
    timeout_seconds    = 30
    # This makes the function publicly accessible
    ingress_settings = "ALLOW_ALL"
    # Run the function using the dedicated service account
    service_account_email = google_service_account.function_sa.email
  }

  # Ensure APIs are enabled before creating the function
  depends_on = [
    google_project_service.project_services
  ]
}

# Give the new function public access by granting the "Cloud Run Invoker" role
# to all users. This is what makes it a public "Hello World" endpoint.
resource "google_cloud_run_service_iam_member" "invoker" {
  project  = google_cloudfunctions2_function.hello_world.project
  location = google_cloudfunctions2_function.hello_world.location
  service  = google_cloudfunctions2_function.hello_world.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Output the function's URL after it's deployed
output "function_url" {
  description = "The URL of the deployed Hello World function."
  value       = google_cloudfunctions2_function.hello_world.service_config[0].uri
}
