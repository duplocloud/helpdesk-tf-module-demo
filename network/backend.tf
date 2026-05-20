terraform {
  backend "s3" {
    bucket         = "tf-poc-state-805863115079-ap-south-1"
    key            = "network/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "tf-poc-state-lock-ap-south-1"
    encrypt        = true
  }
}
