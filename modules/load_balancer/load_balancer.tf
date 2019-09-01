provider "aws" {
    region = "${var.region}"
}

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

# Map the security_group remote state to grab security group outputs
data "terraform_remote_state" "security_groups" {
  backend = "s3"
  config = {
    bucket = "${var.bucket_global}"
    key    = "security_groups/terraform.tfstate"
    region = "${var.region}"
  }
}

# Map the servers remote state to grab security group outputs
data "terraform_remote_state" "servers" {
  backend = "s3"
  config = {
    bucket = "${var.bucket_global}"
    key    = "instances/terraform.tfstate"
    region = "${var.region}"
  }
}

# Build the load balancer
resource "aws_lb" "load_balancer" {
  name               = "${var.lb_name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [
    data.terraform_remote_state.security_groups.outputs.load_balancer_sg
  ]

  subnets = [
    data.terraform_remote_state.networking.outputs.external_subnet1,
    data.terraform_remote_state.networking.outputs.external_subnet2
  ]

  tags = {
    Name = "${var.lb_name}"
  }
}

# Create listener on load balancer to accept traffic
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_servers.arn
  }
}

# Create target group for internal servers
resource "aws_lb_target_group" "internal_servers" {
  name     = "test-internal-servers"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.networking.outputs.vpc
}

# Add hosts to the target group
resource "aws_lb_target_group_attachment" "lb_target_group_server1_attach" {
  target_group_arn = aws_lb_target_group.internal_servers.arn
  target_id        = data.terraform_remote_state.servers.outputs.server1_id
  port             = 80
}
resource "aws_lb_target_group_attachment" "lb_target_group_server2_attach" {
  target_group_arn = aws_lb_target_group.internal_servers.arn
  target_id        = data.terraform_remote_state.servers.outputs.server2_id
  port             = 80
}
