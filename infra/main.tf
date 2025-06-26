# main.tf

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "obligatorio-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "obligatorio-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "obligatorio-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "obligatorio-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "instance_sg" {
  name        = "obligatorio-sg"
  description = "Permite acceso SSH y HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
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

  tags = {
    Name = "obligatorio-sg"
  }
}

resource "aws_instance" "example" {
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.instance_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "obligatorio-instance"
  }
}

resource "aws_ecs_cluster" "main" {
  name = "obligatorio-cluster"
}

resource "aws_ecr_repository" "vote" {
  name = "vote"
}

resource "aws_ecr_repository" "result" {
  name = "result"
}

resource "aws_ecr_repository" "worker" {
  name = "worker"
}

resource "aws_ecr_repository" "seed_data" {
  name = "seed-data"
}

resource "aws_ecs_task_definition" "vote" {
  family                   = "vote-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "vote"
    image     = "${aws_ecr_repository.vote.repository_url}:latest"
    essential = true
    portMappings = [{ containerPort = 80 }]
  }])
}

resource "aws_ecs_task_definition" "result" {
  family                   = "result-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "result"
    image     = "${aws_ecr_repository.result.repository_url}:latest"
    essential = true
    portMappings = [{ containerPort = 80 }]
  }])
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "worker-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "worker"
    image     = "${aws_ecr_repository.worker.repository_url}:latest"
    essential = true
  }])
}

resource "aws_ecs_task_definition" "seed_data" {
  family                   = "seed-data-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "seed-data"
    image     = "${aws_ecr_repository.seed_data.repository_url}:latest"
    essential = true
  }])
}

resource "aws_ecs_service" "vote" {
  name            = "vote-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.vote.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.instance_sg.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "result" {
  name            = "result-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.result.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.instance_sg.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "worker" {
  name            = "worker-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.instance_sg.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "seed_data" {
  name            = "seed-data-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.seed_data.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.instance_sg.id]
    assign_public_ip = true
  }
}
//test2