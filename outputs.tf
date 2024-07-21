output "vm_details" {
  description = "Details of each VM including public IP, private IP, and hostname, etc."
  sensitive = true
  value = [
    for index in range(length(azurerm_linux_virtual_machine.vm)) : {
      hostname   = azurerm_linux_virtual_machine.vm[index].name
      public_ip  = azurerm_public_ip.main[index].ip_address
      private_ip = azurerm_network_interface.vm_nic[index].ip_configuration[0].private_ip_address
	  password   = random_password.admin_password[index].result
	  vm_flavor = azurerm_linux_virtual_machine.vm[index].size
	  vm_image = azurerm_linux_virtual_machine.vm[index].source_image_reference
    }
  ]
}