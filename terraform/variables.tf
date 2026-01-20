variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node_name" {
  description = "Proxmox node name to deploy VMs to"
  type        = string
  default     = "njord"  # Common default, adjust as needed
}

variable "proxmox_storage" {
  description = "Proxmox storage pool for VM disks and images"
  type        = string
  default     = "local-lvm"  # Common default, adjust as needed
}

variable "proxmox_ssh_address" {
  description = "SSH address for Proxmox node (if different from API address)"
  type        = string
  default     = "njord.t"
}
