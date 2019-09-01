variable "region" {
  description = "Name of AWS region"
}

variable "bucket_global" {
  description = "Name of the bucket"
}

variable "aws_one_az" {
  default = "Name of the first availability zone:"
}
variable "aws_two_az" {
  default = "Name of the second availability zone:"
}

variable "cidr_prefix" {
  description = "Such as 10.55., used for building subnets, VPCs, etc."
}

variable "account_name" {
  description = "Name of account ex. stage/prod/test"
}
