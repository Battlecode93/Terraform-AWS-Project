#VPC
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr

  tags = {
    Name = "Terraform-VPC"
  }
}
#Subnet-1
resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = var.subnet-1-cidr
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-1"
  }
}
#Subnet-2
resource "aws_subnet" "subnet-2" {
  vpc_id = aws_vpc.myvpc.id
  cidr_block = var.subnet-2-cidr
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subnet-2"
  }
}
#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "IGW"
  }
}
#Route table associated with IGW
resource "aws_route_table" "RT" {
    vpc_id = aws_vpc.myvpc.id
    
      route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Route-Table"
  }
}
#Association of route table in subnet-1 for public internet connection
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.RT.id
}

#Association of route table in subnet-2 for public internet connection
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.subnet-2.id
  route_table_id = aws_route_table.RT.id
}

#Security Group for the Application Load Balancer
resource "aws_security_group" "alb-security-group" {
  name        = "ALB Security Group"
  description = "Enable HTTP access on Port 80"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "HTTP Access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "ALB Security Group"
  }
}


#Security group for web severs
resource "aws_security_group" "websg" {
  name        = "Web Server Security Group"
  description = "Enable HTTP access on port 80 via ALB and SSH on Port 22 via SSH SG"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "HTTP Access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups  = ["${aws_security_group.alb-security-group.id}"]
  }

  ingress {
    description      = "SSH Access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] #would want to use your own IP address for security reasons. 
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "websg"
  }
}

#s3 bucket
resource "aws_s3_bucket" "b" {
  bucket = "coreysterraformbucket"
}

#First Instance Webserver 
resource "aws_instance" "WebServer1" {
  ami           = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id = aws_subnet.subnet-1.id
  user_data = (file("userdata.sh"))

  tags = {
    Name = "WebServer1"
  }
}

#Second Instance Websever2
resource "aws_instance" "WebServer2" {
  ami           = "ami-04a81a99f5ec58529"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.websg.id]
  subnet_id = aws_subnet.subnet-2.id
  user_data = (file("userdata1.sh"))

  tags = {
    Name = "WebServer2"
  }
}

#Allow the Instance ID Metadata
resource "aws_ec2_instance_metadata_defaults" "imdsv1" {
  http_endpoint = "enabled"  
  http_tokens   = "optional"
  http_put_response_hop_limit = 1
}


#ALB
resource "aws_lb" "MyALB" {
  name               = "MyALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-security-group.id]
  subnets            = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]


  tags = {
    Name = "web"
  }
}

#Target Group for ALB
resource "aws_lb_target_group" "tg" {
  name = "myTG1"
  port = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

#Attached instances to target group
resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id = aws_instance.WebServer1.id
  port = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id = aws_instance.WebServer2.id
  port = 80
}

#Attaching load balancer to target groups
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.MyALB.arn
  port = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type = "forward"
  }
}

output "loadbalancerdns" {
  value = aws_lb.MyALB.dns_name
}