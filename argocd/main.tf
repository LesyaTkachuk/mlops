resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace

    labels = {
      name = var.argocd_namespace
    }
  }
}

resource "helm_release" "argocd" {
  depends_on = [ kubernetes_namespace.argocd ]
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "v7.7.5"

  wait = true
  wait_for_jobs = true
  timeout = 600

  recreate_pods = true
  replace       = true

  values = [file("${path.module}/values/argocd-values.yaml")]
}

# SSH Private Key for Git repository access
resource "kubernetes_secret" "argocd_repo_ssh_key" {
  count = var.git_ssh_private_key_file != "" ? 1 : 0
  depends_on = [ helm_release.argocd ]
  type = "Opaque"

  metadata {
    name = "argocd-repo-ssh-key"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
        "argocd.argoproj.io/secret-type" = "repo-creds"
    }
  }
  
  data = {
    type = "git"
    url = "git@github.com"
    sshPrivateKey = file(var.git_ssh_private_key_file)
    insecure = "false"
    enableLfs = "true"
  }
}