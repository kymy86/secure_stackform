output "sstack_vpc_id" {
    value = "${aws_vpc.sstack_vpc.id}"
}

output "sstack_subnet_id" {
    value = "${aws_subnet.public_subnet.id}"
}

output "sstack_subnet_cidr" {
    value = "${aws_subnet.public_subnet.cidr_block}"
}