variable "company_name" {
  type        = string
  description = "Company name to be used in resource creation"
  default     = "tftest2" #all lower case
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