terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
    linode = {
      source  = "linode/linode"
      version = "~> 2.23"
    }
    time = {
      source = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  required_version = ">= 1.7"
}