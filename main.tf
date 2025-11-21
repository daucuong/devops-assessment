terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "kind" {}

provider "kubernetes" {
  config_path = "~/.kube/config"
  insecure    = true
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
    insecure    = true
  }
}

module "cluster" {
  source = "./modules/cluster"
}

# module "loadbalancer" {
#   source     = "./modules/loadbalancer"
#   depends_on = [module.cluster]
# }

module "ingress" {
  source     = "./modules/ingress"
  depends_on = [module.cluster]
}

module "database" {
  source     = "./modules/database"
  depends_on = [module.cluster]
}

module "monitoring" {
  source        = "./modules/monitoring"
  app_namespace = module.database.app_namespace
  depends_on    = [module.cluster]
}

module "security" {
  source     = "./modules/security"
  depends_on = [module.cluster]
}

module "application" {
  source        = "./modules/application"
  app_namespace = module.database.app_namespace
  depends_on    = [module.cluster]
}

module "backup" {
  source     = "./modules/backup"
  depends_on = [module.cluster]
}

module "cicd" {
  source     = "./modules/cicd"
  depends_on = [module.cluster]
}

module "apm" {
  source     = "./modules/apm"
  depends_on = [module.cluster]
}

