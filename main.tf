provider "aws" {
  region = var.region
  
  default_tags {
    tags = var.tags
  }
}

# provider "kubernetes" {
#     host                   = data.aws_eks_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#     token                  = data.aws_eks_cluster_auth.cluster.token
# }

# provider "helm" {
#   kubernetes {
#     host                   = data.aws_eks_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#     token                  = data.aws_eks_cluster_auth.cluster.token
#   }
# }



module "vpc" {
  source                         = "./vpc"
  vpc_name                       = var.vpc_name
  vpc_cidr                       = var.vpc_cidr
  availability_zones             = var.availability_zones
  public_subnets                 = var.public_subnets
  private_subnets                = var.private_subnets
  tags                           = var.tags
}

module "eks" {
  source                         = "./eks"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cpu_desired_capacity           = var.cpu_desired_capacity
  cpu_max_capacity               = var.cpu_max_capacity
  cpu_min_capacity               = var.cpu_min_capacity
  enable_cluster_private_access  = var.enable_cluster_private_access
  enable_cluster_public_access   = var.enable_cluster_public_access
  cluster_public_access_cidrs    = var.cluster_public_access_cidrs
  cluster_admin_users            = var.cluster_admin_users
  gpu_desired_capacity           = var.gpu_desired_capacity
  gpu_max_capacity               = var.gpu_max_capacity
  gpu_min_capacity               = var.gpu_min_capacity
  tags                           = var.tags
  vpc_id                         = module.vpc.vpc_id
  private_subnets                = module.vpc.private_subnets

  depends_on = [module.vpc]

}

data "aws_eks_cluster" "eks" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name       = var.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

# Configure Kubernetes & Helm providers at the root using EKS outputs
# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
#   }
# }

# provider "helm" {
#   kubernetes = {
#     host                   = module.eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
#     }
#   }
# }

module "argocd" {
  source                         = "./argocd"
  region                         = var.region
  cluster_name                   = var.cluster_name
  argocd_namespace               = var.argocd_namespace
  git_ssh_private_key_file       = var.git_ssh_private_key_file

    # Pass the providers down
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
}