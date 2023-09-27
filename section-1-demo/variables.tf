# aws region variable
variable "aws_region" {
    description = "AWS Region to launch servers"
    default = "us-east-2"
  
}

variable "public_subnet_cidrs" {
    type = list(string)
    description = "Public Subnet CIDR values"
    default = [ "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24" ]
}

variable "private_subnet_cidrs" {
    type = list(string)
    description = "Private Subnet CIDR values"
    default = [ "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24" ]
}


variable "azs" { #creating multiple availability zones
    type = list(string)
    description = "Availability Zones"
    default = [ "us-east-2a", "us-east-2b", "us-east-2c" ]
  
}

# Creating a Variable for ami of type map
# deploy across 3 different AZ's
variable "ec2_ami" {
  type = map

  default = {
    us-west-2a = "ami-0a55cdf919d10eac9" # https://cloud-images.ubuntu.com/locator/ec2/
    us-west-2b = "ami-092efbcc9a2d2be8a"
    us-west-2c = "ami-0b6968e5c7117349a"

  }
}

# Creating a Variable for region
variable "region" {
  default = "us-west-2a"
}

variable "ec2_instance_name" {
    description = "Name of the EC2 instance"
    default = "section1-instance"
}

variable "health_check_path" {
  description = "Health check path for the default target group"
  default = "/"
}

variable "autoscale_min" {
    description = "Minimum autoscale (number of EC2)"
    default = "3"
}

variable "autoscale_max" {
    description = "Maximum autoscale (number of EC2)"
    default = "3"
}

variable "autoscale_desire" {
    description = "Desired autoscale (number of EC2)"
    default = "3"
}


# # Creating a Variable for instance_type
variable "instance_type" {    
  default = "t2.micro"
}