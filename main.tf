terraform {
  required_version = ">= 1.3.7"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.43.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "subscription_id" {
  type    = string
}

variable "azure-alerts-dynatrace-rg-name" {
  type    = string
}

variable "azure-alerts-dynatrace-sa-name" {
  type    = string
}

variable "azure-alerts-dynatrace-sp-name" {
  type    = string
}

variable "azure-alerts-dynatrace-uai-name" {
  type    = string
}

variable "azure-alerts-dynatrace-fa-name" {
  type    = string
}

variable "azure-alerts-dynatrace-fn-name" {
  type    = string
}

variable "azure-alerts-dynatrace-kv-name" {
  type    = string
}

variable "dynatrace-api-token" {
  type    = string
}

variable "dynatrace-api-url" {
  type    = string
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_secrets_on_destroy = true
      recover_soft_deleted_secrets          = true
    }
  }
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "azure-alerts-dynatrace-rg" {
  name = var.azure-alerts-dynatrace-rg-name
}

resource "azurerm_key_vault" "dynatrace-api-token" {
  name                       = "dynatrace-api"
  location                   = data.azurerm_resource_group.azure-alerts-dynatrace-rg.location
  resource_group_name        = data.azurerm_resource_group.azure-alerts-dynatrace-rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  enable_rbac_authorization  = true
  enabled_for_deployment     = false
  purge_protection_enabled   = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Set",
      "List",
      "Get",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}

resource "azurerm_key_vault_secret" "dynatrace-api-token" {
  depends_on = [azurerm_role_assignment.terraform_administrator_keyvault]

  name         = "dynatrace-api-token"
  value        = var.dynatrace-api-token
  key_vault_id = azurerm_key_vault.dynatrace-api-token.id
}

resource "azurerm_key_vault_secret" "dynatrace-api-url" {
  depends_on = [azurerm_role_assignment.terraform_administrator_keyvault]

  name         = "dynatrace-api-url"
  value        = var.dynatrace-api-url
  key_vault_id = azurerm_key_vault.dynatrace-api-token.id
}

resource "azurerm_storage_account" "azure-alerts-dynatrace-sa" {
  name                     = var.azure-alerts-dynatrace-sa-name
  resource_group_name      = data.azurerm_resource_group.azure-alerts-dynatrace-rg.name
  location                 = data.azurerm_resource_group.azure-alerts-dynatrace-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "azure-alerts-dynatrace-container" {
  name                  = "alerts-dynatrace"
  storage_account_id    = azurerm_storage_account.azure-alerts-dynatrace-sa.id
  container_access_type = "private"
}

resource "azurerm_application_insights" "azure-alerts-dynatrace-app-insights" {
  name                = "alerts-dynatrace-appinsights"
  location            = data.azurerm_resource_group.azure-alerts-dynatrace-rg.location
  resource_group_name = data.azurerm_resource_group.azure-alerts-dynatrace-rg.name
  application_type    = "other"
}

resource "azurerm_log_analytics_workspace" "azure-alerts-dynatrace-app-workspace" {
  name                = "azure-alerts-dynatrace-app-workspace"
  location            = data.azurerm_resource_group.azure-alerts-dynatrace-rg.location
  resource_group_name = data.azurerm_resource_group.azure-alerts-dynatrace-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_service_plan" "azure-alerts-dynatrace-sp" {
  name                = var.azure-alerts-dynatrace-sp-name
  resource_group_name = data.azurerm_resource_group.azure-alerts-dynatrace-rg.name
  location            = data.azurerm_resource_group.azure-alerts-dynatrace-rg.location
  os_type             = "Linux"
  sku_name            = "FC1"
}

resource "azurerm_user_assigned_identity" "azure-alerts-dynatrace-uai" {
  resource_group_name = data.azurerm_resource_group.azure-alerts-dynatrace-rg.name
  location            = data.azurerm_resource_group.azure-alerts-dynatrace-rg.location
  name                = var.azure-alerts-dynatrace-uai-name
}

resource "azurerm_function_app_flex_consumption" "azure-alerts-dynatrace-fa" {
  name                = var.azure-alerts-dynatrace-fa-name
  resource_group_name = data.azurerm_resource_group.azure-alerts-dynatrace-rg.name
  location            = data.azurerm_resource_group.azure-alerts-dynatrace-rg.location
  service_plan_id     = azurerm_service_plan.azure-alerts-dynatrace-sp.id

  storage_container_type        = "blobContainer"
  storage_container_endpoint    = "${azurerm_storage_account.azure-alerts-dynatrace-sa.primary_blob_endpoint}${azurerm_storage_container.azure-alerts-dynatrace-container.name}"
  storage_authentication_type   = "StorageAccountConnectionString"
  storage_access_key            = azurerm_storage_account.azure-alerts-dynatrace-sa.primary_access_key
  runtime_name                  = "python"
  runtime_version               = "3.13"
  maximum_instance_count        = 50
  instance_memory_in_mb         = 2048
  public_network_access_enabled = true

  site_config {
    application_insights_connection_string = azurerm_application_insights.azure-alerts-dynatrace-app-insights.connection_string

    cors {
        allowed_origins = ["*"]
    }
  }

  app_settings = {
      USER_MANAGED_IDENTITY_ID = azurerm_user_assigned_identity.azure-alerts-dynatrace-uai.client_id
  }

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.azure-alerts-dynatrace-uai.id]
  }
}

resource "azurerm_role_assignment" "terraform_administrator_keyvault" {
    scope                = azurerm_key_vault.dynatrace-api-token.id
    principal_id         = data.azurerm_client_config.current.object_id
    role_definition_name = "Key Vault Administrator"
}

resource "azurerm_role_assignment" "function_read_keyvault" {
    depends_on          = [azurerm_role_assignment.terraform_administrator_keyvault]

    scope               = azurerm_key_vault.dynatrace-api-token.id
    role_definition_name = "Key Vault Secrets User"
    principal_id       = azurerm_user_assigned_identity.azure-alerts-dynatrace-uai.principal_id
}

resource "azurerm_role_assignment" "function_write_storageaccount" {
    depends_on          = [azurerm_role_assignment.terraform_administrator_keyvault]

    scope               = azurerm_storage_account.azure-alerts-dynatrace-sa.id
    role_definition_name = "Storage Blob Data Owner"
    principal_id       = azurerm_user_assigned_identity.azure-alerts-dynatrace-uai.principal_id
}
