provider "google" {
    credentials = "${file("GoogleProjectServiceAccountKey.json")}"
    project     = "formationdevops"
    region      = "europe-west1"
}

resource "random_id" "instance_id" {
    byte_length = 8
    count = 2
}

// Rancher Master
resource "google_compute_instance" "master" {
    name         = "formationdevops-vm-master"
    machine_type = "n1-standard-2"
    zone         = "europe-west1-b"

    boot_disk {
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-1604-lts"
            size = 30
        }
    }

    metadata {
        sshKeys = "root:${file("~/.ssh/id_rsa.pub")}"
    }

    metadata_startup_script = "sudo apt update; sudo apt install -y docker.io; sudo usermod -aG docker $USER; sudo docker run -d --restart unless-stopped -p 80:8080 rancher/server:v1.6.17"

    network_interface {
        network = "default"

        access_config {
            // Include this section to give the VM an external ip address
        }
    }
}

// Rancher Slaves
resource "google_compute_instance" "slave" {
    name         = "formationdevops-slave-${random_id.instance_id.*.hex[count.index]}"
    machine_type = "n1-standard-2"
    zone         = "europe-west1-b"
    count        = 2

    boot_disk {
        initialize_params {
            image = "ubuntu-os-cloud/ubuntu-1604-lts"
            size = 30
        }
    }

    metadata {
        sshKeys = "root:${file("~/.ssh/id_rsa.pub")}"
    }

    metadata_startup_script = "sudo apt update; sudo apt install -y docker.io; sudo usermod -aG docker $USER;"

    network_interface {
        network = "default"

        access_config {
            // Include this section to give the VM an external ip address
        }
    }
}

resource "google_compute_firewall" "default" {
    name    = "formationdevops-firewall"
    network = "default"

    allow {
        protocol = "tcp"
        ports    = ["80", "443", "52"]
    }
}