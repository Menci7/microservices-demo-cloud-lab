variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "europe-west9"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "europe-west9-b"
}

variable "frontend_ip" {
  description = "Frontend service IP address)"
  type        = string
}

variable "locust_users" {
  description = "Number of concurrent users for load testing"
  type        = number
  default     = 10
}

variable "locust_rate" {
  description = "User spawn rate per second"
  type        = number
  default     = 1
}

variable "machine_type" {
  description = "GCE machine type"
  type        = string
  default     = "e2-small"
}
