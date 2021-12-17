variable "tag_prefix" {
  default = "patrick"
}

variable "region" {
  default = "eu-central-1"
}

variable "vpc_cidr" {
  default     = "10.233.0.0/16"
  description = "which private subnet do you want to use for the VPC. Subnet mask of /16"
}

variable "ami" {
  default     = "ami-0a49b025fffbbdac6"
  description = "Must be an Ubuntu image that is available in the region you choose"
}


variable "asg_min_size" {
  default     = 1
  description = "Autoscaling group minimal size"
}

variable "asg_max_size" {
  default     = 2
  description = "Autoscaling group maximal size"
}

variable "asg_desired_capacity" {
  default     = 1
  description = "Autoscaling group running number of instances"
}

