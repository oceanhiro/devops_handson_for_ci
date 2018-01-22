variable "region" {
    default = "ap-northeast-1" 
}

provider "aws" {
    region     = "${var.region}" 
}

resource "aws_vpc" "devops_handson_vpc_for_ci" {
    cidr_block           = "10.10.0.0/16" 
    instance_tenancy     = "default" 
    enable_dns_support   = "true" 
    enable_dns_hostnames = "false" 
    tags {
        Name = "devops_handson_vpc_for_ci" 
    }
}

resource "aws_internet_gateway" "devops_handson_gw_for_ci" {
    vpc_id = "${aws_vpc.devops_handson_vpc_for_ci.id}" 
}

resource "aws_subnet" "public_a_for_ci" {
    vpc_id            = "${aws_vpc.devops_handson_vpc_for_ci.id}" 
    cidr_block        = "10.10.1.0/24" 
    availability_zone = "ap-northeast-1a" 
}

resource "aws_subnet" "private_a_for_ci" {
    vpc_id            = "${aws_vpc.devops_handson_vpc_for_ci.id}" 
    cidr_block        = "10.10.2.0/24" 
    availability_zone = "ap-northeast-1a" 
}

resource "aws_route_table" "public_route_for_ci" {
    vpc_id = "${aws_vpc.devops_handson_vpc_for_ci.id}"
    route {
        cidr_block = "0.0.0.0/0" 
        gateway_id = "${aws_internet_gateway.devops_handson_gw_for_ci.id}" 
    }
    tags {
        Name = "public_route_for_ci"
    }
} 

resource "aws_route_table" "private_route_for_ci" {
    vpc_id = "${aws_vpc.devops_handson_vpc_for_ci.id}"
    tags {
        Name = "private_route_for_ci"
    }
}

resource "aws_route_table_association" "public_a_for_ci" {
    subnet_id      = "${aws_subnet.public_a_for_ci.id}" 
    route_table_id = "${aws_route_table.public_route_for_ci.id}" 
}

resource "aws_route_table_association" "private_a_for_ci" {
    subnet_id      = "${aws_subnet.private_a_for_ci.id}" 
    route_table_id = "${aws_route_table.private_route_for_ci.id}" 
}

resource "aws_security_group" "ssh_sg" {
  name        = "ssh_sg"
  description = "for ssh sg."
  vpc_id      = "${aws_vpc.devops_handson_vpc_for_ci.id}"
}

// Allow any internal network flow.
resource "aws_security_group_rule" "ingress_any_any_self_ssh" {
  security_group_id = "${aws_security_group.ssh_sg.id}"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  type              = "ingress"
}

// Allow egress all
resource "aws_security_group_rule" "egress_all_all_all_ssh" {
  security_group_id = "${aws_security_group.ssh_sg.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}

// Allow SSH:22 (SSH)
resource "aws_security_group_rule" "ingress_tcp_22_cidr" {
  security_group_id = "${aws_security_group.ssh_sg.id}"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

resource "aws_security_group" "web_app_sg" {
  name        = "web_app_sg"
  description = "for web app sg."
  vpc_id      = "${aws_vpc.devops_handson_vpc_for_ci.id}"
}

// Allow any internal network flow.
resource "aws_security_group_rule" "ingress_any_any_self" {
  security_group_id = "${aws_security_group.web_app_sg.id}"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  self              = true
  type              = "ingress"
}

// Allow egress all
resource "aws_security_group_rule" "egress_all_all_all" {
  security_group_id = "${aws_security_group.web_app_sg.id}"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}

// Allow TCP:80 (HTTP)
resource "aws_security_group_rule" "ingress_tcp_80_cidr" {
  security_group_id = "${aws_security_group.web_app_sg.id}"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

// Allow TCP:443 (HTTPS)
resource "aws_security_group_rule" "ingress_tcp_443_cidr" {
  security_group_id = "${aws_security_group.web_app_sg.id}"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

// Allow TCP:8080 (HTTP-ALT)
resource "aws_security_group_rule" "ingress_tcp_8080_cidr" {
  security_group_id = "${aws_security_group.web_app_sg.id}"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

// CI Server.
resource "aws_instance" "ci-server" {
    ami           = "ami-8ef55ee8" 
    instance_type = "t2.micro" 
    key_name      = "keypair_ocean_key.pem" 
    vpc_security_group_ids = [
        "${aws_security_group.web_app_sg.id}",
	"${aws_security_group.ssh_sg.id}"
    ]
    subnet_id = "${aws_subnet.public_a_for_ci.id}" 
    associate_public_ip_address = "true" 
    root_block_device = {
        volume_size = "20" 
    }
    tags {
        Name = "ci-server" 
    }
}
