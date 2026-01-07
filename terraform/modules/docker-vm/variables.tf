variable "hostname" {
  description = "VM hostname"
  type        = string
}

variable "description" {
  description = "VM description"
  type        = string
  default     = "Docker VM"
}

variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "vm_id" {
  description = "VM ID"
  type        = number
}

variable "start_on_boot" {
  description = "Start VM on boot"
  type        = bool
  default     = true
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 32
}

variable "datastore_id" {
  description = "Datastore for VM disk"
  type        = string
  default     = "local-lvm"
}

variable "snippets_datastore_id" {
  description = "Datastore for cloud-init snippets (must support 'snippets' content type)"
  type        = string
  default     = "local"
}

variable "template_vm_id" {
  description = "Template VM ID to clone from"
  type        = number
  default     = 8000
}

variable "network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "Static IP address in CIDR notation (e.g., 192.168.1.100/24) or empty for DHCP"
  type        = string
  default     = "dhcp"
}

variable "ip_gateway" {
  description = "IP gateway (required if using static IP)"
  type        = string
  default     = "192.168.0.1"
}