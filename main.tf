terraform {

    backend "s3" {
    bucket = "group-mrs-bucket"
    key    = "path/tf/state"
    region = "eu-west-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-2"
}

resource "" "" {


}