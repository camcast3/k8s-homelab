# =============================================================================
# Talos Worker VMs
# =============================================================================

resource "proxmox_vm_qemu" "talos_worker" {
  count = var.worker_count

  name        = "talos-worker-${count.index + 1}"
  target_node = count.index % 2 == 0 ? var.proxmox_node_1 : var.proxmox_node_2
  vmid        = 510 + count.index

  # Clone from Talos ISO
  clone      = null
  full_clone = false
  iso        = var.talos_iso

  # VM Resources
  cores   = var.worker_cores
  sockets = 1
  memory  = var.worker_memory_gb * 1024
  scsihw  = "virtio-scsi-single"
  
  # Boot configuration
  boot    = "order=scsi0;net0"
  onboot  = true
  startup = "order=2,up=30"

  # Disks
  disks {
    scsi {
      scsi0 {
        disk {
          size    = var.worker_disk_size_gb
          storage = count.index % 2 == 0 ? var.proxmox_node_1_storage : var.proxmox_node_2_storage
          format  = "raw"
        }
      }
    }
    ide {
      ide0 {
        cdrom {
          iso = var.talos_iso
        }
      }
    }
  }

  # Network
  network {
    model  = "virtio"
    bridge = count.index % 2 == 0 ? var.proxmox_node_1_bridge : var.proxmox_node_2_bridge
  }

  # VM Settings
  agent   = 0
  cpu     = "host"
  numa    = false
  hotplug = "network,disk,usb"

  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
      disks,
    ]
  }

  # Ensure workers start after control plane
  depends_on = [proxmox_vm_qemu.talos_control]

  # Wait for VM to be accessible
  provisioner "local-exec" {
    command = "sleep 30"
  }

  # Check if Talos is responding
  provisioner "local-exec" {
    command = <<-EOT
      for i in {1..60}; do
        if talosctl version --nodes ${var.worker_ip_prefix}${var.worker_ip_start + count.index} --insecure 2>/dev/null; then
          echo "Talos node ${self.name} is ready"
          exit 0
        fi
        echo "Waiting for Talos node ${self.name} to respond... ($i/60)"
        sleep 10
      done
      echo "Warning: Talos node ${self.name} did not respond in time, continuing anyway..."
      exit 0
    EOT
    when = create
  }
}

# Output worker IPs for easy reference
output "worker_ips" {
  description = "Worker node IP addresses"
  value = [
    for idx in range(var.worker_count) :
    "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
  ]
}