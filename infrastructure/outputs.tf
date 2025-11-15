# =============================================================================
# VM Outputs
# =============================================================================

output "control_plane_nodes" {
  description = "Control plane node details"
  value = [
    for i, vm in proxmox_vm_qemu.talos_control : {
      name        = vm.name
      vmid        = vm.vmid
      target_node = vm.target_node
      mac         = vm.network[0].macaddr
      ip          = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + i}"
      proxmox_ip  = vm.default_ipv4_address
    }
  ]
}

output "worker_nodes" {
  description = "Worker node details"
  value = [
    for i, vm in proxmox_vm_qemu.talos_worker : {
      name        = vm.name
      vmid        = vm.vmid
      target_node = vm.target_node
      mac         = vm.network[0].macaddr
      ip          = "${var.worker_ip_prefix}${var.worker_ip_start + i}"
      proxmox_ip  = vm.default_ipv4_address
    }
  ]
}

output "cluster_endpoints" {
  description = "Cluster endpoint information"
  value = {
    cluster_vip = var.cluster_vip
    api_url     = "https://${var.cluster_vip}:6443"
    control_ips = [
      for i in range(var.control_plane_count) :
      "${var.control_plane_ip_prefix}${var.control_plane_ip_start + i}"
    ]
  }
}

output "node_distribution" {
  description = "VM distribution across Proxmox nodes"
  value = {
    proxmox_node_1 = {
      control_plane = [
        for i, vm in proxmox_vm_qemu.talos_control : vm.name
        if vm.target_node == var.proxmox_node_1
      ]
      workers = [
        for i, vm in proxmox_vm_qemu.talos_worker : vm.name
        if vm.target_node == var.proxmox_node_1
      ]
    }
    proxmox_node_2 = var.proxmox_node_2 != "" ? {
      control_plane = [
        for i, vm in proxmox_vm_qemu.talos_control : vm.name
        if vm.target_node == var.proxmox_node_2
      ]
      workers = [
        for i, vm in proxmox_vm_qemu.talos_worker : vm.name
        if vm.target_node == var.proxmox_node_2
      ]
    } : null
  }
}

# =============================================================================
# Ansible Inventory Generation
# =============================================================================

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    control_nodes = [
      for i in range(var.control_plane_count) : {
        name = "talos-control-${i + 1}"
        ip   = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + i}"
        mac  = proxmox_vm_qemu.talos_control[i].network[0].macaddr
      }
    ]
    worker_nodes = [
      for i in range(var.worker_count) : {
        name = "talos-worker-${i + 1}"
        ip   = "${var.worker_ip_prefix}${var.worker_ip_start + i}"
        mac  = proxmox_vm_qemu.talos_worker[i].network[0].macaddr
      }
    ]
    cluster_name = var.cluster_name
    cluster_vip  = var.cluster_vip
    gateway      = var.gateway
    nameservers  = var.nameservers
  })
  filename = "${path.module}/../ansible/inventory/hosts.yml"
}

output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}
