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
      Name = "${var.name}-gwInternet"
    },
    var.tags
  )
}

resource "aws_egress_only_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id

  tags = merge(
    {
      Name = "${var.name}-gwInternetEgressOnly"
    },
    var.tags
  )
}

resource "aws_route_table" "private" {
  count = length(var.private_subnet_cidr_blocks)

  vpc_id = aws_vpc.default.id

  tags = merge(
    {
      Name = "${var.name}-PrivateRouteTable-${var.availability_zones[count.index]}"
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
      Name = "${var.name}-PublicRouteTable"
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
      Name = "${var.name}-PrivateSubnet-private-az${var.availability_zones[count.index]}"
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
      Name = "${var.name}-PublicSubnet-public-az${var.availability_zones[count.index]}"
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
      Name = "${var.name}-endpointS3"
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
      Name = "${var.name}-sgVpcEndpoint"
    },
    var.tags
  )
}

resource "aws_security_group_rule" "vpc_endpoint_ingress" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"

  security_group_id = aws_security_group.vpc_endpoint.id
  cidr_blocks       = [var.cidr_block]

  description = "Allow inbound TCP traffic from the VPC on 443."
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
      Name = "${var.name}-endpointEc2Messages"
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
      Name = "${var.name}-endpointSsm"
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  subnet_ids          = aws_subnet.private.*.id
  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-endpointSecretsManager"
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "cloudwatch" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.monitoring"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  subnet_ids          = aws_subnet.private.*.id
  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-endpointCloudWatch"
    },
    var.tags
  )
}

resource "aws_vpc_endpoint" "cw_logs" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  subnet_ids          = aws_subnet.private.*.id
  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-endpointCloudWatchLogs"
    },
    var.tags
  )
}


resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  subnet_ids          = aws_subnet.private.*.id
  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-endpointECR_API"
    },
    var.tags
  )
}


resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.vpc_endpoint.id
  ]

  subnet_ids          = aws_subnet.private.*.id
  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-endpointECR_DKR"
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
      Name = "${var.name}-endpointSsmMessages"
    },
    var.tags
  )
}

#
# NAT resources
#
resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidr_blocks)

  domain = "vpc"

  tags = merge(
    {
      Name = "${var.name}-NatElasticIP-${var.availability_zones[count.index]}"
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
      Name = "${var.name}-gwNAT-${var.availability_zones[count.index]}"
    },
    var.tags
  )
}
