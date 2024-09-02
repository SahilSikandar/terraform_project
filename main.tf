resource "aws_vpc" "myvpc" {
      cidr_block =var.cidr   
}
resource "aws_subnet" "subnet1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "ign" {
    vpc_id = aws_vpc.myvpc.id
  
}
resource "aws_route_table" "rt" {
    vpc_id = aws_vpc.myvpc.id
    route {
        cidr_block="0.0.0.0/0"
        gateway_id=aws_internet_gateway.ign.id
  }
  
}

resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.subnet1.id
  route_table_id = aws_route_table.rt.id
}
resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.subnet2.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "webSg" {
  name   = "web"
  vpc_id = aws_vpc.myvpc.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
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

  tags = {
    Name = "Web-sg"
  }
}

resource "aws_s3_bucket" "s3_bucket" {
    bucket = "tes1124t"
  
}

resource "aws_iam_user" "s3_user" {
  name = "s3-access-user"
  tags = {
    Name = "S3AccessUser"
  }
}

resource "aws_iam_user_policy" "s3_user_policy" {
  name = "s3-access-policy"
  user = aws_iam_user.s3_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.s3_bucket.arn,
          "${aws_s3_bucket.s3_bucket.arn}/*"
        ]
      }
    ]
  })
}
resource "aws_iam_access_key" "s3_user_key" {
  user = aws_iam_user.s3_user.name
  
}
resource "aws_instance" "test-server-1" {
    ami = var.ami_id1
    instance_type = var.ami_intancew
    subnet_id = aws_subnet.subnet1.id
    security_groups = [aws_security_group.webSg.id]
    user_data = ("/home/sahil/Downloads/terraform-project/server_1.sh")
   tags={
    Name="test-server-1"
   } 
}

resource "aws_instance" "test-server-2" {
    ami = var.ami_id1
    instance_type = var.ami_intancew
    subnet_id = aws_subnet.subnet2.id
    security_groups = [aws_security_group.webSg.id]
    user_data = file("/home/sahil/Downloads/terraform-project/server2.sh")
   tags={
    Name="test-server-2"
   } 
}
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.webSg.id]
  subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "web"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "myTG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.test-server-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.test-server-2.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}

