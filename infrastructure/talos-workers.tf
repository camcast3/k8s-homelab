# Talos Worker Nodes
# Distribution: 2 nodes on node_1, 2 nodes on node_2

locals {
  # Worker distribution pattern: [node_1, node_1, node_2, node_2]
  worker_distribution = [
    var.proxmox_node_1,
    var.proxmox_node_2,
    var.proxmox_node_2,
  ]

  # Convert GB to MB for Proxmox
  worker_memory_mb = var.worker_memory_gb * 1024
  worker_disk_size = "${var.worker_disk_size_gb}G"
}

resource "proxmox_vm_qemu" "talos_worker" {
  count       = var.worker_count
  name        = "talos-worker-${count.index + 1}"
  target_node = local.worker_distribution[count.index]
  vmid        = 511 + count.index

  cpu {
    cores = var.worker_cores
  }

  memory = local.worker_memory_mb
  boot   = "order=scsi0;ide2"
  kvm    = true

  disks {
    scsi {
      scsi0 {
        disk {
          size    = local.worker_disk_size
          storage = local.proxmox_nodes[local.worker_distribution[count.index]].storage
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
    bridge = local.proxmox_nodes[local.worker_distribution[count.index]].bridge
  }

  lifecycle {
    ignore_changes = [
      boot,
      network,
    ]
  }
}
