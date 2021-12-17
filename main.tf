resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.tag_prefix}-vpc"
  }
}

resource "aws_subnet" "public1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone = "${var.region}a"
  tags = {
    Name = "${var.tag_prefix}-public"
  }
}

resource "aws_subnet" "public2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone = "eu-central-1b"

  tags = {
    Name = "${var.tag_prefix}-public2"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 11)
  availability_zone = "eu-central-1a"
  tags = {
    Name = "${var.tag_prefix}-private"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.tag_prefix}-gw"
  }
}


resource "aws_route_table" "publicroutetable" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.tag_prefix}-route-table-gw"
  }
}


resource "aws_eip" "nateIP" {
  vpc = true
}


resource "aws_nat_gateway" "NAT" {
  allocation_id = aws_eip.nateIP.id
  subnet_id     = aws_subnet.public1.id

  tags = {
    Name = "${var.tag_prefix}-nat"
  }

}

resource "aws_route_table" "privateroutetable" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT.id
  }

  tags = {
    Name = "${var.tag_prefix}-route-table-nat"
  }

}


resource "aws_route_table_association" "PublicRT1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.publicroutetable.id
}

resource "aws_route_table_association" "PublicRT2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.publicroutetable.id
}

resource "aws_route_table_association" "PrivateRT1" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.privateroutetable.id
}

resource "aws_security_group" "web_server_sg" {
  vpc_id      = aws_vpc.main.id
  name        = "web_server_sg"
  description = "web_server_sg"

  ingress {
    description = "http from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "icmp from internet"
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.tag_prefix}-web_server_sg"
  }
}



data "cloudinit_config" "server_config" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = file("${path.module}/scripts/webserver.yml")
  }
}

resource "aws_launch_configuration" "as_conf" {
  name_prefix     = "${var.tag_prefix}-lc"
  image_id        = var.ami
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.web_server_sg.id]
  user_data       = data.cloudinit_config.server_config.rendered

  lifecycle {
    create_before_destroy = true
  }
}

# loadbalancer Target Group
resource "aws_lb_target_group" "lb_target_group" {
  name     = "${var.tag_prefix}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# resource "aws_lb_target_group_attachment" "lb_target_group_attachment" {
#   target_group_arn = aws_lb_target_group.lb_target_group.arn
#   target_id        = aws_instance.web_server.id
#   port             = 80
# }

# application load balancer
resource "aws_lb" "lb_application" {
  name               = "${var.tag_prefix}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_server_sg.id]
  subnets            = [aws_subnet.public1.id, aws_subnet.public2.id]

  tags = {
    Environment = "${var.tag_prefix}-lb"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.lb_application.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}


resource "aws_autoscaling_group" "as_group" {
  name                      = "${var.tag_prefix}-asg"
  max_size                  = 2
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = aws_launch_configuration.as_conf.name
  vpc_zone_identifier       = [aws_subnet.private.id]
  target_group_arns         = [aws_lb_target_group.lb_target_group.id]


  tag {
    key                 = "Name"
    value               = "${var.tag_prefix}-webserver"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

}