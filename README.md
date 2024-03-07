# terraform-aws-vpc [![CI](https://github.com/d3b-center/terraform-aws-vpc/workflows/CI/badge.svg?branch=master)](https://github.com/d3b-center/terraform-aws-vpc/actions?query=workflow%3ACI)

A Terraform module to create a dual-stack (IPv4/IPv6) Amazon Web Services (AWS) Virtual Private Cloud (VPC).

- [Usage](#usage)
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

Example usage:

```hcl
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


## Variables

- `name` - A name for the VPC (default: `Default`).
- `region` - A valid AWS region to house VPC resources.
- `cidr_block` - The CIDR range for the entire VPC (default: `10.0.0.0/16`).
- `public_subnet_cidr_blocks` - A list of CIDR ranges for public subnets (default: `["10.0.0.0/24", "10.0.2.0/24"]`).
- `public_subnet_ipv6_prefix_indices` - A list of indices corresponding to IPv6 prefixes for public subnets (default: `[0, 2]`).
- `private_subnet_cidr_blocks` - A list of CIDR ranges for private subnets (default: `["10.0.1.0/24", "10.0.3.0/24"]`).
- `private_subnet_ipv6_prefix_indices` - A list of indices corresponding to IPv6 prefixes for public subnets (default: `[1, 3]`).
- `availability_zones` - A list of availability zones for subnet placement (default: `["us-east-1a", "us-east-1b"]`).
- `tags` - A mapping of keys and values to apply as tags to all resources that support them (default: `{}`).

## Outputs

- `id` - ID of the VPC.
- `public_subnet_ids` - A list of VPC public subnet IDs.
- `private_subnets_ids` - A list of VPC private subnet IDs.
- `cidr_block` - The CIDR range for the entire VPC.
- `ipv6_cidr_block` - The IPv6 CIDR range for the entire VPC.
- `nat_gateway_ips` - Public IP addresses of the VPC NAT gateways.
