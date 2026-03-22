terraform {
  backend "s3" {
    bucket         = "levizitting-infra-tf-state"
    key            = "aws-global/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
