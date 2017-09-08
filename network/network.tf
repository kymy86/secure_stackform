resource "aws_vpc" "sstack_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags = {
        Name = "Secure Stack VPC"
    }
}

resource "aws_internet_gateway" "sstack_gateway" {
    vpc_id = "${aws_vpc.sstack_vpc.id}"
    tags = {
        Name = "Secure Stack Gateway"
    }
}

resource "aws_route" "public_access" {
    route_table_id = "${aws_vpc.sstack_vpc.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.sstack_gateway.id}"
}

resource "aws_subnet" "public_subnet" {
    vpc_id = "${aws_vpc.sstack_vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    tags = {
        Name = "Public subnet"
    }
}

resource "aws_route_table_association" "public_subnet_association" {
    subnet_id = "${aws_subnet.public_subnet.id}"
    route_table_id = "${aws_vpc.sstack_vpc.main_route_table_id}"
}