variable "region" {
  type        = string
  description = "Linode region to deploy"
  default     = "gb-lon"
}

variable "lke_cluster_label" {
  type        = string
  description = "Label for LKE cluster"
  default     = "kubecon-demo-cluster"
}

variable "lke_image_type" {
  type        = string
  description = "The image type to deploy all nodes with."
  default     = "g6-standard-8"
}

variable "k8s_version" {
  type        = string
  description = "The version of LKE to deploy.  Default not provided because changes frequently."
}

