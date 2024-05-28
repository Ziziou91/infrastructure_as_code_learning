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

## ========VPC========
resource "aws_vpc" "app-vpc" {
    cidr_block = var.vpc_cidr_block
}

## ========INTERNET GATEWAY========
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.app-vpc.id
}

## ========ROUTE TABLE========
resource "aws_route_table" "app-route-table" {
    vpc_id = aws_vpc.app-vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
    route {
        ipv6_cidr_block = "::/0"
        gateway_id = aws_internet_gateway.gw.id
    }

    tags = {
        Name = var.route_table_name
    }
}

## ========APP SUBNET========
resource "aws_subnet" "app-subnet" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = var.app_subnet_cidr_block
    availability_zone = "eu-west-1a"

    tags = {
        Name = var.app_subnet_name
    }
}

## ========DB SUBNET========
resource "aws_subnet" "db-subnet" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = var.db_subnet_cidr_block
    availability_zone = "eu-west-1a"

    tags = {
        Name = var.db_subnet_name
    }
}

## ========ASSOCIATE SUBNET WITH ROUTE TABLE========
resource "aws_route_table_association" "a" {
    subnet_id = aws_subnet.app-subnet.id
    route_table_id = aws_route_table.app-route-table.id
}

## ========APP SECURITY GROUP========
resource "aws_security_group" "tech258-joshg-allow-web" {
    name = "allow_web_traffic"
    description = "Allow TLS inbound traffic"
    vpc_id = aws_vpc.app-vpc.id
    
    ingress {
        description = "HTTPS"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]        
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "tech258-joshg-allow-web"
    }
}

## ========DB SECURITY GROUP========
resource "aws_security_group" "tech258-joshg-allow-db" {
    name = "allow_db_traffic"
    description = "Allow TLS inbound traffic"
    vpc_id = aws_vpc.app-vpc.id
    
    ingress {
        description = "mongo"
        from_port = 27017
        to_port = 27017
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]        
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "tech258-joshg-allow-db"
    }
}


## ========CREATE DB========
resource "aws_instance" "db" {
    ami = var.ami_id
    instance_type = "t2.micro"
    availability_zone = "eu-west-1a"
    
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.tech258-joshg-allow-db.id]

    subnet_id = aws_subnet.db-subnet.id

    associate_public_ip_address = true

    user_data = <<-EOF
                sudo apt update -y
                sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
                sudo apt-get install gnupg curl -y
                sudo curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
                sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
                    --dearmor --yes

                echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

                sudo apt update -y

                sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mongodb-org=7.0.6 mongodb-org-database=7.0.6 mongodb-org-server=7.0.6 mongodb-mongosh=2.2.4 mongodb-org-mongos=7.0.6 mongodb-org-tools=7.0.6

                echo "mongodb-org hold" | sudo dpkg --set-selections
                echo "mongodb-org-database hold" | sudo dpkg --set-selections
                echo "mongodb-org-server hold" | sudo dpkg --set-selections
                echo "mongodb-mongosh hold" | sudo dpkg --set-selections
                echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
                echo "mongodb-org-tools hold" | sudo dpkg --set-selections
                echo HOLD version of mongodb

                sudo sed -i "s,\\(^[[:blank:]]*bindIp:\\) .*,\\1 0.0.0.0," /etc/mongod.conf

                sudo systemctl restart mongod

                sudo systemctl enable mongod
                EOF

    tags = {
        Name = var.db_name
    }

}

# try waiting, different version of mongodb

## ========CREATE APP========
resource "aws_instance" "app" {
    ami = var.ami_id
    instance_type = "t2.micro"
    availability_zone = "eu-west-1a"
    
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.tech258-joshg-allow-web.id]
    
    subnet_id = aws_subnet.app-subnet.id


    associate_public_ip_address = true

    user_data = <<-EOF
                #!/bin/bash
                sudo cd /
                sudo apt update -y
                sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
                sudo DEBIAN_FRONTEND=noninteractive apt install nginx -y

                sudo sed -i '51s/.*/\t        proxy_pass http:\/\/localhost:3000;/' /etc/nginx/sites-enabled/default
                sudo systemctl restart nginx
                sudo systemctl enable nginx
                
                export DB_HOST=mongodb://${aws_instance.db.private_ip}:27017/posts

                curl -fsSL https://deb.nodesource.com/setup_20.x | sudo DEBIAN_FRONTEND=noninteractive -E bash - && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
            
                git clone https://github.com/Ziziou91/sparta-test-app.git

                cd /sparta-test-app/app

                sudo -E npm install

                sudo npm install -g pm2 -y
                pm2 stop app
                pm2 start app.js 
                EOF
    tags = {
        Name = var.app_name
    }
}