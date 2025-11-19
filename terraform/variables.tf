variable "prefix" {
  type    = string
  default = "test"
}

variable "location" {
  type    = string
  default = "centralindia"
}

variable "resource_group_name" {
  type    = string
  default = ""
}

variable "aks_node_count" {
  type    = number
  default = 2
}

variable "aks_node_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "acr_sku" {
  type    = string
  default = "Standard"
}
