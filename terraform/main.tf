terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
  # backend "s3" {
  #   bucket = "name-mybucket"
  #   key    = "terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      owner      = "thales eduardo"
      managed-by = "${var.tag_name}"
    }
  }
}

module "vpc" {
  source         = "./modules/vpc"
  tag_name       = var.tag_name
  vpc_cidr_block = var.vpc_cidr_block
}

module "eks" {
  source         = "./modules/eks"
  cluster_name   = var.cluster_name
  vpc_cidr_block = var.vpc_cidr_block
  tag_name       = var.tag_name
  retention_days = var.retention_days
  desired_size   = var.desired_size
  max_size       = var.max_size
  min_size       = var.min_size
  # outputs
  subnet_public_ids = module.vpc.subnet_public_ids
  vpc_id            = module.vpc.vpc_id
}
