variable "aws_region" {
    description = "AWS region where launch servers"
    default = "eu-west-1"
}

variable "aws_profile" {
    description = "aws profile"
    default = "default"
}

variable "aws_amis" {
    default = {
        eu-central-1 = "ami-1e339e71"
        eu-west-2 = "ami-996372fd"
        eu-west-1 = "ami-785db401"
    }
}

variable "sstack_instance_type" {
    default = "t2.medium"
}

variable "aws_private_key_path" {
    description = <<DESCRIPTION
Path to the SSH private key to be used for authentication.
Example: ~/.ssh/private_key.pem
DESCRIPTION
}

variable "aws_public_key_path" {
    description = <<DESCRIPTION
Path to the SSH public key to be used for authentication.
Ensure this keypair is added to your local SSH agent so provisioners can
connect.
Example: ~/.ssh/public_key.pub
DESCRIPTION
}

variable "aws_key_name" {
    description = "Name of the AWS key pair"
}

variable "fe_subdomain" {
    description = "URL (with no http) of front-end application"
}

variable "be_subdomain" {
    description = "URL (with no http) of back-end application"
}

variable "certificate_email" {
    description = "Email for certbot certification process"
}

variable "route53_zone_name" {
    description = "name of your main domain zone"
}

variable "subdomain_ttl" {  
  default = "60"
}

variable "my_ip_address" {
    description = "CIDR address from where the SSH connection to the instance is allowed"
}

variable "ssh_user" {
    description = "username for SSH agent"
    default = "ubuntu"
}

variable "s3_frontend_bucket_name" {
    description = "Bucket name where the frontend files are placed"
}

variable "s3_assets_bucket_name" {
    description = "Bucket where back-end stores the asset files"
}
