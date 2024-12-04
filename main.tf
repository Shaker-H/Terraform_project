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


resource "aws_elastic_beanstalk_application" "example_app" {
  name        = "<your-team-name>-task-listing-app"
  description = "Task listing app"
}

resource "aws_elastic_beanstalk_environment" "example_app_environment" {
  name                = "<your-team-name>-task-listing-app-environment"
  application         = aws_elastic_beanstalk_application.example_app.name

  # This page lists the supported platforms
  # we can use for this argument:
  # https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html#platforms-supported.docker
  solution_stack_name = "64bit Amazon Linux 2023 v4.0.1 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.example_app_ec2_instance_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "EC2KeyName"
    value = "your-ec2-key-pair-name"
  }
}