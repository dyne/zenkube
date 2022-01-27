output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

#output "config_map_aws_auth" {
#  description = "A kubernetes configuration to authenticate to this EKS cluster."
#  value       = module.eks.config_map_aws_auth
#}

output "kubeconfig" {
    value = "aws eks --region ${var.region} update-kubeconfig --name ${var.cluster_name}"
}
