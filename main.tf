provider "aws" {
    region = "${var.aws_region}"
    profile = "${var.aws_profile}"
}

resource "aws_key_pair" "sstack_auth" {
    key_name = "${var.aws_key_name}"
    public_key = "${file(var.aws_public_key_path)}"
}

module "iam" {
    source = "./iam"
}

module "network" {
    source = "./network"
}

module "security" {
    source = "./security"
    vpc_id = "${module.network.sstack_vpc_id}"
    my_ip_address = "${var.my_ip_address}"
}

data "aws_route53_zone" "main" {  
  name = "${var.route53_zone_name}"
}

resource "aws_s3_bucket" "sstack_bucket" {
    bucket = "${var.s3_assets_bucket_name}"
    acl = "public-read"
    region = "${var.aws_region}"
}

data "template_file" "init_server" {
    template = "${(file("./user_data/init_server.tpl"))}"
     vars {
         s3_frontend_bucket_name = "${var.s3_frontend_bucket_name}"
         fe_subdomain = "${var.fe_subdomain}"
         be_subdomain = "${var.be_subdomain}"
     }
}

resource "aws_instance" "sstack_instance" {
    ami = "${lookup(var.aws_amis, var.aws_region)}"
    instance_type = "${var.sstack_instance_type}"
    key_name = "${var.aws_key_name}"
    security_groups = ["${module.security.sstack_sc_id}"]
    subnet_id = "${module.network.sstack_subnet_id}"
    iam_instance_profile = "${module.iam.es_iam_id}"

    ebs_block_device = {
        device_name = "/dev/sdb"
        volume_type = "gp2"
        volume_size = "20"
        iops = "100"
    }

    user_data = "${data.template_file.init_server.rendered}"

    tags = {
        Name = "Secure stack instance"
    }
}

resource "aws_route53_record" "app_fe" {
    zone_id = "${data.aws_route53_zone.main.zone_id}"
    name = "${var.fe_subdomain}"
    type = "A"
    ttl = "${var.subdomain_ttl}"
    records = ["${aws_instance.sstack_instance.public_ip}"]
}

resource "aws_route53_record" "app_be" {
    zone_id = "${data.aws_route53_zone.main.zone_id}"
    name = "${var.be_subdomain}"
    type = "A"
    ttl = "${var.subdomain_ttl}"
    records = ["${aws_instance.sstack_instance.public_ip}"]
}

data "template_file" "provisioner_app" {
    template = "${(file("./user_data/provisioner.tpl"))}"

    vars {
        fe_subdomain = "${var.fe_subdomain}"
        be_subdomain = "${var.be_subdomain}"
        certificate_email = "${var.certificate_email}"
    }
}

resource "null_resource" "provision_app" {
    triggers {
        subdomain_ids = "${aws_route53_record.app_be.id}"
    }
    connection {
        type = "ssh"
        host = "${aws_instance.sstack_instance.public_ip}"
        user = "${var.ssh_user}"
        private_key = "${file(var.aws_private_key_path)}"
        agent       = false
    }
    provisioner "remote-exec" {
        inline = "${data.template_file.provisioner_app.rendered}"
    }
}