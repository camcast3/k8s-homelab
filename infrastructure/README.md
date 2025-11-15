# Talos Homelab Infrastructure

This Terraform configuration provisions a Talos Linux Kubernetes cluster on Proxmox.

## Architecture

- **Control Plane**: 3 nodes (2 on node_1, 1 on node_2)
- **Workers**: 4 nodes (2 on node_1, 2 on node_2)
- **Network**: Static IPs configured via Talos
- **OS**: Talos Linux

## Prerequisites

1. **Proxmox VE** with API token configured (2 nodes recommended for HA)
2. **Talos ISO** uploaded to Proxmox storage on both nodes
3. **OpenTofu/Terraform** installed

## Configuration

### 1. Create `creds.auto.tfvars`

```hcl
# Proxmox credentials
proxmox_token_id     = "opentofu-prov@pve!your-token-name"
proxmox_token_secret = "your-secret-here"
```

### 2. Create `machines.auto.tfvars`

```hcl
# Proxmox settings
pvebeast_url           = "https://192.168.1.2:8006/api2/json"
proxmox_node_1         = "proxmox"
proxmox_node_2         = "proxmox2"
proxmox_node_1_storage = "local"
proxmox_node_2_storage = "local-lvm"
proxmox_node_1_bridge  = "vmbr0"
proxmox_node_2_bridge  = "vmbr0"

# Cluster configuration
cluster_name = "homelab"
cluster_vip  = "192.168.1.100"

# Control plane nodes (3 total: 2 on node_1, 1 on node_2)
control_plane_count     = 3
control_plane_cores     = 2
control_plane_memory    = 4096
control_plane_disk_size = "50G"
control_plane_ip_start  = 50  # IPs: 192.168.1.50-52

# Worker nodes (4 total: 2 on node_1, 2 on node_2)
worker_count     = 4
worker_cores     = 4
worker_memory    = 8192
worker_disk_size = "100G"
worker_ip_start  = 60  # IPs: 192.168.1.60-63

# Network
gateway     = "192.168.1.1"
nameservers = ["192.168.1.1"]
```

## Usage

### Deploy Infrastructure

```bash
# Initialize Terraform
tofu init

# Preview changes
tofu plan -out=tfplan

# Apply configuration
tofu apply tfplan

# View outputs
tofu output
```

### Clean Up

```bash
# Destroy all resources
tofu destroy
```

## File Structure

```
infrastructure/
├── main.tf                  # Provider configuration
├── variables.tf             # Variable declarations
├── outputs.tf               # Output values and Ansible inventory
├── talos-control.tf         # Control plane VMs (2 on node_1, 1 on node_2)
├── talos-workers.tf         # Worker VMs (2 on node_1, 2 on node_2)
├── unifi.tf                 # DHCP reservation info output
├── templates/
│   └── inventory.tpl        # Ansible inventory template
├── creds.auto.tfvars        # Credentials (gitignored)
├── machines.auto.tfvars     # Machine configuration (gitignored)
└── README.md                # This file
```

## Node Distribution

VMs are automatically distributed across Proxmox nodes for high availability:

**Control Plane:**
- `talos-control-1` → node_1
- `talos-control-2` → node_1
- `talos-control-3` → node_2

**Workers:**
- `talos-worker-1` → node_1
- `talos-worker-2` → node_2
- `talos-worker-3` → node_2

## Next Steps

After infrastructure is provisioned:

1. VMs boot from Talos ISO and obtain temporary DHCP IPs
2. Run Ansible playbook to configure Talos with static IPs
3. Bootstrap Kubernetes cluster

See `../ansible/README.md` for Ansible configuration steps.

## Outputs

- `control_plane_nodes` - Control plane node details (name, IP, MAC, VMID, target_node)
- `worker_nodes` - Worker node details
- `cluster_endpoints` - Cluster VIP and API endpoint
- `node_distribution` - Shows which VMs are on which Proxmox nodes
- `dhcp_reservation_info` - MAC/IP pairs for manual DHCP reservation (optional)
- `ansible_inventory_path` - Path to generated inventory file

## Notes

- **Static IPs**: Talos configures static IPs directly (no DHCP dependency)
- **DHCP Reservations**: Optional - use `dhcp_reservation_info` output to manually create in UniFi/router for DNS
- **KVM**: VMs use software emulation (KVM disabled) - enable KVM in BIOS for better performance
- **HA**: VMs distributed across 2 Proxmox nodes for high availability
- **Storage**: Each node can use different storage (local, local-lvm, ZFS, etc.)
- **State**: Files stored locally - consider remote backend for production
