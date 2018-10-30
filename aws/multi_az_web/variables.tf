variable "region" {
  default = "us-east-1"
}

variable "AMI" {
  type = "map"
  default = {
    us-east-1 = "ami-0ac019f4fcb7cb7e6"
    us-east-2 = "ami-0f65671a86f061fcd"
  }
}

variable "vpc-cidr" {
  type = "map"
  default = {
    alex = "10.0.0.0/16"
    dave = "10.1.0.0/16"
    jason = "10.2.0.0/16"
  }
}

variable "public-subnet-a-cidr" {
  type = "map"
  default = {
    alex = "10.0.0.0/24"
    dave = "10.1.0.0/24"
    jason = "10.2.0.0/24"
  }
}

variable "private-subnet-a-cidr" {
  type = "map"
  default = {
    alex = "10.0.128.0/24"
    dave = "10.1.128.0/24"
    jason = "10.2.128.0/24"
  }
}
