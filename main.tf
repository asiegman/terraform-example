provider "aws" {
  region = "${var.region}"
}

resource "aws_vpc" "default" {
  cidr_block = "${lookup(var.vpc-cidr, terraform.workspace)}"

  tags {
    Name = "vpc-${terraform.workspace}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "Internet Gateway"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "public_a" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${lookup(var.public-subnet-a-cidr, terraform.workspace)}"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_a" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${lookup(var.private-subnet-a-cidr, terraform.workspace)}"
  map_public_ip_on_launch = false
}

resource "aws_security_group" "web_elb" {
  name        = "web-elb"
  description = "Web ELB Security Group"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "linux_management" {
  name        = "linux-management"
  description = "Management needs for Linux instances"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "devops-scratch" {
  key_name   = "devops-scratch"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0D10pleUmZSCgaxjm1N+c4Ndt5GXixiMcnh2MJ6GAUsyREJ1H+RgHMTm0AojtyWLJ3PpvaMtduJiZQj+cKQjdpGva3Irm2Y2M1KsLl/E9/vpGbaLytWmibtM2JWnwRNFahB2WZ2WAMQ874R/9MHn1PW+4Gn7jvNzK+4M3Us+o506tkyakv0QuJESoPxF7WJRDWiYzISnoMcpWiSft40jqJVJb2KXnUV9gW/bhuEXoZHtvzkae8AIEixkYoXCvA0LTvGw2upYzmE91V1OmY1TcfHHRj9qTens5z/NzAHy6XGoHCLGI42LUHNQdVq5hTh/vVUDnvzb7zXau5ZgFAMs3"
}

resource "aws_instance" "ssh_bastion" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("~/.ssh/devops-scratch.pem")}"
  }

  instance_type = "t2.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${lookup(var.AMI, var.region)}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.devops-scratch.key_name}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [
    "${aws_security_group.linux_management.id}"
  ]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.public_a.id}"

  # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt install -y python3-pip"
    ]
  }
}
