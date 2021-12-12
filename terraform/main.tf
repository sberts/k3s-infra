terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

provider "openstack" {
  auth_url    = "http://controller:5000/v3"
  region      = "RegionOne"
}

resource "openstack_networking_secgroup_v2" "db" {
  name        = "${var.name} db secgroup"
  description = "allow all traffic"
}

resource "openstack_networking_secgroup_rule_v2" "db" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = ""
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.db.id
}

resource "openstack_compute_instance_v2" "db" {
  name            = "k3s-db"
  image_id        = "7b84e04c-a7e2-4349-8bfe-b63f85502cb3"
  flavor_id       = "3828c0b7-df1c-4c78-86bb-d66f3657a3d7"
  key_pair        = var.key_pair
  security_groups = [ openstack_networking_secgroup_v2.db.name ]

  metadata = {
    this = "that"
  }

  network {
    name = var.network
  }
}

resource "openstack_networking_floatingip_v2" "db" {
  pool = "provider"
}

resource "openstack_compute_floatingip_associate_v2" "db" {
  floating_ip = "${openstack_networking_floatingip_v2.db.address}"
  instance_id = "${openstack_compute_instance_v2.db.id}"
}

resource "openstack_compute_instance_v2" "master" {
  count           = var.master_count
  name            = "${var.name}-master-${count.index}"
  image_id        = "7b84e04c-a7e2-4349-8bfe-b63f85502cb3"
  flavor_id       = "3828c0b7-df1c-4c78-86bb-d66f3657a3d7"
  key_pair        = var.key_pair
  security_groups = [ openstack_networking_secgroup_v2.db.name ]

  metadata = {
    this = "that"
  }

  network {
    name = var.network
  }
}

resource "openstack_networking_floatingip_v2" "master" {
  count = var.master_count
  pool = "provider"
}

resource "openstack_compute_floatingip_associate_v2" "master" {
  count       = var.master_count
  floating_ip = "${element(openstack_networking_floatingip_v2.master.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.master.*.id, count.index)}"
}

output "db_fip" {
  value = openstack_networking_floatingip_v2.db.address
}

output "master_fip" {
    value = "${openstack_networking_floatingip_v2.master.*.address}"
}
