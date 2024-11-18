variable "name" {
  description = "The name of the project"
  type        = string
  default     = "opsfleet-demo"
}

variable "env" {
  description = <<EOF
  Allowed values: prod, preprod, dev, test
  EOF
  type        = string
  default     = "test"
}

variable "aws_region" {
  description = "aws region to deploy resources"
  type        = string
  default     = "eu-central-1"
}

variable "eks_cluster_version" {
  description = "EKS version. Change to upgrade cluster version and replace nodes after cluster upgraded"
  type        = string
  default     = "1.30"
}

variable "eks_cluster_instance_types" {
  description = "EC2 instance types to use by Karpenter or Cluster Autoscaler"
  type        = list(any)
  default     = ["m7i.xlarge"]
}

variable "eks_cluster_size" {
  description = <<EOF
  Configuration of EKS Cluster Node group. Desired size - initial size.
  Cluster Autoscaler can scale in and scale out node inside Node Group limits.
  Karpenter doesn't use Node Group limits.
  EOF
  type        = map(any)
  default = {
    min_size     = 3
    max_size     = 5
    desired_size = 3
    hdd_size     = 100
  }
}

variable "cloudwatch_agent_policy" {
  description = "Attach `CloudWatchAgentServerPolicy` IAM Policy to Node Group nodes. Alternative to IRSA"
  type        = bool
  default     = false
}

variable "addons" {
  description = <<EOF
  Kubernetes addons to install in cluster
  EOF
  type        = map(bool)
  default = {
    enable_karpenter = true
  }
}
