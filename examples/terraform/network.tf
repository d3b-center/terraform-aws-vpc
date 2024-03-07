#
# VPC resources
#
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

module "vpc" {
  source = "../../"

  name        = join("", ["vpc", var.environment, var.project])
  region      = var.region
  bastion_ami = data.aws_ami.amazon_linux.id
}

resource "aws_ssm_document" "default" {
  name          = "SSM-SessionManagerRunShell"
  document_type = "Session"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Document to hold regional settings for Session Manager"
    sessionType   = "Standard_Stream"
    inputs = {
      shellProfile = {
        linux = "cd ~ && /usr/bin/env bash"
      }
    }
  })
}
