# Latest Ubuntu 24.04 LTS x86_64 image published by Canonical.
data "google_compute_image" "ubuntu" {
  project = "ubuntu-os-cloud"
  family  = "ubuntu-2404-lts"
}

# Keep the same externally reachable ports as docker-compose.yaml:
# 80 serves the nginx proxy, 3000 exposes the notes API directly, and 22
# is opened for SSH (restrict the CIDR in production).
resource "google_compute_firewall" "instance" {
  name    = "docker-projekti-gcp"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = [80, 3000, 22]
  }

  source_ranges = [var.allowed_cidr]
  description   = "Web proxy, API and SSH for the Compose example"
}

# The startup script installs Docker, clones the selected branch, and runs
# the existing Compose file. The instance keeps the database volume on disk.
resource "google_compute_instance" "example" {
  name           = "docker-projekti-gcp"
  machine_type   = var.machine_type
  zone           = "${var.region}-b"
  can_ip_forward = false
  tags           = ["docker-projekti"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.id
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral public IP so the instance is reachable from the internet.
    }
  }

  metadata = {
    startup-script = templatefile("${path.module}/startup-script.sh.tftpl", {
      repository_url    = var.repository_url
      repository_branch = var.repository_branch
    })
  }

  depends_on = [google_compute_firewall.instance]
}
