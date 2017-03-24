variable "windows_2016_image" {
    type = "string"
    default = "windows-server-2016-dc-v20170227"
}

variable "projectid" {
    type = "string"
}

variable "region" {
    type = "string"
    default = "us-east1"
}

variable "zone" {
    type = "string"
    default = "us-east1-d"
}

provider "google" {
    project = "${var.projectid}"
    region = "${var.region}"
    credentials = ""
}

resource "google_compute_network" "buildlet" {
  name       = "buildlet"
}

resource "google_compute_subnetwork" "buildlet-subnet-1" {
  name          = "buildlet-subnet-${var.region}"
  ip_cidr_range = "10.0.0.0/24"
  network       = "${google_compute_network.buildlet.self_link}"
}

// Allow dev access buildlet
resource "google_compute_firewall" "buildlet-dev-access" {
  name    = "buildlet-dev-access"
  network = "${google_compute_network.buildlet.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["3389", "80"]
  }

  target_tags = ["allow-dev-access"]
}

// Allow all traffic within subnet
resource "google_compute_firewall" "intra-subnet-open" {
  name    = "buildlet-intra-subnet-open"
  network = "${google_compute_network.buildlet.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["1-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["1-65535"]
  }

  source_tags = ["internal"]
}

resource "google_compute_instance" "buildlet-win2016" {
  name         = "buildlet-win2016"
  machine_type = "n1-standard-2"
  zone         = "${var.zone}"

  tags = ["allow-dev-access", "internal"]

  disk {
    image = "${var.windows_2016_image}"
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.buildlet-subnet-1.name}"
    access_config {
      // Ephemeral IP
    }
  }

  metadata {
    sysprep-specialize-script-ps1  = "${file("winstrap.ps1")}"
    buildlet-binary-url            = "https://storage.googleapis.com/go-builder-data/buildlet.windows-amd64"
  }
}


