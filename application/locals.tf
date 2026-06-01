data "aws_caller_identity" "current" {}

# Read the network root's outputs from S3 in the matching workspace.
data "terraform_remote_state" "network" {
  backend   = "s3"
  workspace = terraform.workspace
  config = {
    bucket = "tf-poc-state-805863115079-ap-south-1"
    key    = "network/terraform.tfstate"
    region = "ap-south-1"
  }
}

# Latest Amazon Linux 2 AMI in the current region.
data "aws_ssm_parameter" "amzn2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

locals {
  common_tags        = { env = var.env_name }
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  public_subnet_ids  = data.terraform_remote_state.network.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
  effective_ami      = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.amzn2_ami.value
  account_id         = data.aws_caller_identity.current.account_id
}
