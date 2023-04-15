provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_key_pair" "sstack_auth" {
  key_name   = var.aws_key_name
  public_key = file(var.aws_public_key_path)
}

module "iam" {
  source = "./iam"
}

module "network" {
  source = "./network"
}

module "security" {
  source        = "./security"
  vpc_id        = module.network.sstack_vpc_id
  my_ip_address = var.my_ip_address
}

data "aws_route53_zone" "main" {
  name = var.route53_zone_name
}

resource "aws_s3_bucket" "sstack_bucket" {
  bucket = var.s3_assets_bucket_name
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.sstack_bucket.id
  acl    = "public-read"
}

data "aws_ami" "aws_amis" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "sstack_instance" {
  ami                  = data.aws_ami.aws_amis.id
  instance_type        = var.sstack_instance_type
  key_name             = var.aws_key_name
  security_groups      = ["${module.security.sstack_sc_id}"]
  subnet_id            = module.network.sstack_subnet_id
  iam_instance_profile = module.iam.es_iam_id

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = "20"
    iops        = "100"
  }

  user_data = templatefile(
    "${path.module}/user_data/init_server.tpl",
    {
      s3_frontend_bucket_name = "${var.s3_frontend_bucket_name}"
      fe_subdomain            = "${var.fe_subdomain}"
      be_subdomain            = "${var.be_subdomain}"
      certificate_email       = "${var.certificate_email}"
      fe_subdomain            = "${var.fe_subdomain}"
    }
  )

  tags = {
    Name = "Secure stack instance"
  }
}

resource "aws_route53_record" "app_fe" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.fe_subdomain
  type    = "A"
  ttl     = var.subdomain_ttl
  records = ["${aws_instance.sstack_instance.public_ip}"]
}

resource "aws_route53_record" "app_be" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.be_subdomain
  type    = "A"
  ttl     = var.subdomain_ttl
  records = ["${aws_instance.sstack_instance.public_ip}"]
}