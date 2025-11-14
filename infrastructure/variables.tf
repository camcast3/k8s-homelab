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