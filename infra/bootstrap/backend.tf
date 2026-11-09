# Bootstrap state lives in the S3 bucket this layer creates (state.tf).
# Account-specific values (bucket, profile) are passed at init time:
#   cp backend.hcl.example backend.hcl   # fill in your account ID
#   terraform init -backend-config=backend.hcl
#
# Fresh account only (bucket doesn't exist yet): comment out this block, apply once with
# local state, then uncomment and run `terraform init -migrate-state -backend-config=backend.hcl`.

terraform {
  backend "s3" {
    key          = "bootstrap/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
    encrypt      = true
  }
}
