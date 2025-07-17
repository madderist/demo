variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "The Google Cloud region to deploy resources in."
  type        = string
  default     = "us-central1"
}

variable "github_repo_name" {
  description = "The name of the connected GitHub repository (e.g., 'owner/repo')."
  type        = string
  default     = "madderist/demo" # Updated to match the main.tf
}

variable "github_branch_name" {
  description = "The name of the branch to deploy from."
  type        = string
}