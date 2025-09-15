data "nutanix_clusters_v2" "<CLUSTER NAME>" {
  filter = "name eq '<CLUSTER NAME>'"
}

data "nutanix_images_v2" "<IMAGE NAME>" {
  filter = "startswith(name,'<IMAGE NAME>')"
  page   = 0
  limit  = 10
}

data "nutanix_subnets_v2" "<SUBNET NAME>" {
  filter = "name eq '<SUBNET NAME>'"
}

resource "nutanix_virtual_machine_v2" "<VM NAME>" {
  name                 = var.vm_name
  num_sockets          = 1
  num_cores_per_socket = 4
  memory_size_bytes    = 8 * 1024 * 1024 * 1024 # 8 GiB

  cluster {
    ext_id = data.nutanix_clusters_v2.<CLUSTER NAME>.cluster_entities[0].ext_id
  }

  guest_customization {
    config {
      sysprep {
        install_type = "PREPARED"
        sysprep_script {
          unattend_xml {
            value = base64encode(
            templatefile("${path.module}/files/unattend.xml", { vm_name = var.vm_name }))
          }
        }
      }
    }
  }

  disks {
    disk_address {
      bus_type = "SCSI"
      index    = 0
    }
    backing_info {
      vm_disk {
        data_source {
          reference {
            image_reference {
              image_ext_id = data.nutanix_images_v2.<IMAGE NAME>.images[0].ext_id
            }
          }
        }
      }
    }
  }

  boot_config {
    uefi_boot {
      boot_order = ["DISK", "NETWORK", "CDROM", ]
    }
  }

  nics {
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = data.nutanix_subnets_v2.<SUBNET NAME>.subnets[0].ext_id
      }
      vlan_mode = "ACCESS"
    }
  }

  power_state = "OFF"
}
