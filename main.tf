#
# VPC resources
#
resource "aws_vpc" "default" {
  cidr_block                       = var.cidr_block
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    {
      Name = "gwInternet"
    },
    var.tags
  )
}

resource "aws_egress_only_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    {
      Name = "gwInternetEgressOnly"
    },
    var.tags
  )
}

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id = aws_vpc.default.id

  tags = merge(
    {
      Name = "PrivateRouteTable"
    },
    var.tags
  )
}

resource "aws_route" "private" {
  count = length(var.private_subnet_cidr_blocks)

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default[count.index].id
}


resource "aws_route" "ipv6_private" {
  count = length(var.private_subnet_cidr_blocks)

  route_table_id              = aws_route_table.private[count.index].id
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.default.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    {
      Name = "PublicRouteTable"
    },
    var.tags
  )
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_route" "ipv6_public" {
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.default.id
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id                                         = aws_vpc.default.id
  assign_ipv6_address_on_creation                = true
  cidr_block                                     = var.private_subnet_cidr_blocks[count.index]
  enable_dns64                                   = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  enable_resource_name_dns_a_record_on_launch    = true
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.default.ipv6_cidr_block, 8, var.private_subnet_ipv6_prefix_indices[count.index])
  availability_zone                              = var.availability_zones[count.index]
  private_dns_hostname_type_on_launch            = "resource-name"

  tags = merge(
    {
      Name = "PrivateSubnet"
    },
    var.tags
  )
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr_blocks)

  vpc_id                                         = aws_vpc.default.id
  assign_ipv6_address_on_creation                = true
  cidr_block                                     = var.public_subnet_cidr_blocks[count.index]
  enable_dns64                                   = true
  enable_resource_name_dns_aaaa_record_on_launch = true
  enable_resource_name_dns_a_record_on_launch    = true
  ipv6_cidr_block                                = cidrsubnet(aws_vpc.default.ipv6_cidr_block, 8, var.public_subnet_ipv6_prefix_indices[count.index])
  availability_zone                              = var.availability_zones[count.index]
  map_public_ip_on_launch                        = true
  private_dns_hostname_type_on_launch            = "resource-name"

  tags = merge(
    {
      Name = "PublicSubnet"
    },
    var.tags
  )
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidr_blocks)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidr_blocks)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.default.id
  service_name = "com.amazonaws.${var.region}.s3"

  route_table_ids = flatten([
    aws_route_table.public.id,
    aws_route_table.private.*.id
  ])

  tags = merge(
    {
      Name = "endpointS3"
    },
    var.tags
  )
}

#
# Interface VPC endpoint resources
#
resource "aws_security_group" "vpc_endpoint" {
  name_prefix = "sgVpcEndpoint"
  vpc_id      = aws_vpc.default.id

  tags = merge(
    {
      Name = "sgVpcEndpoint"
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  subnet_ids          = aws_subnet.private.*.id
  private_dns_enabled = true

  tags = merge(
    {
      Name = "endpointEc2Messages"
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  subnet_ids          = aws_subnet.private.*.id
  private_dns_enabled = true

  tags = merge(
    {
      Name = "endpointSsm"
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  subnet_ids          = aws_subnet.private.*.id
  private_dns_enabled = true

  tags = merge(
    {
      Name = "endpointSsmMessages"
    },
    var.tags
  )
}

#
# NAT resources
#
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidr_blocks)

  vpc = true

  tags = merge(
    {
      Name = "ElasticIP"
    },
    var.tags
  )
}

resource "aws_nat_gateway" "default" {
  depends_on = [aws_internet_gateway.default]

  count = length(var.public_subnet_cidr_blocks)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    {
      Name = "gwNAT"
    },
    var.tags
  )
}

#
# Bastion resources
#
resource "aws_security_group" "bastion" {
  name_prefix = "sgBastion"
  vpc_id      = aws_vpc.default.id

  tags = merge(
    {
      Name = "sgBastion"
    },
    var.tags
  )
}

resource "aws_security_group_rule" "bastion_vpc_endpoint_egress" {
  type      = "egress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id        = aws_security_group.bastion.id
  source_security_group_id = aws_security_group.vpc_endpoint.id

  description = "Allow outbound TCP traffic to the interface VPC endpoints on 443."
}

resource "aws_security_group_rule" "vpc_endpoint_bastion_ingress" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id        = aws_security_group.vpc_endpoint.id
  source_security_group_id = aws_security_group.bastion.id

  description = "Allow inbound TCP traffic from the bastion on 443."
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "bastion" {
  name_prefix        = "BastionRole"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.bastion.name
  policy_arn = var.aws_ssm_managed_instance_core_policy_arn
}

resource "aws_iam_instance_profile" "bastion" {
  name_prefix = "BastionInstanceProfile"
  role        = aws_iam_role.bastion.name

  tags = var.tags
}

resource "aws_instance" "bastion" {
  ami                    = var.bastion_ami
  availability_zone      = var.availability_zones[0]
  ebs_optimized          = true
  iam_instance_profile   = aws_iam_instance_profile.bastion.id
  instance_type          = var.bastion_instance_type
  monitoring             = true
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.bastion.id]

  tags = merge(
    {
      Name = "Bastion"
    },
    var.tags
  )
}
