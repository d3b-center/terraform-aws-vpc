#
# Bastion security group resources
#
resource "aws_security_group_rule" "bastion_https_egress" {
  type             = "egress"
  from_port        = 443
  to_port          = 443
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]

  security_group_id = module.vpc.bastion_security_group_id
}
