variable "image" {
    type = "string"
}

variable "projectid" {
    type = "string"
}

variable "region" {
    type = "string"
}

variable "zone" {
    type = "string"
}

provider "google" {
    project = "${var.projectid}"
    region = "${var.region}"
    credentials = ""
}


// Allow dev access buildlet
resource "google_compute_firewall" "buildlet-dev-access" {
  name    = "buildlet-dev-access"
  network = "default"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["3389", "80"]
  }

  target_tags = ["allow-dev-access"]
}


resource "google_compute_instance" "buildlet-windows" {
  name         = "buildlet-windows"
  machine_type = "n1-standard-2"
  zone         = "${var.zone}"

  tags = ["allow-dev-access", "internal"]

  disk {
    image = "${var.image}"
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral IP
    }
  }

  metadata {
    sysprep-specialize-script-ps1  = "${file("winstrap.ps1")}"
    buildlet-binary-url            = "https://storage.googleapis.com/go-builder-data/buildlet.windows-amd64"
  }
}


