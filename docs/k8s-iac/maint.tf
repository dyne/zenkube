 provider "aws" {
  region = var.region
 }

module "eks" {
  source = "github.com/dab-solutions/tf_hardened_eks.git?ref=awsv17"

  cluster_name = var.cluster_name

  map_users = var.map_users
}