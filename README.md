# terraform-aws-vpc [![CI](https://github.com/d3b-center/terraform-aws-vpc/workflows/CI/badge.svg?branch=master)](https://github.com/d3b-center/terraform-aws-vpc/actions?query=workflow%3ACI)

A Terraform module to create a dual-stack (IPv4/IPv6) Amazon Web Services (AWS) Virtual Private Cloud (VPC).

- [Usage](#usage)
  - [Connecting to the Bastion with Session Manager](#connecting-to-the-bastion-with-aws-session-manager)
  - [Configuring Security Group Rules](#configuring-security-group-rules)
- [Variables](#variables)
- [Outputs](#outputs)

## Usage

This module creates a VPC alongside a variety of related resources, including:

- Public and private subnets.
- Public and private route tables.
- Elastic IPs.
- Network interfaces.
- NAT gateways.
- An internet gateway and an egress-only internet gateway (for private IPv6 traffic).
- An S3 VPC endpoint.
- VPC endpoints to support AWS Session Manager.
- A bastion EC2 instance.

Example usage:

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

module "vpc" {}
  source = "github.com/d3b-center/terraform-aws-vpc"

  name                               = "Default"
  region                             = "us-east-1"
  cidr_block                         = "10.0.0.0/16"
  private_subnet_cidr_blocks         = ["10.0.1.0/24", "10.0.3.0/24"]
  private_subnet_ipv6_prefix_indices = [1, 3]
  public_subnet_cidr_blocks          = ["10.0.0.0/24", "10.0.2.0/24"]
  public_subnet_ipv6_prefix_indices  = [0, 2]
  availability_zones                 = ["us-east-1a", "us-east-1b"]
  bastion_ami                        = data.aws_ami.amazon_linux.id
  bastion_instance_type              = "t3.nano"

  tags = {}
}
```

See the [examples](./examples/) directory for a complete implementation.

### Connecting to the Bastion with Session Manager

After copying the bastion instance ID from the AWS Console, you can start a session:

```console
$ aws ssm start-session --target i-0471c64f8747dadae

Starting session with SessionId: iamuser-0f4532b020626b7be
sh-4.2$
```

For information about accessing other VPC resources, see [How can I use an SSH tunnel through AWS Systems Manager to access my private VPC resources?](https://aws.amazon.com/premiumsupport/knowledge-center/systems-manager-ssh-vpc-resources/)

### Configuring Security Group Rules

Aside from those needed to support Session Manager, this module adds no security group rules to the bastion instance, meaning that all traffic will be blocked.

In order to configure security rules for the bastion, use the `bastion_security_group_id` output. For example:

```hcl
resource "aws_security_group_rule" "bastion_https_egress" {
  type             = "egress"
  from_port        = 443
  to_port          = 443
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = module.vpc.bastion_security_group_id
}
```

## Variables

- `name` - A name for the VPC (default: `Default`).
- `region` - A valid AWS region to house VPC resources.
- `cidr_block` - The CIDR range for the entire VPC (default: `10.0.0.0/16`).
- `public_subnet_cidr_blocks` - A list of CIDR ranges for public subnets (default: `["10.0.0.0/24", "10.0.2.0/24"]`).
- `public_subnet_ipv6_prefix_indices` - A list of indices corresponding to IPv6 prefixes for public subnets (default: `[0, 2]`).
- `private_subnet_cidr_blocks` - A list of CIDR ranges for private subnets (default: `["10.0.1.0/24", "10.0.3.0/24"]`).
- `private_subnet_ipv6_prefix_indices` - A list of indices corresponding to IPv6 prefixes for public subnets (default: `[1, 3]`).
- `availability_zones` - A list of availability zones for subnet placement (default: `["us-east-1a", "us-east-1b"]`).
- `bastion_ami` - An AMI ID for the bastion.
- `bastion_instance_type` - An instance type for the bastion (default: `t3.nano`).
- `aws_ssm_managed_instance_core_policy_arn` - ARN to the canned AmazonSSMManagedInstanceCore policy. (default: `arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore`).
- `tags` - A mapping of keys and values to apply as tags to all resources that support them (default: `{}`).

## Outputs

- `id` - ID of the VPC.
- `public_subnet_ids` - A list of VPC public subnet IDs.
- `private_subnets_ids` - A list of VPC private subnet IDs.
- `vpc_endpoint_security_group_id` - Security group associated with the interface VPC endpoints for adding rules.
- `bastion_security_group_id` - Security group associated with the bastion for adding rules.
- `bastion_iam_role_name` - IAM role associated with the bastion for attaching IAM policies.
- `cidr_block` - The CIDR range for the entire VPC.
- `ipv6_cidr_block` - The IPv6 CIDR range for the entire VPC.
- `nat_gateway_ips` - Public IP addresses of the VPC NAT gateways.
