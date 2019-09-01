variable "region" {
  description = "Name of AWS region"
}

variable "account_name" {
  description = "Name of account ex. stage/prod/test"
}

variable "ami" {
  description = "AMI ID"
}

variable "instance_type" {
  description = "Type of instance"
}

variable "bucket_global" {
  description = "Name of the bucket"
}

variable "aws_key_name" {
  description = "AWS ssh key name"
}

variable "CloudTrailBucketName" {
  description = "AWS trail bucket"
}