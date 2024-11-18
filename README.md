<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**

- [Opsfleet demo EKS](#opsfleet-demo-eks)
  - [Provision](#provision)
  - [Configure kubectl](#configure-kubectl)
  - [Deploy applications](#deploy-applications)
  - [Requirements](#requirements)
  - [Providers](#providers)
  - [Modules](#modules)
  - [Resources](#resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Opsfleet demo EKS

## Provision
```bash
terraform init
terraform plan
terraform apply
```
## Configure kubectl
Run the command from the output:
```bash
terraform output configure_kubectl
```
## Deploy applications
```bash
kubectl apply -f ./workload-graviton.yaml
kubectl apply -f ./workload-flexible.yaml
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 5.60 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.60.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | 2.1.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | 20.8.5 |
| <a name="module_eks_blueprints_addons"></a> [eks\_blueprints\_addons](#module\_eks\_blueprints\_addons) | aws-ia/eks-blueprints-addons/aws | ~> 1.16.3 |
| <a name="module_irsa_ebs_csi"></a> [irsa\_ebs\_csi](#module\_irsa\_ebs\_csi) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | 5.41.0 |

## Resources

| Name | Type |
|------|------|
| [kubectl_manifest.karpenter_node_class](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_node_pool](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/5.60/docs/data-sources/availability_zones) | data source |
| [aws_iam_policy.ebs_csi_policy](https://registry.terraform.io/providers/hashicorp/aws/5.60/docs/data-sources/iam_policy) | data source |
| [aws_subnets.private](https://registry.terraform.io/providers/hashicorp/aws/5.60/docs/data-sources/subnets) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/5.60/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| <a name="input_addons"></a> [addons](#input\_addons) | Kubernetes addons to install in cluster | `map(bool)` | <pre>{<br>  "enable_karpenter": true<br>}</pre> |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | aws region to deploy resources | `string` | `"eu-central-1"` |
| <a name="input_cloudwatch_agent_policy"></a> [cloudwatch\_agent\_policy](#input\_cloudwatch\_agent\_policy) | Attach `CloudWatchAgentServerPolicy` IAM Policy to Node Group nodes. Alternative to IRSA | `bool` | `false` |
| <a name="input_eks_cluster_instance_types"></a> [eks\_cluster\_instance\_types](#input\_eks\_cluster\_instance\_types) | EC2 instance types to use by Karpenter or Cluster Autoscaler | `list(any)` | <pre>[<br>  "m7i.xlarge"<br>]</pre> |
| <a name="input_eks_cluster_size"></a> [eks\_cluster\_size](#input\_eks\_cluster\_size) | Configuration of EKS Cluster Node group. Desired size - initial size.<br>  Cluster Autoscaler can scale in and scale out node inside Node Group limits.<br>  Karpenter doesn't use Node Group limits. | `map(any)` | <pre>{<br>  "desired_size": 3,<br>  "hdd_size": 100,<br>  "max_size": 5,<br>  "min_size": 3<br>}</pre> |
| <a name="input_eks_cluster_version"></a> [eks\_cluster\_version](#input\_eks\_cluster\_version) | EKS version. Change to upgrade cluster version and replace nodes after cluster upgraded | `string` | `"1.30"` |
| <a name="input_env"></a> [env](#input\_env) | Allowed values: prod, preprod, dev, test | `string` | `"test"` |
| <a name="input_name"></a> [name](#input\_name) | The name of the project | `string` | `"opsfleet-demo"` |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_configure_kubectl"></a> [configure\_kubectl](#output\_configure\_kubectl) | Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig |
<!-- END_TF_DOCS -->
