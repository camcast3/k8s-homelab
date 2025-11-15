# =============================================================================
# Outputs
# =============================================================================

# Control Plane Nodes
output "control_plane_nodes" {
  description = "Control plane node details"
  value = {
    for idx, vm in proxmox_vm_qemu.talos_control : vm.name => {
      vmid             = vm.vmid
      target_node      = vm.target_node
      mac_address      = vm.network[0].macaddr
      expected_ip      = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
      # Proxmox may provide the actual IP via agent or network info
      actual_ip        = try(vm.default_ipv4_address, "pending")
    }
  }
}

# Worker Nodes
output "worker_nodes" {
  description = "Worker node details"
  value = {
    for idx, vm in proxmox_vm_qemu.talos_worker : vm.name => {
      vmid             = vm.vmid
      target_node      = vm.target_node
      mac_address      = vm.network[0].macaddr
      expected_ip      = "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
      actual_ip        = try(vm.default_ipv4_address, "pending")
    }
  }
}

# Get actual IPs from Proxmox network data
data "external" "control_plane_ips" {
  count   = var.control_plane_count
  program = ["bash", "-c", <<-EOT
    ssh -o StrictHostKeyChecking=no root@${count.index % 2 == 0 ? split("//", var.pvebeast_url)[1] : var.proxmox_node_1} \
      "qm guest cmd ${500 + count.index} network-get-interfaces 2>/dev/null | jq -r '.[] | select(.name==\"eth0\") | .[\"ip-addresses\"][] | select(.\"ip-address-type\"==\"ipv4\") | .[\"ip-address\"]' || echo '{}'" | \
      jq -R -s '{ip: .}'
  EOT
  ]
  
  depends_on = [proxmox_vm_qemu.talos_control]
}

data "external" "worker_ips" {
  count   = var.worker_count
  program = ["bash", "-c", <<-EOT
    ssh -o StrictHostKeyChecking=no root@${count.index % 2 == 0 ? split("//", var.pvebeast_url)[1] : var.proxmox_node_1} \
      "qm guest cmd ${510 + count.index} network-get-interfaces 2>/dev/null | jq -r '.[] | select(.name==\"eth0\") | .[\"ip-addresses\"][] | select(.\"ip-address-type\"==\"ipv4\") | .[\"ip-address\"]' || echo '{}'" | \
      jq -R -s '{ip: .}'
  EOT
  ]
  
  depends_on = [proxmox_vm_qemu.talos_worker]
}

# Generate Ansible Inventory with actual DHCP IPs
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    control_nodes = [
      for idx, vm in proxmox_vm_qemu.talos_control : {
        name        = vm.name
        mac         = vm.network[0].macaddr
        expected_ip = "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}"
        dhcp_ip     = try(data.external.control_plane_ips[idx].result.ip, "${var.control_plane_ip_prefix}${var.control_plane_ip_start + idx}")
      }
    ]
    worker_nodes = [
      for idx, vm in proxmox_vm_qemu.talos_worker : {
        name        = vm.name
        mac         = vm.network[0].macaddr
        expected_ip = "${var.worker_ip_prefix}${var.worker_ip_start + idx}"
        dhcp_ip     = try(data.external.worker_ips[idx].result.ip, "${var.worker_ip_prefix}${var.worker_ip_start + idx}")
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
    proxmox_vm_qemu.talos_worker,
    data.external.control_plane_ips,
    data.external.worker_ips
  ]
}

output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}
