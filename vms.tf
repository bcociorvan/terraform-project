resource "random_password" "admin_password" {
  count   = var.vm_count
  length  = var.admin_password_length
  special = true
}

resource "azurerm_network_interface" "vm_nic" {
  count               = var.vm_count
  name                = "vm-nic-${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main[count.index].id
  }
}

resource "azurerm_public_ip" "main" {
  count               = var.vm_count
  name                = "main-pip-${count.index}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
}

locals {
  vm_flavors = merge([
    for flavor, indices in var.additional_vm_flavor_indices : {
      for idx in indices : tostring(idx) => flavor
    }
  ]...)

  vm_images = merge([
    for image_key, indices in var.additional_vm_image_indices : {
      for idx in indices : tostring(idx) => var.additional_vm_images[image_key]
    }
  ]...)
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                = var.vm_count
  name                 = "vm-${count.index}"
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  size                 = lookup(local.vm_flavors, tostring(count.index), var.default_vm_flavor)
  admin_username       = var.admin_username
  disable_password_authentication = false
  admin_password       = random_password.admin_password[count.index].result
  network_interface_ids = [azurerm_network_interface.vm_nic[count.index].id]
 


# admin_ssh_key {
#    username       = var.admin_username
#    public_key = file("~/.ssh/id_rsa.pub")
#  }


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Determine VM image
  source_image_reference {
    publisher = lookup(local.vm_images, tostring(count.index), var.default_vm_image)["publisher"]
    offer     = lookup(local.vm_images, tostring(count.index), var.default_vm_image)["offer"]
    sku       = lookup(local.vm_images, tostring(count.index), var.default_vm_image)["sku"]
    version   = lookup(local.vm_images, tostring(count.index), var.default_vm_image)["version"]
  }


  provisioner "local-exec" {
    command = <<-EOT
      echo "VM ${count.index} is ready" > vm_${count.index}_ready.txt
    EOT

    on_failure = continue  # Ignore failure if VM is not accessible momentarily
  }
}



# Null resource to run script after all VMs are up
resource "null_resource" "run_after_vms" {
  # Make sure this runs after all VMs are provisioned
  depends_on = [
  azurerm_linux_virtual_machine.vm,
  azurerm_public_ip.main]
  
  count = var.vm_count
  
  provisioner "remote-exec" {
    inline = [
      "echo 'Hello from VM ${count.index}' > /tmp/output.txt",
      "cat /tmp/output.txt"
    ]

    connection {
      type     = "ssh"
      user     = var.admin_username
      #private_key = file("~/.ssh/id_rsa")
      password = random_password.admin_password[count.index].result
      host     = azurerm_public_ip.main[count.index].ip_address
      #host = azurerm_network_interface.vm_nic[count.index].ip_configuration[0].private_ip_address
      timeout  = "2m"
    }
  }
}

# Null resource to run script after all VMs are up
resource "null_resource" "run_ping" {
  depends_on = [null_resource.run_after_vms]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOF
    vm_count=${var.vm_count}
    #add a mechanism to ensure safe and atomic writes to combined_output.txt file from multiple processes, ensuring that only one process writes at a time
    lockfile=/tmp/combined_output.lock
    vm_info=$(cat <<'JSON'
    [
      %{ for idx in range(var.vm_count) }
      {
        "current_ip": "${azurerm_public_ip.main[idx].ip_address}",
        "next_private_ip": "${azurerm_network_interface.vm_nic[(idx + 1) % var.vm_count].private_ip_address}",
        "current_vm": "${azurerm_linux_virtual_machine.vm[idx].name}",
        "next_vm": "${azurerm_linux_virtual_machine.vm[(idx + 1) % var.vm_count].name}",
        "current_private_ip": "${azurerm_network_interface.vm_nic[idx].ip_configuration[0].private_ip_address}",
        "password": "${random_password.admin_password[idx].result}"
      }%{ if idx < var.vm_count - 1 },%{ endif }
      %{ endfor }
    ]
    JSON
    )
    #echo "$vm_info" > out.txt  # Initial VM info to a JSON file, for debug
    echo "Starting loop through VMs"
    
    # Ensure the output file is empty before starting the commands
    > combined_output.txt


    echo "$vm_info" | jq -c '.[]' | while IFS= read -r vm; do
      current_ip=$(echo "$vm" | jq -r '.current_ip')
      next_private_ip=$(echo "$vm" | jq -r '.next_private_ip')
      current_vm=$(echo "$vm" | jq -r '.current_vm')
      next_vm=$(echo "$vm" | jq -r '.next_vm')
      current_private_ip=$(echo "$vm" | jq -r '.current_private_ip')
      password=$(echo "$vm" | jq -r '.password')

      # Running ping commands on VMs and appending outputs to a single output file
      sshpass -p "$password" ssh -o StrictHostKeyChecking=no ${var.admin_username}@$current_ip \
      "ping -c 1 $next_private_ip > /dev/null && echo 'Ping from machine $current_vm with IP $current_private_ip to machine $next_vm with IP $next_private_ip -> PASS' || echo 'Ping from machine $current_vm with IP $current_private_ip to machine $next_vm with IP $next_private_ip -> FAIL'" | while IFS= read -r line; do
        (
          flock -x 200
          echo "$line" >> combined_output.txt
        ) 200>$lockfile
      done &
    done
    wait # Wait for all background processes to complete
    EOF
  }
}

data "external" "file_content" {
  depends_on = [null_resource.run_ping]

  program = ["/bin/bash", "-c", <<EOF
    content=$(jq -Rs . < combined_output.txt)
    echo "{\"content\": $content}"
  EOF
  ]
}

output "combined_output" {
  value = data.external.file_content.result["content"]
  description = "Combined ping results from all VMs"
}

