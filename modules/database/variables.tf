variable "namespace" {
  description = "Namespace for the application"
  type        = string
  default     = "acme"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "acme_db"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = "password"
}
