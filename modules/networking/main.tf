# Terraform code for VPC
resource "aws_vpc" "main" {
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "${var.tenancy}"

  tags = {
    Name = "main"
  }
}

# Public subnet
resource "aws_subnet" "public_subnet_1" {
  availability_zone= "us-west-2a"
  vpc_id     = "${var.vpc_id}"
  cidr_block = var.subnet_cidr_1

  tags = {
    Name = "Main"
  }
}

resource "aws_subnet" "public_subnet_2" {
    availability_zone= "us-west-2b"
  vpc_id     = "${var.vpc_id}"
  cidr_block = var.subnet_cidr_2

  tags = {
    Name = "Main"
  }
}

# Private subnet
# resource "private_subnet" "main" {
#   availability_zone       = "${var.availability_zone}"
#   cidr_block              = "${var.private_subnet_cidr}"
#   map_public_ip_on_launch = false

#   tags = {
#     Env  = "production"
#     Name = "private-us-west-2a"
#   }

#   vpc_id= "${var.vpc_id}"
# }

# Internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Env  = "production"
    Name = "internet-gateway"
  }
}

# route_table.public.tf

resource "aws_route_table" "public" {
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Env  = "production"
    Name = "route-table-public"
  }
  vpc_id = "${var.vpc_id}"
}

# route_table.private.tf

resource "aws_route_table" "private" {
  tags = {
    Env  = "production"
    Name = "route-table-private"
  }

  vpc_id = "${var.vpc_id}"
}

# route_table_association.public.tf

resource "aws_route_table_association" "aws_public_subnet_1" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_subnet_1.id
}

resource "aws_route_table_association" "aws_public_subnet_2" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_subnet_2.id
}

# # route_table_association.private.tf

# resource "aws_route_table_association" "private_subnet_1" {
#   route_table_id = aws_route_table.private.id
#   subnet_id      = aws_subnet.main.id
# }

# main_route_table_association.tf

resource "aws_main_route_table_association" "main" {
  route_table_id = aws_route_table.public.id
  vpc_id         = "${var.vpc_id}"
}

# security_group.alb.tf

resource "aws_security_group" "alb" {
  description = "security-group--alb"

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }

  name = "security-group--alb"

  tags = {
    Env  = "production"
    Name = "security-group--alb"
  }

  vpc_id = "${var.vpc_id}"
}

# alb.tf

resource "aws_alb" "default" {
  name            = "alb"
  security_groups = [aws_security_group.alb.id]

  subnets = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id,
  ]
}

# alb_target_group.tf

resource "aws_alb_target_group" "default" {
  health_check {
    path = "/"
  }

  name     = "alb-target-group"
  port     = 80
  protocol = "HTTP"

  vpc_id = "${var.vpc_id}"
}

resource "aws_alb_listener" "django" {
  load_balancer_arn = aws_alb.default.arn
  port = "80"
  protocol = "HTTP"
//  certificate_arn = var.certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.default.id
    type             = "forward"
  }
}
# security_group.ecs.tf

resource "aws_security_group" "ec2" {
  description = "security-group--ec2"

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  ingress {
    from_port       = 0
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    to_port         = 65535
  }

  name = "security-group--ec2"

  tags = {
    Env  = "production"
    Name = "security-group--ec2"
  }

  vpc_id = "${var.vpc_id}"
}

# iam_policy_document.ecs.tf

data "aws_iam_policy_document" "ecs" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

# iam_role.ecs.tf

resource "aws_iam_role" "ecs" {
  assume_role_policy = data.aws_iam_policy_document.ecs.json
  name               = "ecs_Instance_Role"
}

# iam_role_policy_attachment.ecs.tf

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# iam_instance_profile.ecs.tf

resource "aws_iam_instance_profile" "ecs" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs.name
}

# ami.tf

data "aws_ami" "default" {
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.202*-x86_64-ebs"]
  }

  most_recent = true
  owners      = ["amazon"]
}

# EC2_launch_configuration.tf

resource "aws_launch_configuration" "default" {
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ecs.name
  image_id                    = data.aws_ami.default.id
  instance_type               = "t2.micro"
  key_name                    = "COP_TEAM"

  lifecycle {
    create_before_destroy = true
  }

  name_prefix = "lauch-configuration-"

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  security_groups = [aws_security_group.ec2.id]
#   user_data       = file("user_data.sh")
}

# autoscaling_group.tf

resource "aws_autoscaling_group" "default" {
  desired_capacity     = 1
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.default.name
  max_size             = 2
  min_size             = 1
  name                 = "auto-scaling-group"

  tag {
    key                 = "Env"
    propagate_at_launch = true
    value               = "production"
  }

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "blog"
  }

  target_group_arns    = [aws_alb_target_group.default.arn]
  termination_policies = ["OldestInstance"]

  vpc_zone_identifier = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]
}

# ecs_cluster.tf

resource "aws_ecs_cluster" "production" {
  lifecycle {
    create_before_destroy = true
  }

  name = "production"

  tags = {
    Env  = "production"
    Name = "production"
  }
}

# ecs_task_definition.tf

resource "aws_ecs_task_definition" "default" {
  family = "service"
  container_definitions = jsonencode([
    {
      name      = "first"
      image     = "069653090426.dkr.ecr.us-west-2.amazonaws.com/trinity-frontend:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },
    # {
    #   name      = "second"
    #   image     = "service-second"
    #   cpu       = 256
    #   memory    = 256
    #   essential = true
    #   portMappings = [
    #     {
    #       containerPort = 443
    #       hostPort      = 443
    #     }
    #   ]
    # }
  ])

  volume {
    name      = "service-storage"
    host_path = "/ecs/service-storage"
  }

}

# ecs_task_definition.data.tf

data "aws_ecs_task_definition" "default" {
  task_definition = aws_ecs_task_definition.default.family
}

# # ecs_service.tf

# resource "aws_ecs_service" "default" {
#   name            = "mongodb"
#   cluster         = aws_ecs_cluster.production.id
#   task_definition = aws_ecs_task_definition.default.arn
#   desired_count   = 1
#   iam_role        = aws_iam_role.ecs.arn
#   depends_on      = [aws_iam_role_policy_attachment.ecs]

# #   ordered_placement_strategy {
# #     type  = "binpack"
# #     field = "cpu"
# #   }

#   load_balancer {
#     target_group_arn = aws_alb_target_group.default.arn
#     container_name   = "nginx"
#     container_port   = 80
#   }

#   placement_constraints {
#     type       = "memberOf"
#     expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
#   }
# }