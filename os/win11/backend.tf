
terraform {
          backend "azurerm" {
            subscription_id      = "625b66d7-5b11-40fb-99ab-ba303c13ea88"
            resource_group_name  = "tf_state"
            storage_account_name = "continobakerytfstate"
            container_name       = "pkcontino-win11"
            key                  = "dev.tfstate"
          }
        }

provider "azurerm" {
 features {
  virtual_machine {
    skip_shutdown_and_force_delete = true
  }
 }
 skip_provider_registration = false
 storage_use_azuread = true
}
