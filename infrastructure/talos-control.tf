# =============================================================================
# Talos Control Plane VMs
# =============================================================================

locals {
  control_node_assignments = [
    for idx in range(var.control_plane_count) :
    idx % length(var.proxmox_nodes)
  ]
}

resource "proxmox_vm_qemu" "talos_control" {
  count = var.control_plane_count

  name        = "talos-control-${count.index + 1}"
  target_node = var.proxmox_nodes[local.control_node_assignments[count.index]]
  vmid        = 500 + count.index

  # No clone - creating fresh VM
  clone      = null
  full_clone = false

  # CPU Configuration
  cpu {
    cores   = var.control_plane_cores
    sockets = 1
    type    = "host"
    numa    = false
  }

  # Memory
  memory  = var.control_plane_memory_gb * 1024
  scsihw  = "virtio-scsi-pci"  # VirtIO SCSI (not single)
  
  # Boot configuration - Talos recommended
  boot    = "order=ide2;scsi0"  # Boot from CD-ROM first, then disk
  bios    = "ovmf"              # UEFI
  machine = "q35"               # Q35 machine type
  onboot  = false
  startup = ""

  # Disks - IDE CD-ROM + SCSI disk
  disks {
    ide {
      ide2 {
        cdrom {
          iso = var.talos_iso
        }
      }
    }
    scsi {
      scsi0 {
        disk {
          size       = var.control_plane_disk_size_gb
          storage    = var.proxmox_storage[local.control_node_assignments[count.index]]
          discard    = true      # Enable discard
          emulatessd = true      # SSD emulation
          iothread   = true      # Enable IO thread
          format     = "raw"
        }
      }
    }
  }

  # Network
  network {
    id     = 0
    model  = "virtio"
    bridge = var.proxmox_bridge[local.control_node_assignments[count.index]]
  }

  # EFI disk for UEFI boot
  efidisk {
    efitype = "4m"
    storage = var.proxmox_storage[local.control_node_assignments[count.index]]
  }

  # VM Settings
  agent   = 1
  hotplug = "disk,network,usb"  # No memory or CPU hotplug for Talos

  lifecycle {
    ignore_changes = [
      network,
      disks,
    ]
  }
}