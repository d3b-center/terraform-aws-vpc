# Example Project

This directory contains an example project demonstrating usage of our VPC module, including:

* Provider-level tagging using [`default_tags`](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/guides/resource-tagging#propagating-tags-to-all-resources).
* A security group rule that allows the bastion instance to make HTTPS requests.
* Changing the default working directory and shell for AWS Systems Manager to `~` and `/bin/bash`.

- [Overview](#overview)
- [Getting Started](#getting-started)
  - [Dependencies](#dependencies)
  - [Instructions](#instructions)

## Overview

The `terraform` directory contains a Terraform project.

The `scripts` directory contains one script:
- `infra` is a wrapper for the `terraform` command that also manages initialization.

## Getting Started

### Dependencies

- AWS CLI 2.4+
- Docker 20.10+
- Docker Compose 2.2+

### Instructions

First, copy the following file, renaming it to `terraform-aws-vpc.tfvars` in the process:

```console
cp terraform/terraform-aws-vpc.tfvars.example terraform/terraform-aws-vpc.tfvars
```

Then, customize its contents with a text editor:

- For project, use your name in title case.

Here's an example of a customized `terraform-aws-vpc.tfvars`:

```hcl
project = "JohnAmazon"
environment = "Staging"
region = "us-east-1"
```

Next, launch an instance of the included Terraform container image:

```console
export AWS_PROFILE=d3b-sandbox
docker-compose run --rm terraform
bash-5.1#
```

Once inside the context of the container image, use `infra` to generate a Terraform plan:

```console
bash-5.1# ./scripts/infra plan
```
