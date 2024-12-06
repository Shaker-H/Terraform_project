terraform {
  backend "s3" {
    bucket = "group-mrs-bucket"
    key    = "group-mrs-bucket/Terraform_Project"
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

resource "aws_ecr_repository" "smrrepository" {
  name = "smrrepository"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
  lifecycle {
    ignore_changes = [name] // I added this line so that if ecr repo already exists it will not make another one with same name
  }
}

resource "aws_instance" "app_server" {
  ami           = "ami-0d26eb3972b7f8c96"
  instance_type = "t2.micro"

  tags = {
    Name = "MRS_AppServer"
  }
}

resource "aws_elastic_beanstalk_application" "example_app" {
  name        = "MRS-task-listing-app"
  description = "Task listing app"
}

resource "aws_iam_role" "example_app_ec2_role" {
  name = "example-app-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "example_app_ec2_instance_profile" {
  name = "example-app-ec2-instance-profile"
  role = aws_iam_role.example_app_ec2_role.name
}

resource "aws_elastic_beanstalk_environment" "example_app_environment" {
  name        = "MRS-task-listing-app-environment"
  application = aws_elastic_beanstalk_application.example_app.name

  solution_stack_name = "64bit Amazon Linux 2023 v4.0.1 running Docker"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.example_app_ec2_instance_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "MRS"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOST"
    value     = aws_db_instance.rds_app.address
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_NAME"
    value     = aws_db_instance.rds_app.db_name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USER"
    value     = aws_db_instance.rds_app.username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
    value     = aws_db_instance.rds_app.password
  }
}

resource "aws_iam_role_policy_attachment" "beanstalk_ec2_ecr_policy" {
  role       = aws_iam_role.example_app_ec2_role.name  
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_db_instance" "rds_app" {
  allocated_storage    = 10
  engine               = "postgres"
  engine_version       = "17.2"
  instance_class       = "db.t3.micro"
  identifier           = "mrs-app-prod"
  db_name              = "mrs_db"
  username             = "root"
  password             = "password"
  skip_final_snapshot  = true
  publicly_accessible  = true
}

resource "aws_s3_bucket" "example" {
  bucket = "mrsappbucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_iam_role_policy_attachment" "beanstalk_web_tier_policy" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "beanstalk_multicontainer_docker_policy" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_role_policy_attachment" "beanstalk_worker_tier_policy" {
  role       = aws_iam_role.example_app_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

