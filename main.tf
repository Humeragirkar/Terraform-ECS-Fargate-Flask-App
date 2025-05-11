provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true  # Important for assigning public IPs
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Route Table
resource "aws_route_table" "rtt" {
  vpc_id = aws_vpc.main.id
}

# Route
resource "aws_route" "rt" {
  route_table_id         = aws_route_table.rtt.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

# Route Table Association
resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rtt.id
}

# Security Group
resource "aws_security_group" "sg" {
  name        = "flask-app-sg"
  description = "Allow inbound on port 5000"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 5000
    to_port     = 5000
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

# ECR Repository
resource "aws_ecr_repository" "flask_app" {
  name = "python-app"
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "iam_task_exec_role" {
  name = "task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach ECS Task Execution Policy
resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role       = aws_iam_role.iam_task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "flask-app-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "taskdef" {
  family                   = "flask-app-task"
  execution_role_arn       = aws_iam_role.iam_task_exec_role.arn
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([{
    name      = "python-app",
    image     = "099066653356.dkr.ecr.us-east-1.amazonaws.com/python-app:latest",
    essential = true,
    portMappings = [
      {
        containerPort = 5000,
        protocol      = "tcp"
      }
    ]
  }])
}

# ECS Service
resource "aws_ecs_service" "flask_service" {
  name            = "flask-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.taskdef.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.sg.id]
    assign_public_ip = true
  }

}
