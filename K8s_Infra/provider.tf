terraform {
required_version = ">= 1.6.3"

  backend "s3" {
    endpoints = {
      s3 = "https://sfo3.digitaloceanspaces.com" 
    }

    bucket = "reverseip-statefile"
    key    = "${TF_VAR_BACKEND_digitalocean_spaces_key}"

    access_key = "${TF_VAR_BACKEND_digitalocean_spaces_access_key}"
    secret_key = "${TF_VAR_BACKEND_digitalocean_spaces_secret_key}"
  

    # Deactivate a few AWS-specific checks
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true
    region                      = "us-east-1"
  }
}