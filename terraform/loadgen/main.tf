terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Create a service account for the VM
resource "google_service_account" "loadgen_sa" {
  account_id   = "loadgen-sa"
  display_name = "Load Generator Service Account"
}

# GCE instance for load generator
resource "google_compute_instance" "loadgen" {
  name         = "loadgen-vm"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["loadgen", "http-server"]

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable"  # Container-Optimized OS (has Docker pre-installed)
      size  = 10  # GB
    }
  }

  network_interface {
    network = "default"
    
    # Assign external IP for accessing Locust web UI
    access_config {}
  }

  service_account {
    email  = google_service_account.loadgen_sa.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script = templatefile("${path.module}/startup-script.sh", {
      frontend_ip   = var.frontend_ip
      locust_users  = var.locust_users
      locust_rate   = var.locust_rate
    })
  }

  # Allow recreation when startup script changes
  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    frontend_ip   = var.frontend_ip
    locust_users  = var.locust_users
    locust_rate   = var.locust_rate
  })
}

# Firewall rule for Locust web UI (port 8089)
resource "google_compute_firewall" "locust_web" {
  name    = "allow-locust-web"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8089"]
  }

  source_ranges = ["0.0.0.0/0"]  # WARNING: Open to internet - restrict in production
  target_tags   = ["loadgen"]
}

# Output the VM's external IP
output "loadgen_external_ip" {
  value       = google_compute_instance.loadgen.network_interface[0].access_config[0].nat_ip
  description = "External IP of the load generator VM"
}

output "locust_web_url" {
  value       = "http://${google_compute_instance.loadgen.network_interface[0].access_config[0].nat_ip}:8089"
  description = "URL to access Locust web interface"
}

output "ssh_command" {
  value       = "gcloud compute ssh loadgen-vm --zone=${var.zone}"
  description = "Command to SSH into the VM"
}
