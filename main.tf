# Configure the Google Cloud provider with an alias to avoid conflicts with Infracost
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
  alias   = "main"
  # Credentials will be obtained from the GOOGLE_APPLICATION_CREDENTIALS environment variable
  # or from the service account attached to the resource in GCP
}

# Create a VPC network
resource "google_compute_network" "vpc_network" {
  provider                = google.main
  name                    = "terraform-network"
  auto_create_subnetworks = false
}

# Create a subnet
resource "google_compute_subnetwork" "subnet" {
  provider      = google.main
  name          = "terraform-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Reserve a static external IP address for the public VM
resource "google_compute_address" "static_ip" {
  provider = google.main
  name     = "terraform-static-ip"
  region   = var.region
}

# Create firewall rule for SSH, HTTP, and HTTPS for the public VM
resource "google_compute_firewall" "public_vm_firewall" {
  provider = google.main
  name     = "public-vm-firewall"
  network  = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["public-vm"]
}

# Create firewall rule for internal communication between VMs
resource "google_compute_firewall" "internal_firewall" {
  provider = google.main
  name     = "internal-firewall"
  network  = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/24"]
}

# Create the public VM instance
resource "google_compute_instance" "public_vm" {
  provider     = google.main
  name         = "public-vm"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["public-vm"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata = {
    ssh-keys = var.ssh_pub_key != "" ? "${var.ssh_username}:${var.ssh_pub_key}" : null
  }
}

# Create the private VM instances
resource "google_compute_instance" "private_vm" {
  provider     = google.main
  count        = 2
  name         = "private-vm-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet.id
    # No access_config means no external IP
  }

  metadata = {
    ssh-keys = var.ssh_pub_key != "" ? "${var.ssh_username}:${var.ssh_pub_key}" : null
  }
}
