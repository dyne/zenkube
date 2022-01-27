variable "cluster_name" {
  
}

variable "cluster_version" {
    default = "1.20"
}

variable "region" {
    default = "eu-west-1" 
}

variable "node_groups" {
    default = {
        default = {
            desired_capacity = 1
            max_capacity     = 10
            min_capacity     = 1

            instance_types = ["t3.large"]
            capacity_type  = "DEMAND"
            update_config = {
                max_unavailable_percentage = 50 # or set `max_unavailable`
            }
        }
    }
}

variable "ami_type" {
    default = "AL2_x86_64"
}

variable "disk_size" {
    default = 50
}

variable "cluster_tags" {
    default = {}
}

#### Networking
data "aws_availability_zones" "available" {
}

variable "vpc_cidr" {
    type = string
    description = "(optional) describe your variable"
    default = "10.0.0.0/16"
}

variable "private_subnets" {
    default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
    default = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "vpc_tags" {
    default = {}
}

variable "enable_nat_gateway" {
    default = true
}

variable "single_nat_gateway" {
    default = true
  
}

variable "enable_dns_hostnames" {
    default = true
  
}

variable "map_users" {
    default = []
}