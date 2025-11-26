# =============================================================================
# Outputs - Redesigned to capture actual and expected IPs
# =============================================================================

# Control Plane Nodes - Actual IP Discovery
output "control_plane_nodes" {
  description = "Control plane nodes with actual and expected IPs"
  value = {
    for idx, vm in proxmox_vm_qemu.talos_control : vm.name => {
      vmid            = vm.vmid
      proxmox_node    = vm.target_node
      expected_ip     = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
      actual_ip       = try(vm.default_ipv4_address, "pending")
      mac_address     = try(vm.network[0].macaddr, "pending")
      ssh_host        = try(vm.ssh_host, "pending")
      agent_enabled   = vm.agent == 1
    }
  }
}

# Worker Nodes - Actual IP Discovery
output "worker_nodes" {
  description = "Worker nodes with actual and expected IPs"
  value = {
    for idx, vm in proxmox_vm_qemu.talos_worker : vm.name => {
      vmid            = vm.vmid
      proxmox_node    = vm.target_node
      expected_ip     = "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
      actual_ip       = try(vm.default_ipv4_address, "pending")
      mac_address     = try(vm.network[0].macaddr, "pending")
      ssh_host        = try(vm.ssh_host, "pending")
      agent_enabled   = vm.agent == 1
    }
  }
}

# Flattened list for Ansible consumption
output "control_plane_ips_map" {
  description = "Control plane IP mapping for Ansible"
  value = [
    for idx, vm in proxmox_vm_qemu.talos_control : {
      name        = vm.name
      vmid        = vm.vmid
      expected_ip = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
      actual_ip   = try(vm.default_ipv4_address, "")
      mac         = try(vm.network[0].macaddr, "")
    }
  ]
}

output "worker_ips_map" {
  description = "Worker IP mapping for Ansible"
  value = [
    for idx, vm in proxmox_vm_qemu.talos_worker : {
      name        = vm.name
      vmid        = vm.vmid
      expected_ip = "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
      actual_ip   = try(vm.default_ipv4_address, "")
      mac         = try(vm.network[0].macaddr, "")
    }
  ]
}

# JSON output for Ansible to consume
output "cluster_nodes_json" {
  description = "All cluster nodes in JSON format for Ansible"
  value = jsonencode({
    control_plane = {
      for idx, vm in proxmox_vm_qemu.talos_control : vm.name => {
        vmid        = vm.vmid
        expected_ip = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
        actual_ip   = try(vm.default_ipv4_address, "")
        mac         = try(vm.network[0].macaddr, "")
        node        = vm.target_node
      }
    }
    workers = {
      for idx, vm in proxmox_vm_qemu.talos_worker : vm.name => {
        vmid        = vm.vmid
        expected_ip = "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
        actual_ip   = try(vm.default_ipv4_address, "")
        mac         = try(vm.network[0].macaddr, "")
        node        = vm.target_node
      }
    }
  })
}

# Legacy outputs (kept for compatibility)
output "control_plane_distribution" {
  description = "Control plane VM distribution across Proxmox nodes"
  value = {
    for idx, vm in proxmox_vm_qemu.talos_control : vm.name => {
      proxmox_node = vm.target_node
      vmid         = vm.vmid
      expected_ip  = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
      actual_ip    = try(vm.default_ipv4_address, "pending")
      mac          = try(vm.network[0].macaddr, "pending")
    }
  }
}

output "worker_distribution" {
  description = "Worker VM distribution across Proxmox nodes"
  value = {
    for idx, vm in proxmox_vm_qemu.talos_worker : vm.name => {
      proxmox_node = vm.target_node
      vmid         = vm.vmid
      expected_ip  = "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
      actual_ip    = try(vm.default_ipv4_address, "pending")
      mac          = try(vm.network[0].macaddr, "pending")
    }
  }
}

# Cluster Summary
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
        for idx, vm in proxmox_vm_qemu.talos_control : {
          name         = vm.name
          vmid         = vm.vmid
          expected_ip  = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
          actual_ip    = try(vm.default_ipv4_address, "pending")
          proxmox_host = vm.target_node
          mac          = try(vm.network[0].macaddr, "pending")
        }
      ]
    }
    
    workers = {
      count = var.worker_count
      nodes = [
        for idx, vm in proxmox_vm_qemu.talos_worker : {
          name         = vm.name
          vmid         = vm.vmid
          expected_ip  = "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
          actual_ip    = try(vm.default_ipv4_address, "pending")
          proxmox_host = vm.target_node
          mac          = try(vm.network[0].macaddr, "pending")
        }
      ]
    }
  }
}

# Generate Ansible Inventory with actual IPs
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    control_nodes = [
      for idx, vm in proxmox_vm_qemu.talos_control : {
        name        = vm.name
        vmid        = vm.vmid
        expected_ip = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
        actual_ip   = try(vm.default_ipv4_address, "")
        mac         = try(vm.network[0].macaddr, "00:00:00:00:00:00")
      }
    ]
    worker_nodes = [
      for idx, vm in proxmox_vm_qemu.talos_worker : {
        name        = vm.name
        vmid        = vm.vmid
        expected_ip = "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
        actual_ip   = try(vm.default_ipv4_address, "")
        mac         = try(vm.network[0].macaddr, "00:00:00:00:00:00")
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

# Write JSON file for Ansible to consume
resource "local_file" "cluster_nodes_json" {
  content = jsonencode({
    control_plane_nodes = [
      for idx, vm in proxmox_vm_qemu.talos_control : {
        name        = vm.name
        vmid        = vm.vmid
        expected_ip = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
        actual_ip   = try(vm.default_ipv4_address, "")
        mac         = try(vm.network[0].macaddr, "")
        node        = vm.target_node
      }
    ]
    worker_nodes = [
      for idx, vm in proxmox_vm_qemu.talos_worker : {
        name        = vm.name
        vmid        = vm.vmid
        expected_ip = "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
        actual_ip   = try(vm.default_ipv4_address, "")
        mac         = try(vm.network[0].macaddr, "")
        node        = vm.target_node
      }
    ]
    cluster_info = {
      name               = var.cluster_name
      vip                = var.cluster_vip
      gateway            = var.gateway
      nameservers        = var.nameservers
      kubernetes_version = var.kubernetes_version
    }
  })
  filename = "${path.module}/../ansible/vars/cluster_nodes.json"

  depends_on = [
    proxmox_vm_qemu.talos_control,
    proxmox_vm_qemu.talos_worker
  ]
}

output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}

output "cluster_nodes_json_path" {
  description = "Path to cluster nodes JSON file for Ansible"
  value       = local_file.cluster_nodes_json.filename
}

# Quick reference outputs
output "control_plane_ips" {
  description = "Control plane node expected IP addresses"
  value = [
    for idx in range(var.control_plane_count) :
    "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
  ]
}

output "worker_ips" {
  description = "Worker node expected IP addresses"
  value = [
    for idx in range(var.worker_count) :
    "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
  ]
}

output "cluster_endpoint" {
  description = "Kubernetes cluster API endpoint"
  value       = "https://${var.cluster_vip}:6443"
}

# VMIDs for reference
output "control_plane_vmids" {
  description = "Control plane VMIDs"
  value = [
    for vm in proxmox_vm_qemu.talos_control : vm.vmid
  ]
}

output "worker_vmids" {
  description = "Worker VMIDs"
  value = [
    for vm in proxmox_vm_qemu.talos_worker : vm.vmid
  ]
}