# create a service on the cloud - launch an EC2 instance on AWS
# HCL syntax key = value


# ========PROVIDERS========
provider "github" {
  token = var.github_token
}

provider "aws" {
	region = "eu-west-1"
}

# ========GITHUB ORCHESTRATION========
resource "github_repository" "infrastructure_as_code_automated_repo" {
  name        = "infrastructure_as_code_automated_repo"
  description = "Automatically created repo with Terraform"
  visibility  = "public"
}

# ========AWS ORCHESTRATION========

# ========VPC========
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = var.vpc_name
  }
}

# ========SUBNETS========
resource "aws_subnet" "app_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.app_subnet_cidr_block

  tags = {
    Name = var.app_subnet_name
  }
}

resource "aws_subnet" "db_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.db_subnet_cidr_block

  tags = {
    Name = var.db_subnet_name
  }
}

# ========EC2 INSTANCES========
# Create EC2 app instance in app subnet
resource "aws_instance" "app_instance" {
  	tags = {
		Name = var.app_name 
	}

	ami = var.ami_id

	instance_type = "t2.micro"

# associate with subnet
  subnet_id = aws_subnet.app_subnet.id

	associate_public_ip_address = true
}

# Create EC2 db instance in app subnet
resource "aws_instance" "db_instance" {
  	tags = {
		Name = var.db_name 
	}

	ami = var.ami_id

	instance_type = "t2.micro"

# associate with subnet
  subnet_id = aws_subnet.db_subnet.id

	associate_public_ip_address = true
}






