subscription_id = "<subscription_id>"
client_id       = "<client_id>"
client_secret   = "<client_id>"
tenant_id       = "<tenant_id>"
resource_group_name = "vm-ping-test-rg"
location = "westus2"
vm_count = 6
admin_username = "azureuser"
admin_password_length = 16
additional_vm_image_indices = {
  "OpenLogic" = [2, 3, 4, 8, 1]
  "RedHat"    = [1, 3, 2, 7, 10, 14]
}
additional_vm_flavor_indices = {
  "Standard_B2s"     = [0, 1, 9]
  "Standard_D2s_v3"  = [1, 3, 4, 6]
}