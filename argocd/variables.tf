variable "region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
}

variable "git_ssh_private_key_file" {
  description = "Path to the SSH private key file"
  type        = string
  
}