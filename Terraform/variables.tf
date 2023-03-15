variable "company_name" {
  type        = string
  description = "Company name to be used in resource creation"
  default     = "wolftest" #all lower case
}
variable "location" {
  type        = string
  description = "Company name to be used in resource creation"
  default     = "Canada Central" #all lower case
}
variable "subscription_id" {
  type        = string
  description = "Company name to be used in resource creation"
  default     = "f6fcb95e-6b4e-41e8-96f9-44fb1dfd8c22" 
}
variable "tenant_id" {
  type        = string
  description = "Company name to be used in resource creation"
  default     = "e7b21e91-c04e-4b80-9ce7-2456ee9519cd" 
}
variable "client_id" {
  type        = string
  description = "Company name to be used in resource creation"
  default     = "a3c9abce-1170-485c-8d3f-4def849160ab" 
}
variable "client_secret" {
  type        = string
  description = "Company name to be used in resource creation"
  default     = "GQH8Q~gvpVNFkyzXw_79Ajb-vqbrjSOQozZ6tahc" 
}
variable "resource_group_name" {
  type        = string
  description = "Company name to be used in resource creation"
  default     = "AJDatabricksSetupResourceGroup" 
}
variable "storage_account_name" {
  type        = string
  description = "Company name to be used in resource creation"
  default     = "ajdatabrickssetupsa" 
}
variable "container_name" {
  type        = string
  description = "Company name to be used in resource creation"
  default     = "tfstate" 
}  
variable "key_vault_names" {
  type        = list(string)
  description = "Company name to be used in resource creation"
  default     = ["kvdbproddakota","kvdbtestdakota"] 
}  
variable "databricks_resource_names" {
  type        = list(string)
  description = "Company name to be used in resource creation"
  default     = ["dbricksprod","dbricksdev"] 
}  
variable "databricks_sku" {
  type        = string
  description = "Company name to be used in resource creation"
  default     = "standard" #be changed depending on the site
}  
variable "storage_account_names" {
  type        = list(string)
  description = "Company name to be used in resource creation"
  default     = ["landingsadakota","unitysadakota"] 
}  
variable "private_subnets" {
  type        = map(any)
  description = "Subnet array with address prefixes"
  default     = {

        private_subnet_prod = {
    name = "private_subnet_prod"
    address_prefixes = ["42.0.0.0/24"]
  }
          private_subnet_dev = {
    name = "private_subnet_dev"
    address_prefixes = ["42.0.1.0/24"]
  }
}  

}
variable "public_subnets" {
  type        = map(any)
  description = "Subnet array with address prefixes"
  default     = {
    public_subnet_prod = {
    name = "public_subnet_prod"
    address_prefixes = ["42.0.2.0/24"]
  }
      public_subnet_dev = {
    name = "public_subnet_dev"
    address_prefixes = ["42.0.3.0/24"]
  }
}  

}

#variable "databricksresources" {
#  type        = map(any)
#  description = "Subnet array with address prefixes"
#  default     = {
#    databricks_prod = {
#    name = "databricksprod"
#    address_prefixes = ["42.2.0.0/20"]
#  }
#      databricks_dev = {
#    name = "public_subnet_dev"
#    address_prefixes = ["42.4.0.0/20"]
#  }
#}  
#
#}