locals {
  name                   = var.name
  env                    = var.env
  cluster_name           = "${var.name}-${var.env}"
  cluster_version        = var.eks_cluster_version
  cluster_instance_types = var.eks_cluster_instance_types
  cluster_min_size       = var.eks_cluster_size.min_size
  cluster_max_size       = var.eks_cluster_size.max_size
  cluster_desired_size   = var.eks_cluster_size.desired_size
  azs                    = slice(data.aws_availability_zones.available.names, 0, 3)
  tags = {
    Terraform = "true"
  }
}

data "aws_availability_zones" "available" {}

data "aws_vpc" "this" {
  id = "opsfleet-vpc"
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    Tier = "Private"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version

  cluster_endpoint_public_access           = true
  cluster_endpoint_private_access          = true
  enable_cluster_creator_admin_permissions = true
  cluster_enabled_log_types                = []

  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.irsa_ebs_csi.iam_role_arn
    }
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        tolerations = [
          # Allow CoreDNS to run on the same nodes as the Karpenter controller
          # for use during cluster creation when Karpenter nodes do not yet exist
          {
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }
        ]
      })
    }
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  vpc_id     = data.aws_vpc.this.id
  subnet_ids = data.aws_subnets.private.ids

  enable_irsa = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    default = {
      iam_role_additional_policies = var.cloudwatch_agent_policy ? {
        CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
        AWSXrayWriteOnlyAccess      = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
      } : {}
      instance_types = local.cluster_instance_types
      min_size       = local.cluster_min_size
      max_size       = local.cluster_max_size
      desired_size   = local.cluster_desired_size
      capacity_type  = "ON_DEMAND"
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = try(var.eks_cluster_size.hdd_size, 100)
            volume_type = "gp3"
          }
        }
      }

      labels = try(var.addons.enable_karpenter, false) ? {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      } : {}
    }
  }

  node_security_group_tags = try(var.addons.enable_karpenter, false) ? merge(local.tags, {
    "karpenter.sh/discovery" = local.cluster_name
  }) : {}

  tags = local.tags
}

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa_ebs_csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.41.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16.3"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_karpenter = try(var.addons.enable_karpenter, false)

  tags = local.tags
}

resource "kubectl_manifest" "karpenter_node_class" {
  count = try(var.addons.enable_karpenter, false) ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023
      role: ${module.eks_blueprints_addons.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${module.eks.cluster_name}
      tags:
        karpenter.sh/discovery: ${module.eks.cluster_name}
  YAML

  depends_on = [
    module.eks_blueprints_addons
  ]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  count = try(var.addons.enable_karpenter, false) ? 1 : 0

  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["on-demand"]
            - key: "node.kubernetes.io/instance-type"
              operator: In
              values: ["m7i.xlarge", "m7i.2xlarge", "m8g.xlarge", "m8g.2xlarge"]
      limits:
        cpu: 200
        memory: 640Gi
      disruption:
        consolidationPolicy: WhenEmpty
        expireAfter: 30s
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}
