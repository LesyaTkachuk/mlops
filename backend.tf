# terraform {
#   backend "s3" {
#     bucket = "mlops-tfstate-oleksandra"
#     key    = "global/s3/terraform.tfstate"
#     region = "us-east-1"
#   }
# }

# Backend configuration for storing Terraform state
# Local backend for development
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
