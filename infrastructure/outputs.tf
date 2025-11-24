# =============================================================================
# Outputs
# =============================================================================

# Control Plane Nodes Distribution
output "control_plane_distribution" {
  description = "Control plane VM distribution across Proxmox nodes"
  value = {
    for idx, vm in proxmox_vm_qemu.talos_control : vm.name => {
      proxmox_node = vm.target_node
      vmid         = vm.vmid
      ip           = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
      mac          = try(vm.network[0].macaddr, "pending")
    }
  }
}

# Worker Nodes Distribution
output "worker_distribution" {
  description = "Worker VM distribution across Proxmox nodes"
  value = {
    for idx, vm in proxmox_vm_qemu.talos_worker : vm.name => {
      proxmox_node = vm.target_node
      vmid         = vm.vmid
      ip           = "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
      mac          = try(vm.network[0].macaddr, "pending")
    }
  }
}

# All Nodes Summary
output "cluster_summary" {
  description = "Complete cluster configuration summary"
  value = {
    cluster_name       = var.cluster_name
    cluster_vip        = var.cluster_vip
    kubernetes_version = var.kubernetes_version
    proxmox_nodes      = var.proxmox_nodes
    
    control_plane = {
      count = var.control_plane_count
      nodes = [
        for idx in range(var.control_plane_count) : {
          name         = "talos-control-${idx + 1}"
          vmid         = 500 + idx
          ip           = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
          proxmox_host = var.proxmox_nodes[idx % length(var.proxmox_nodes)]
        }
      ]
    }
    
    workers = {
      count = var.worker_count
      nodes = [
        for idx in range(var.worker_count) : {
          name         = "talos-worker-${idx + 1}"
          vmid         = 510 + idx
          ip           = "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
          proxmox_host = var.proxmox_nodes[idx % length(var.proxmox_nodes)]
        }
      ]
    }
  }
}

# Generate Ansible Inventory (only after VMs are created)
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    control_nodes = [
      for idx in range(var.control_plane_count) : {
        name = "talos-control-${idx + 1}"
        ip   = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
        mac  = try(proxmox_vm_qemu.talos_control[idx].network[0].macaddr, "00:00:00:00:00:00")
      }
    ]
    worker_nodes = [
      for idx in range(var.worker_count) : {
        name = "talos-worker-${idx + 1}"
        ip   = "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
        mac  = try(proxmox_vm_qemu.talos_worker[idx].network[0].macaddr, "00:00:00:00:00:00")
      }
    ]
    cluster_name       = var.cluster_name
    cluster_vip        = var.cluster_vip
    gateway            = var.gateway
    nameservers        = var.nameservers
    kubernetes_version = var.kubernetes_version
  })
  filename = "${path.module}/../ansible/inventory/hosts.yml"

  depends_on = [
    proxmox_vm_qemu.talos_control,
    proxmox_vm_qemu.talos_worker
  ]
}

output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}

# Quick reference outputs
output "control_plane_ips" {
  description = "Control plane node IP addresses"
  value = [
    for idx in range(var.control_plane_count) :
    "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
  ]
}

output "worker_ips" {
  description = "Worker node IP addresses"
  value = [
    for idx in range(var.worker_count) :
    "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
  ]
}

output "cluster_endpoint" {
  description = "Kubernetes cluster API endpoint"
  value       = "https://${var.cluster_vip}:6443"
}