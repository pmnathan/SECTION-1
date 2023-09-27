resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    tags = {
        Name = "Project VPC"

    }
}
// the IGW is needed for the vpc to access the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "public_subnets"{
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = element(var.public_subnet_cidrs, count.index)
    availability_zone = element(var.azs, count.index)

    tags = {
        Name = "Public Subnet ${count.index + 1}"
    }
}

resource "aws_subnet" "private_subnets" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = element(var.private_subnet_cidrs, count.index)
    availability_zone = element(var.azs, count.index)

    tags = {
        Name = "Private Subnet ${count.index + 1}"
    }
}

resource "aws_security_group" "load-balancer" {
  name        = "load_balancer_security_group"
  description = "Controls access to the ELB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# # Instance Security group (traffic ALB -> EC2, ssh -> EC2)
resource "aws_security_group" "ec2" {
  name        = "ec2_security_group"
  description = "Allows inbound access from the ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load-balancer.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# # An internet facing ELB with connections to the 3 private subnet IP addresses of your web servers
resource "aws_elb" "elb" {
    name               = "section1-elb"
    security_groups = [aws_security_group.load-balancer.id]
    //since you want to create the ELB in the public subnets, you need to specify the public subnet IDs
   // availability_zones = [ "us-east-2a", "us-east-2b", "us-east-2c" ] 
    subnets = [aws_subnet.public_subnets[0].id, aws_subnet.public_subnets[1].id, aws_subnet.public_subnets[2].id]

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

#   listener {
#     instance_port      = 8000
#     instance_protocol  = "http"
#     lb_port            = 443
#     lb_protocol        = "https"
#     # ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
#   }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  tags = {
    Name = "section1-elb"
  }
}

# Target group
resource "aws_alb_target_group" "default-target-group" {
  name     = "${var.ec2_instance_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = var.health_check_path
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 3
    timeout             = 3
    interval            = 60
    matcher             = "200"
  }
}

# resource "aws_autoscaling_group" "ec2-cluster" {
#   availability_zones = [ "us-west-2a", "us-west-2b", "us-west-2c" ]
#   desired_capacity   = 3
#   max_size           = 5
#   min_size           = 3
#   health_check_type = "EC2"
#   launch_configuration = aws_launch_configuration.ec2.name
#   # vpc_zone_identifier  = aws_subnet.public_subnets[count.index].id
#   target_group_arns    = [aws_alb_target_group.default-target-group.arn]

#   launch_template {
#     id      = aws_launch_template.amitemp.id
#     version = "$Latest"
#   }
# }
# resource "aws_autoscaling_attachment" "asg_attachment_bar" {
#   autoscaling_group_name = aws_autoscaling_group.ec2-cluster.id
#   lb_target_group_arn    = aws_alb_target_group.default-target-group.arn
# }

# resource "aws_alb_listener" "ec2-alb-http-listener" {
#   load_balancer_arn = aws_elb.elb.id
#   port              = "80"
#   protocol          = "HTTP"
#   depends_on        = [aws_alb_target_group.default-target-group]

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_alb_target_group.default-target-group.arn
#   }
# }

# # auto 
# resource "aws_launch_template" "amitemp" {
#   name_prefix   = "section1"
#   image_id      = "ami-0a55cdf919d10eac9"
#   instance_type = "t2.micro"
# }

# # initializing an internet gateway to provide access to the internet in the VPC

# resource "aws_internet_gateway" "gw" {
#     vpc_id = aws_vpc.main.id # or: .main.id..?

#     tags = {
#         Name = "Project VPC IG"
#     }
# }

# resource "aws_eip" "nat_gateway" {
#   domain = "vpc"
#   associate_with_private_ip = "10.0.0.5"
#   depends_on                = [aws_internet_gateway.gw]
# }

# resource "aws_nat_gateway" "ngw" {
#   allocation_id = aws_eip.nat_gateway.id
#   subnet_id     = aws_subnet.public_subnets[0].id

