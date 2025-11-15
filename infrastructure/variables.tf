# =============================================================================
# Proxmox Provider Variables
# =============================================================================

variable "pvebeast_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_token_id" {
  description = "Proxmox API Token ID"
  type        = string
}

variable "proxmox_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node_1" {
  description = "Primary Proxmox node name"
  type        = string
  default     = "proxmox"
}

variable "proxmox_node_2" {
  description = "Secondary Proxmox node name (optional, leave empty if only one node)"
  type        = string
  default     = ""
}

variable "proxmox_node_1_storage" {
  description = "Storage name for proxmox_node_1"
  type        = string
  default     = "local"
}

variable "proxmox_node_2_storage" {
  description = "Storage name for proxmox_node_2"
  type        = string
  default     = "local"
}

variable "proxmox_node_1_bridge" {
  description = "Network bridge for proxmox_node_1"
  type        = string
  default     = "vmbr0"
}

variable "proxmox_node_2_bridge" {
  description = "Network bridge for proxmox_node_2"
  type        = string
  default     = "vmbr0"
}

# =============================================================================
# Talos Configuration https://docs.siderolabs.com/talos/v1.9/getting-started/system-requirements
# =============================================================================

variable "talos_iso" {
  description = "Path to Talos Linux ISO in Proxmox"
  type        = string
  default     = "local:iso/talos-metal-amd64-v1.11.5.iso"
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

variable "cluster_vip" {
  description = "Kubernetes API VIP (Virtual IP)"
  type        = string
}

# =============================================================================
# Control Plane Configuration
# =============================================================================

variable "control_plane_count" {
  description = "Number of control plane nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.control_plane_count >= 3
    error_message = "Control Plane count must be at least 3 nodes for HA."
  }
}

variable "control_plane_cores" {
  description = "CPU cores for control plane nodes"
  type        = number
  default     = 4

  validation {
    condition     = var.control_plane_cores >= 4
    error_message = "Contol Plane must have at least 4 vCores"
  }
}

variable "control_plane_memory_gb" {
  description = "Memory (MB) for control plane nodes"
  type        = number
  default     = 4

  validation {
    condition     = var.control_plane_memory_gb >= 4
    error_message = "Contol Plane must have at least 4 GB of memory"
  }
}

variable "control_plane_disk_size_gb" {
  description = "Disk size for control plane nodes"
  type        = number
  default     = 100

    validation {
        condition     = var.control_plane_disk_size_gb >= 100
        error_message = "Control Plane disk size must be at least 100 GB"
    }
}

variable "control_plane_ip_prefix" {
  description = "IP prefix for control plane nodes"
  type        = string
}

variable "control_plane_ip_start" {
  description = "Starting IP octet for control plane nodes"
  type        = number
}

# =============================================================================
# Worker Configuration
# =============================================================================

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3

  validation {
    condition     = var.worker_count >= 3
    error_message = "Worker count must be at least 3 nodes for HA."
  }
}

variable "worker_cores" {
  description = "CPU cores for worker nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.worker_cores >= 2
    error_message = "Worker must have at least 2 vCores"
  }
}

variable "worker_memory_gb" {
  description = "Memory (MB) for worker nodes"
  type        = number
  default     = 2

  validation {
    condition     = var.worker_memory_gb >= 2
    error_message = "Worker must have at least 2 GB of memory"
  }
}

variable "worker_disk_size_gb" {
  description = "Disk size for worker nodes in GB"
  type        = number
  default     = 100

  validation {
    condition     = var.worker_disk_size_gb >= 100
    error_message = "Worker disk size must be at least 100 GB"
  }
}

variable "worker_ip_prefix" {
  description = "IP prefix for worker nodes"
  type        = string
}

variable "worker_ip_start" {
  description = "Starting IP octet for worker nodes"
  type        = number
}

# =============================================================================
# Network Configuration
# =============================================================================

variable "gateway" {
  description = "Default gateway"
  type        = string
}

variable "nameservers" {
  description = "DNS nameservers"
  type        = list(string)
}
