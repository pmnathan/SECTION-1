# Resource blocks define physical or virtual components of your infrastructure
# or they can be logical resources
# "type" and "name" form a unique id for TF to identify

# EC2 instances
# resource "aws_instance" "my-machine" {
#   # Creates three identical aws ec2 instances
#   count = 3    
  
#   # All three instances will have the same ami and instance_type
#   ami = lookup(var.ec2_ami,var.region) 
#   instance_type = "t2.micro" 
#   vpc_security_group_ids = [aws_security_group.ec2.id]
#   subnet_id = aws_subnet.public_subnets[count.index].id
#   tags = {
#     # The count.index allows you to launch a resource 
#     # starting with the distinct index number 0 and corresponding to this instance.
#     Name = "my-machine-${count.index}"
#   }
# }
