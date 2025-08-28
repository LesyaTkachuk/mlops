module "ebs_csi_driver_irsa" {
    source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
    version = "~> 5.0"
    
    role_name = "ebs-csi"

    attach_ebs_csi_policy = true

    oidc_providers = {
        this = {
            provider_arn               = module.eks.oidc_provider_arn
            namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
        }
    }

    tags ={
        Terraform = "true"
        Environment = "dev"
    }
}

module "eks" {
  source             = "terraform-aws-modules/eks/aws"
  version            = "~> 20.0"
  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  subnet_ids         = var.private_subnets
  vpc_id             = var.vpc_id

  eks_managed_node_groups = {
    cpu_nodes = {
      desired_capacity = var.cpu_desired_capacity
      max_capacity     = var.cpu_max_capacity
      min_capacity     = var.cpu_min_capacity

      instance_types = ["t3.medium"]
    }

    gpu_nodes = {
      desired_capacity = var.gpu_desired_capacity
      max_capacity     = var.gpu_max_capacity
      min_capacity     = var.gpu_min_capacity

      instance_types = ["t3.small"]
    }
  }

  cluster_endpoint_private_access = var.enable_cluster_private_access
  cluster_endpoint_public_access  = var.enable_cluster_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_public_access_cidrs

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
    most_recent               = true
    resolve_conflicts         = "OVERWRITE"
    preserve                  = false
    service_account_role_arn  = module.ebs_csi_driver_irsa.iam_role_arn
  }
    # aws-ebs-csi-driver = {
    #   most_recent = true
    #   resolve_conflicts = "OVERWRITE"
    #   preserve_on_delete = false
    #   pod_identity_associations=[{
    #     service_account = "ebs-csi-controller-sa"
    #     namespace = "kube-system"
    #     role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    #   }]
    # }
  }

  tags = var.tags
}

resource "aws_eks_access_entry" "cluster_admin" {
  count         = length(var.cluster_admin_users)
  cluster_name  = module.eks.cluster_name
  principal_arn = var.cluster_admin_users[count.index]
  type         = "STANDARD"

  depends_on = [module.eks]
}

# Associate cluster admin policy
resource "aws_eks_access_policy_association" "cluster_admin" {
  count         = length(var.cluster_admin_users)
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.cluster_admin_users[count.index]

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.cluster_admin]
}

