# GitHub Token Variable
variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

# GitHub Owner Variable
variable "github_owner" {
  description = "GitHub username or organization"
  type        = string
  default     = "LearnbayDevops"  # Replace with your username or organization
}

