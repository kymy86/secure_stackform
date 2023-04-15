output "server_ip" {
  value = aws_instance.sstack_instance.public_ip
}

output "front_end_url" {
  value = "https://${var.fe_subdomain}"
}

output "back_end_url" {
  value = "https://${var.be_subdomain}"
}

output "s3_bucket_assets_access_key_id" {
  value = module.iam.s3_access_key_id
}

output "s3_bucket_assets_secret_access_key" {
  value = module.iam.s3_secret_access_key
}