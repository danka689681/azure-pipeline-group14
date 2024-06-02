terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0.2"
    }
  }
}

provider "azurerm" {
  features {
  resource_group {
       prevent_deletion_if_contains_resources = false
  }
}
}

resource "azurerm_resource_group" "PDP_RG" {
  location = "westeurope"
  name     = "pdp_resource-group-finalc"
  tags = {
    evironment = "dev"
    source     = "Terraform"
  }
}

# # Storage Account
resource "azurerm_storage_account" "PDP_Storage" {
  name                     = "pdpstoragegroup14c"
  resource_group_name      = azurerm_resource_group.PDP_RG.name
  location                 = azurerm_resource_group.PDP_RG.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Application Insights
resource "azurerm_application_insights" "PDP_AppInsights" {
  name                = "pdp_app-insightsc"
  resource_group_name = azurerm_resource_group.PDP_RG.name
  location            = azurerm_resource_group.PDP_RG.location
  application_type    = "web"
}

# Key Vault
resource "azurerm_key_vault" "PDP_KeyVault" {
  name                     = "pdp-keyvault-group14c"
  resource_group_name      = azurerm_resource_group.PDP_RG.name
  location                 = azurerm_resource_group.PDP_RG.location
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false
}

data "azurerm_client_config" "current" {}


## Azure ML Workspace
resource "azurerm_machine_learning_workspace" "PDP_Workspace" {
  name                = "pdp_workspace_group14c1"
  resource_group_name = azurerm_resource_group.PDP_RG.name
  location            = azurerm_resource_group.PDP_RG.location
  sku_name            = "Basic"

  application_insights_id = azurerm_application_insights.PDP_AppInsights.id
  key_vault_id            = azurerm_key_vault.PDP_KeyVault.id
  storage_account_id      = azurerm_storage_account.PDP_Storage.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_container" "PDP_Storage_Container" {
  name                  = "pdpstoragecontainerc"
  storage_account_name  = azurerm_storage_account.PDP_Storage.name
  container_access_type = "private"  # Other options: "blob", "container", "none"
}

resource "azurerm_machine_learning_compute_instance" "PDP_Compute_Instance" {
  name                = "pdp-compute-group14c1"
  location            = azurerm_resource_group.PDP_RG.location # Specify the desired Azure region

  tags = {
    environment = "production"
  }
  machine_learning_workspace_id = azurerm_machine_learning_workspace.PDP_Workspace.id
  virtual_machine_size          = "STANDARD_DS2_V2"  # Set the virtual machine size directly
}
### Run Azure ML Pipeline
#resource "null_resource" "run_azure_ml_pipeline" {
#  provisioner "local-exec" {
#    command     = <<EOT
#      # Fetch the pipeline ID
#    command = <<EOT
#      python3 ./hello-comonent/pipeline-exec.py ${data.azurerm_subscription.current.id}
#
#    EOT
#    interpreter = ["bash", "-c"]
#  }
#}
#


