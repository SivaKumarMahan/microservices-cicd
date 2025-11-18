data "azurerm_resource_group" "existing_rg" {
  name = "aimsplus"
}
data "azurerm_client_config" "current" {
}

# Log Analytics
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}


# ACR
resource "azurerm_container_registry" "acr" {
  name                = "acrtest8943"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = false
}


# Key Vault
resource "azurerm_key_vault" "kv" {
  name                     = "kvtest8634"
  location                 = var.location
  resource_group_name      = data.azurerm_resource_group.existing_rg.name
  sku_name                 = "standard"
  tenant_id                = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled = false
}

# Storage account for Functions
resource "azurerm_storage_account" "sa" {
  name                     = "microservicesa8634"
  resource_group_name      = data.azurerm_resource_group.existing_rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


# AKS
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  dns_prefix          = "${var.prefix}-aks"


  default_node_pool {
    name       = "agentpool"
    node_count = var.aks_node_count
    vm_size    = var.aks_node_size
  }


  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }


  network_profile {
    network_plugin = "azure"
  }
}


# Allow AKS managed identity to pull from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}


# Function App
resource "azurerm_app_service_plan" "function_plan" {
  name                = "${var.prefix}-func-plan"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}


resource "azurerm_function_app" "function" {
  name                       = "appfunction8634"
  location                   = var.location
  resource_group_name        = data.azurerm_resource_group.existing_rg.name
  app_service_plan_id        = azurerm_app_service_plan.function_plan.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  version                    = "~4"
  identity {
    type = "SystemAssigned"
  }
}


# Optional: grant Function Managed Identity access to Key Vault (if using key vault references)
resource "azurerm_key_vault_access_policy" "func_kv_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_function_app.function.identity[0].principal_id


  secret_permissions = ["Get", "List"]
}