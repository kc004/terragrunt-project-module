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

# Deploy AWS instances
resource "aws_instance" "server1" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id     = data.terraform_remote_state.networking.outputs.internal_subnet1
  key_name = "${var.aws_key_name}"
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 80 &
              EOF
  tags = {
    Name      = "${var.region}${var.account_name}InternalServer1"
    Terraform = "true"
  }
}

resource "aws_instance" "server2" {
  ami           = "${var.ami}"
  instance_type = "${var.instance_type}"
  subnet_id     = data.terraform_remote_state.networking.outputs.internal_subnet2
  key_name = "${var.aws_key_name}"
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, This is stage" > index.html
              nohup busybox httpd -f -p 80 &
              EOF

  tags = {
    Name      = "${var.region}${var.account_name}InternalServer2"
    Terraform = "true"
  }
}

resource "aws_cloudwatch_log_metric_filter" "myapp" {
  name           = "MyAppAccessCount"
  pattern        = ""
  log_group_name = "${aws_cloudwatch_log_group.myapplog.name}"

  metric_transformation {
    name      = "EventCount"
    namespace = "test"
    value     = "1"
  }
}

resource "aws_s3_bucket" "CloudTrailS3Bucket" {
  bucket = "${var.CloudTrailBucketName}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "CloudTrailS3Bucket" {
  bucket = "${aws_s3_bucket.CloudTrailS3Bucket.id}"
  depends_on = ["aws_s3_bucket.CloudTrailS3Bucket"]
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [{
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": { "Service": "cloudtrail.amazonaws.com" },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.CloudTrailBucketName}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": { "Service": "cloudtrail.amazonaws.com" },
            "Action": "s3:PutObject",
            "Resource": ["arn:aws:s3:::${var.CloudTrailBucketName}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"],
            "Condition": { "StringEquals": { "s3:x-amz-acl": "bucket-owner-full-control" } }
        }]

}
POLICY
}

resource "aws_cloudtrail" "terraform-CloudTrail" {
  depends_on                    = ["aws_s3_bucket_policy.CloudTrailS3Bucket"]
  name                          = "terraform-CloudTrail"
  s3_key_prefix                 = ""
  s3_bucket_name                = "${aws_s3_bucket.CloudTrailS3Bucket.id}"
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = true
}

resource "aws_cloudwatch_log_group" "myapplog" {
  name = "test"
}

resource "aws_cloudwatch_log_stream" "logstream" {
  name           = "TestLogStream"
  log_group_name = "${aws_cloudwatch_log_group.myapplog.name}"
}

data "aws_caller_identity" "current" {}