# variable "region" {
#   type = string
# }

variable "azs" {
  description = "A list of availability zones names or ids in the region"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  type        = string
  description = "Name of cluster"
}
