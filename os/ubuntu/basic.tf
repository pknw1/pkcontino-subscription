variable "expiry" { default = 1 }


locals {
  current_time           = timestamp()
  today                  = formatdate("YYYY-MM-DD", local.current_time)
  hours                  = var.expiry * 24
  max_start_date         = formatdate("YYYY-MM-DD", timeadd(timestamp(), "${local.hours}h"))
}

resource "azurerm_resource_group" "rg" {
  name     = "ubuntu2204"
  location = "uksouth"
  tags     = { 
    expires =  local.max_start_date
    }    
}