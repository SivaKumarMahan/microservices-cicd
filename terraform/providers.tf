terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  subscription_id                 = "ed79d02d-bd46-4fa8-96bb-4fcddc112959"
  tenant_id                       = "59abe6c5-fee5-4332-b2dd-5935ec367903"
  resource_provider_registrations = "none"
}