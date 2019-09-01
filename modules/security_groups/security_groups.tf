provider "aws" {
    region = "${var.region}"
}

# Init terraform
terraform {
  backend "s3" {}
}

# Map the networking remote state to find out subnet outputs
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "${var.bucket_global}"
    key    = "vpc/terraform.tfstate"
    region = "${var.region}"
  }
}

# Build security group for internal
resource "aws_security_group" "internal_sg" {
  name   = "internal_sg"
  vpc_id = data.terraform_remote_state.networking.outputs.vpc
}

# Permit traffic inbound - internal SG
resource "aws_security_group_rule" "internal_allow_all_inbound" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.internal_sg.id
}

# Permit traffic outbound - internal SG
resource "aws_security_group_rule" "internal_allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.internal_sg.id
}

# Build security group for load balancer (external)
resource "aws_security_group" "load_balancer_sg" {
  name   = "load_balancer_sg"
  vpc_id = data.terraform_remote_state.networking.outputs.vpc
}

# Permit traffic inbound - load balancer SG
resource "aws_security_group_rule" "load_balancer_allow_inbound1" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.load_balancer_sg.id
}
resource "aws_security_group_rule" "load_balancer_allow_inbound2" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.load_balancer_sg.id
}
# Permit traffic outbound - load balancer SG
resource "aws_security_group_rule" "load_balancer_allow_non_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.load_balancer_sg.id
}
