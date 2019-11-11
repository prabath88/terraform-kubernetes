variable "AWS_REGION" {
  default = "us-east-1"
}

variable "AWS_PROFILE" {
  default = "senaka"
}

variable "minion_count" {
  default = "1"
}

variable "master_count" {
  default = "1"
}

variable "PRIVATE_KEY_PATH" {
  default = "london-region-key-pair"
}

variable "PUBLIC_KEY_PATH" {
  default = "london-region-key-pair.pub"
}

variable "EC2_USER" {
  default = "ec2-user"
}
variable "AMI" {
  type = "map"

  default {
    us-east-1 = "ami-00dc79254d0461090"
  }
}
