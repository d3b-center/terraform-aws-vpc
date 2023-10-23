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

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.default.id
  service_name      = "com.amazonaws.${var.region}.ec2messages"

  route_table_ids = flatten([
    aws_route_table.public.id,
    aws_route_table.private.*.id
  ])

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
  
  route_table_ids = flatten([
    aws_route_table.public.id,
    aws_route_table.private.*.id
  ])

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
  
  route_table_ids = flatten([
    aws_route_table.public.id,
    aws_route_table.private.*.id
  ])

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

