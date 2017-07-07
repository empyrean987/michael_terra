# First Terraform Recipe to create a private vpc with a bastion host and web instance
# 1. Create private VPC for Web & Resource Instances

variable "vpc_web_test_id" {}

data "aws_vpc" "selected" {
  id = "${var.vpc_web_test_id}"
}

resource "aws_subnet" "vpc_web_test_subnet" {
  vpc_id            = "${data.aws_vpc.selected.id}"
  availability_zone = "us-west-2a"
  cidr_block        = "${cidrsubnet(data.aws_vpc.selected.cidr_block, 4, 1)}"
}


#2. Create a bastion host with external & Internal IP Address in that VPC
resource "aws_network_interface" "internal" {
  subnet_id = "${aws_subnet.vpc_web_test_subnet.id}"
  tags {
    Name = "internal_network_interface"
  }
}

resource "aws_instance" "foo" {
    ami = "ami-22b9a343" // us-west-2
    instance_type = "t2.micro"
    network_interface {
     network_interface_id = "${aws_network_interface.internal.id}"
     device_index = 0
  }
}





resource "aws_vpc" "default" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_subnet" "tf_test_subnet" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_instance" "foo" {
  # us-west-2
  ami           = "ami-5189a661"
  instance_type = "t2.micro"

  private_ip = "10.0.0.12"
  subnet_id  = "${aws_subnet.tf_test_subnet.id}"
}

resource "aws_eip" "bar" {
  vpc = true

  instance                  = "${aws_instance.foo.id}"
  associate_with_private_ip = "10.0.0.12"
}