#   tags = {
#     Name = "terraform-ngw"
#   }
#   depends_on = [aws_eip.nat_gateway]
# }

# # Route tables for the subnets
# resource "aws_route_table" "public-route-table" {
#   vpc_id = aws_vpc.main.id
#   tags = {
#     Name = "public-route-table"
#   }
# }
# resource "aws_route_table" "private-route-table" {
#   vpc_id = aws_vpc.main.id
#   tags = {
#     Name = "private-route-table"
#   }
# }

# # Route the public subnet traffic through the Internet Gateway
# resource "aws_route" "public-internet-igw-route" {
#   route_table_id         = aws_route_table.public-route-table.id
#   gateway_id             = aws_internet_gateway.gw.id
#   destination_cidr_block = "0.0.0.0/0"
# }

# # Route NAT Gateway
# resource "aws_route" "nat-ngw-route" {
#   route_table_id         = aws_route_table.private-route-table.id
#   nat_gateway_id         = aws_nat_gateway.ngw.id
#   destination_cidr_block = "0.0.0.0/0"
# }

# # associate public subnets to second route table
# resource "aws_route_table_association" "public_subnet_asso" {
#  count = length(var.public_subnet_cidrs)
#  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
#  route_table_id = aws_route_table.public-route-table.id
# }

# # associate private subnets to second route table
# resource "aws_route_table_association" "private_subnet_asso" {
#  count = length(var.private_subnet_cidrs)
#  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
#  route_table_id = aws_route_table.private-route-table.id
# }


# # create second route table and associate it with same VPC
# # we have also specified the route to the internet (0.0.0.0/0) using our IGW
# # resource "aws_route_table" "second_rt" {
# #  vpc_id = aws_vpc.main.id
 
# #  route {
# #    cidr_block = "0.0.0.0/0"
# #    gateway_id = aws_internet_gateway.gw.id
# #  }
 
# #  tags = {
# #    Name = "2nd Route Table"
# #  }
# # }

# # # conversion of multiple different resources into one vpc module
# # module "vpc" {
# #    source               = "terraform-aws-modules/vpc/aws"
# #    name                 = "vpc-main"
# #    cidr                 = "10.0.0.0/16"
# #    azs                  = ["${var.aws_region}a", "${var.aws_region}b"]
# #    private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] 
# #    public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
# #    enable_dns_hostnames = true
# #    enable_dns_support   = true
# #    enable_nat_gateway   = false
# #    enable_vpn_gateway   = false
# #    tags = {
# #        Terraform   = "true"
# #        Environment = "dev"
# #    }
# # }


# ## don't think I need this any more as I attached the subnets to the instances in the instances block!!

# # locals {
# #   public_subnets  = aws_subnet.public_subnets.cidr_block
# #   private_subnets = aws_subnet.private_subnets.cidr_block

# #   public_instance_conf = [
# #     for index, subnet in local.public_subnets : [
# #       for i in range(var.public_instance_per_subnet) : {
# #         ami                    = "ami-0a55cdf919d10eac9" # data.aws_ami.amazon_linux_ami.id
# #         instance_type          = t2.micro
# #         subnet_id              = subnet
# #         key_name               = "aws_access_key" # aws_key_pair.aws_ec2_access_key.id
# #         vpc_security_group_ids = [aws_security_group.load-balancer.id]
# #       }
# #     ]
# #   ]

# #   private_instance_conf = [
# #     for index, subnet in local.private_subnets : [
# #       for i in range(var.private_instance_per_subnet) : {
# #         ami                    = "ami-0a55cdf919d10eac9" # data.aws_ami.amazon_linux_ami.id
# #         instance_type          = t2.micro
# #         subnet_id              = subnet
# #         key_name               = "aws_access_key" # aws_key_pair.aws_ec2_access_key.id
# #         vpc_security_group_ids = [aws_security_group.load-balancer.id]
# #       }

# #     ]
# #   ]
# # }