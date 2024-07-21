variable "subscription_id" {
  description = "The Azure subscription ID"
}

variable "client_id" {
  description = "The Client ID for the Azure service principal"
}

variable "client_secret" {
  description = "The Client Secret for the Azure service principal"
}

variable "tenant_id" {
  description = "The Tenant ID for the Azure service principal"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  default     = "vm-ping-test-rg"
}

variable "location" {
  description = "The Azure region to create resources in"
  default     = "westus2"
}

variable "vm_count" {
  description = "Number of VMs to create (between 2 and 100)"
  type        = number
  default     = 5
  validation {
    condition = var.vm_count >= 2 && var.vm_count <= 100
    error_message = "Number of VMs must be between 2 and 100"
  }
}

# Define default VM flavor and image
variable "default_vm_flavor" {
  description = "Default VM flavor"
  type        = string
  default     = "Standard_B1s"
}

variable "default_vm_image" {
  description = "Default VM image"
  type        = map(string)
  default = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

# Define lists of VM indices for additional flavors and images
variable "additional_vm_flavor_indices" {
  description = "Map of specific VM indices to additional flavors"
  type        = map(list(number))
  default     = {
    "Standard_B2s" = [],
    "Standard_D2s_v3" = []
  }
}

variable "additional_vm_image_indices" {
  description = "Map of specific VM indices to additional images"
  type        = map(list(number))
  default     = {
    "RedHat" = [],
    "OpenLogic" = []
  }
}

variable "additional_vm_images" {
  description = "Map of image details for additional images"
  type        = map(map(string))
  default     = {
    "RedHat" = {
      publisher = "RedHat"
      offer     = "RHEL"
      sku       = "8-lvm"
      version   = "latest"
    },
    "OpenLogic" = {
      publisher = "OpenLogic"
      offer     = "CentOS"
      sku       = "7.9"
      version   = "latest"
    }
  }
}

variable "admin_username" {
  description = "The admin username for the VMs"
  default     = "adminuser"
}

variable "admin_password_length" {
  description = "The length of the generated admin password"
  type        = number
  default     = 16
}
