# Configure the GitHub Provider
provider "github" {
  token = var.github_token
  owner = var.github_owner
}

# GitHub Repository Resource
resource "github_repository" "my_repo" {
  name        = "learnbay-python-application"  # Name of the repository
  description = "A sample repository created using Terraform"  # Description
  visibility   = "public"                   # Set visibility to "public" or "private"

  # Optional features
  has_issues   = true   # Enable issues
  has_projects = true    # Enable projects
  has_wiki     = true    # Enable wiki
}

# Branch Default Resource for the Default Branch
resource "github_branch_default" "default_branch" {
  repository = github_repository.my_repo.name  # Set the repository name
  branch     = "main"                         # Name of the default branch
}

# Branch Protection for the Default Branch
resource "github_branch_protection" "main" {
  repository_id  = github_repository.my_repo.id
  pattern        = "main"                      # Protect the main branch
  enforce_admins = true                        # Require admin approval for changes
}
