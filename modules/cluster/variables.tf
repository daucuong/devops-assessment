variable "cluster_name" {
  description = "Name of the Kind cluster"
  type        = string
  default     = "devops-assessment"
}

variable "node_image" {
  description = "Kind node image"
  type        = string
  default     = "kindest/node:v1.27.3"
}
