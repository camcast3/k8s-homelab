# Talos Control Plane Nodes
# Distribution: 2 nodes on node_1, 1 node on node_2

locals {
  # Define node configuration mapping
  proxmox_nodes = {
    (var.proxmox_node_1) = {
      storage = var.proxmox_node_1_storage
      bridge  = var.proxmox_node_1_bridge
    }
    (var.proxmox_node_2) = {
      storage = var.proxmox_node_2_storage
      bridge  = var.proxmox_node_2_bridge
    }
  }

  # Control plane distribution pattern: [node_1, node_1, node_2]
  control_distribution = [
    var.proxmox_node_1,
    var.proxmox_node_1,
    var.proxmox_node_2,
  ]

  # Convert GB to MB for Proxmox
  control_plane_memory_mb = var.control_plane_memory_gb * 1024
  control_plane_disk_size = "${var.control_plane_disk_size_gb}G"
}

resource "proxmox_vm_qemu" "talos_control" {
  count       = var.control_plane_count
  name        = "talos-control-${count.index + 1}"
  target_node = local.control_distribution[count.index]
  vmid        = 501 + count.index

  cpu {
    cores = var.control_plane_cores
  }

  memory = local.control_plane_memory_mb
  boot   = "order=scsi0;ide2"
  kvm    = true

  disks {
    scsi {
      scsi0 {
        disk {
          size    = local.control_plane_disk_size
          storage = local.proxmox_nodes[local.control_distribution[count.index]].storage
        }
      }
    }
    ide {
      ide2 {
        cdrom {
          iso = var.talos_iso
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = local.proxmox_nodes[local.control_distribution[count.index]].bridge
  }

  lifecycle {
    ignore_changes = [
      boot,
      network,
    ]
  }
}
