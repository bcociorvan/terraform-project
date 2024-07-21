# terraform-project
This terraform code will:
- spawn up a complete infrastructure from scratch in `Azure`
- create a configurable number of VMs (any number between 2 and 100)
- for each VM the following parameters can be specified:
  * the VM flavor
  * the VM image
- if no VM flavor and/or VM image is specified, the default VM flavor is `Standard_B1s` and the default VM image is `UbuntuServer 18.04-LTS`
- VM admin passwords are generated automatically and they are different on each VM
- this code will automatically run a ping from one VM to each other in a round-robin fashion (example: VM-0 -> VM-1, VM-1 -> VM-2, VM-2 -> VM-3, VM-n -> VM-0) and record the result in `combined_output.txt` (`FAIL/PASS` between source and destination)
- the results (ping outputs) are aggregated in one terraform output variable `combined_output`



# Files from the project:
```
├── README.md
├── network.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars
├── variables.tf
└── vms.tf
```
- `providers.tf` file is used to configure the Azure provider
- `network.tf` file is used to define and configure networking resources virtual networks, subnets, network security groups
- `outputs.tf` file is used to define the output variables that will be displayed when the Terraform configuration is applied.
  It will output for each VM: `hostname, public_ip, private_ip, password, vm_flavor, vm_image`
> Note: The output is hidden because it contains sensitive data like passwords (sensitive = true) 
- `vms.tf` file used to define the specific configurations related to virtual machines, also contains the code for automatically run a ping in a round-robin fashion between the VMs
- `variables.tf` file is used to define the variables that Terraform configuration will use. It specifies the variable names, types, default values, and descriptions
- `terraform.tfvars` file is used to assign values to the variables defined in variables.tf. It provides specific values that override any default values specified in the variables.tf file.

# Configuration of terraform.tfvars

```tf
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
  "Standard_B2s"     = [0, 2, 9]
  "Standard_D2s_v3"  = [2, 3, 4, 6]
}
```
- and your Azure `subscription_id, client_id, client_secret, client_secret`
- define `resource_group_name`
- define `location`
- `vm_count` define how many VMs will be deployed in Azure (between 2 and 100)
- `admin_username` define admin username
- `admin_password_length` define admin password lenght
- `additional_vm_image_indices`  define VMs with custom VM image
- `additional_vm_flavor_indices` define VMs with custom VM flavor

Extra stuff:
- by default, VMs are deployed with `UbuntuServer 18.04-LTS` and VM flavor `Standard_B1s`
- if you declare a VM multiple times in `additional_vm_image_indices`, it will take only the last one, for example, VM-1 is present twice, in `OpenLogic` and in `RedHat`, but it will be deployed with `RedHat` image
- if you declare a VM multiple times in `additional_vm_flavor_indices`, it will take only the last one, for example, VM-2 is present twice, in `Standard_B2s` and in `Standard_D2s_v3`, but it will be deployed with `Standard_D2s_v3` flavor
- if you declare a VM that is out of the indices in `additional_vm_image_indices` or `additional_vm_flavor_indices`, it will be ignored



# Output Aggregation
The data `"external" "file_content"` block reads the `combined_output.txt` file and aggregates the results into a single Terraform output variable named `combined_output`.

