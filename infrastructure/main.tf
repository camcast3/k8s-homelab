terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.2-rc05"
    }
  }
}

provider "proxmox" {
  pm_api_url        = var.pvebeast_url
  pm_api_token_id   = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure   = true
  pm_log_enable = true
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_debug      = true
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}

resource "proxmox_vm_qemu" "vm_on_host1" {
  name        = "host1-vm"
  target_node = "pvebeast"
  vmid        = 501
  
  cpu {
    cores = 2
  }
  
  memory      = 2048
  
  # Boot order - use 'c' for disk, 'd' for CD-ROM
  boot        = "order=scsi0;ide2"
  
  # Disk configuration
  disks {
    scsi {
      scsi0 {
        disk {
          size    = "20G"
          storage = "local"
        }
      }
    }
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/talos-metal-amd64-v1.11.5.iso"
        }
      }
    }
  }
  
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
}