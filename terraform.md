# Terraform 

Terraform is an open-source, cloud-agnostic orchestration tool that allows us to manage architecture using infrastructure as code.

Terraforms excellent documentation, readability of it's .tf files (written in proprietary hcl language - similar to JSON) and widespread adoption makes terraform scripts easy to use.

Thanks to Terraform being cloud-agnostic it allows us to create scripts for multi-cloud deployment.

Mutli-cloud is vital for organisations that need:
- High availability. If 1 cloud provider is not available then we still have another.
- The need for services exclusive to different cloud providers. 
- Regulatory compliance. Some industries and sectors require organisations to adopt a multi-cloud model.

The FCA has made multi-cloud a requirement for financial services organisations. This makes a service to manage multi-cloud architectures, such as terraform, very valuable.

## Setting up terraform and launching an EC2 instance

![Terraform diagram](./images/terraform/terraform-diagram.png)

1) Download the latest version of terraform from the [official website](https://developer.hashicorp.com/terraform/install)
   ![download terraform](./images/terraform/image_1.png)
2) Extract *terraform.exe* and move into the directory `c:/terraform`
    ![install terraform](./images/terraform/image_2.png)
3) Update the `PATH` environment variable include were terraform is located:
    ![add terraform to PATH environment variable](./images/terraform/image_3.png)
4) Close and reopen bash, then check the variable has been set by running `terraform -v`
5) We need to add our AWS access key details (both ACCESS_KEY_ID and SECRET_KEY) as environment variables. Add them in the same tool we used for PATH with the following keys
```bash
AWS_ACCESS_KEY_ID : ASDSADASDSADASDSA
AWS_SECRET_KEY: ASDSADASDSADASD
```   
6) We can then initialise our terraform installation with the command `terraform init`
7) We can now start building our first terraform script (written in HCL). We'll call this `main.tf`
```hcl
# create a service on the cloud - launch an EC2 instance on AWS
# HCL syntax key = value

# where on AWS - which region?
provider "aws" {

        region = "eu-west-1"
}

# aws-access-key-id = ajsadhjvcbkjh MUST NOT HARDCODE THE KEY
# aws-secret-access-key = adsad MUST NOT HARDCODE THE KEY
# MUST NOT PUSH ANYTHING TO GITHUB UNTIL WE HAVE CREATED A .gitignore file

# Which service/resources - EC2
resource "aws_instance" "app_instance" {


# which type of instance - ami to use
        ami = "ami-example"

# t2 micro
        instance_type = "t2.micro"

# associate public ip with this instance
        associate_public_ip_address = true

# name the ec2/resource
        tags = {
                Name = "joshg-sample-app"
        }
}
```
8) we can check this is valid by running `terraform plan`   
9) Apply the configuration with `terraform apply`

NOTE: running just `terraform` provides us with a very useful help screen.

## Creating more complex architecture with terraform

Terraforms capabilities go far beyond just launching virtual machines. We are able to launch entire VPCs, subnets, route tables and blob storage with just a few lines in a .tf file.

Launching a VPC can be as simple as 
```hcl
provider "aws" {
	region = "eu-west-1"
}

# Create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name = "joshg-sample-vpc"
  }
}
```

## Abstracting sensitive information in our Terraform files

In order to make our architecture more secure we can remove the need for any hardcoded sensitive information. Our VPC details, CIDR blocks, and ami type should not be kept in our main.tf

We can move this information into a variable.tf file, and add it to our .gitignore file

### Tasks

- Create/push to a github repo with terraform, using ssh/token/https 