variable "aws_region" {
  description = "AWS region where resources will be provisioned"
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-07a00cf47dbbc844c"
}

variable "instance_type" {
  description = "Instance type for the EC2 instance"
  default     = "c7i-flex.large"
}
