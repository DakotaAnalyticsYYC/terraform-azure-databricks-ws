variable "company_name1" {
  type        = string
  description = "Company name to be used in resource creation"
  default     = "tftest2" #all lower case
}

variable "deployment_location1" {
  type        = string
  description = "Which datacenter to deploy to"
  default     = "Canada Central" #typically one of ['Canada Central', 'West US', 'West US 2', 'West US 3']
}

variable "sqladmin_password1" {
  type        = string
  description = "Save in password or key vault... change this"
  default     = "B0*^*AF*M!3gOeMFCvZ#695RxO1xbGub" #use a secure string generator
}

