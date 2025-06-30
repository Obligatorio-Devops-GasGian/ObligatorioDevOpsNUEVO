# main.tf 2

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
  description = "Permite SSH, HTTP, Redis y PostgreSQL"
  vpc_id      = aws_vpc.main.id

  # ────── INGRESS ──────
  # SSH
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Redis
  ingress {
    description = "Redis"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL
  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ────── EGRESS ─────
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

########################################
# Vote
########################################
resource "aws_ecs_task_definition" "vote" {
  family                   = "vote-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "vote"
      image     = "${aws_ecr_repository.vote.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
        }
      ]
      environment = [
        {
          name  = "REDIS_HOST"
          value = var.redis_host
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/vote"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },    
    {
      name  = "redis-service"
      image = "redis:alpine"
      essential = true
      portMappings = [{ containerPort = 6379 }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/redis"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}


########################################
# Result a
########################################
resource "aws_ecs_task_definition" "result" {
  family                   = "result-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = "256"
  memory = "512"
  execution_role_arn = var.ecs_task_execution_role_arn
  task_role_arn = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name  = "result"
      image = "${aws_ecr_repository.result.repository_url}:latest"
      essential    = true
      portMappings = [{ containerPort = 80 }]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/result"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

########################################
# Worker
########################################
resource "aws_ecs_task_definition" "worker" {
  family                   = "worker-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = "256"
  memory = "512"
  execution_role_arn = var.ecs_task_execution_role_arn
  task_role_arn = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name  = "worker"
      image = "${aws_ecr_repository.worker.repository_url}:latest"
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/worker"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

########################################
# Seed-data
########################################
resource "aws_ecs_task_definition" "seed_data" {
  family                   = "seed-data-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = "256"
  memory = "512"
  execution_role_arn = var.ecs_task_execution_role_arn
  task_role_arn = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name  = "seed-data"
      image = "${aws_ecr_repository.seed_data.repository_url}:latest"
      essential = true

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/seed-data"
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}


resource "aws_ecs_service" "vote" {
  name            = "vote-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.vote.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  force_new_deployment = true
  enable_execute_command = true
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
  force_new_deployment = true
  enable_execute_command = true
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
  force_new_deployment = true
  enable_execute_command = true
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
  force_new_deployment = true
  enable_execute_command = true
  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.instance_sg.id]
    assign_public_ip = true
  }
}
//test3
########################################
# CloudWatch Log Groups
########################################

resource "aws_cloudwatch_log_group" "vote" {
  name              = "/ecs/vote"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "result" {
  name              = "/ecs/result"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/worker"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "seed_data" {
  name              = "/ecs/seed-data"
  retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "db" {
  name              = "/ecs/db"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "redis" {
  name              = "/ecs/redis"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "redis" {
  family                   = "redis-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn
  container_definitions = jsonencode([{
    name  = "redis-service"
    image = "redis:alpine"
    essential = true
    portMappings = [{ containerPort = 6379 }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/redis"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}
resource "aws_ecs_task_definition" "db" {
  family                   = "postgres-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn
  container_definitions = jsonencode([{
    name  = "db"
    image = "postgres:15-alpine"
    essential = true
    environment = [
      { name = "POSTGRES_USER", value = "postgres" },
      { name = "POSTGRES_PASSWORD", value = "postgres" }
    ]
    portMappings = [{ containerPort = 5432 }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/db"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}
resource "aws_ecs_service" "redis" {
  name            = "redis-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.redis.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.instance_sg.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "db" {
  name            = "db-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.db.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  force_new_deployment = true

  network_configuration {
    subnets          = [aws_subnet.public_subnet.id]
    security_groups  = [aws_security_group.instance_sg.id]
    assign_public_ip = true
  }
}

# CloudWatch Alarms

########################################
# SNS para notificaciones               #
########################################
resource "aws_sns_topic" "alarms" {
  name = "obligatorio-alertas"
}

# --- email ---------------
#
#
# resource "aws_sns_topic_subscription" "email_alert" {
#   topic_arn = aws_sns_topic.alarms.arn
#   protocol  = "email"
#   endpoint  = "gasvaryt@gmail.com"
# }
# 

########################################
# Parámetros globales de la alarma
########################################
locals {
  cpu_threshold          = 1   # % – se dispara con >1 % de CPU
  evaluation_periods     = 1   # basta un único período
  period_seconds         = 30  # 30 segundos de ventana
  treat_missing_strategy = "breaching"  # falta de datos = alarma
  services = {
    vote      = aws_ecs_service.vote.name
    result    = aws_ecs_service.result.name
    worker    = aws_ecs_service.worker.name
    seed_data = aws_ecs_service.seed_data.name
    redis     = aws_ecs_service.redis.name
    db        = aws_ecs_service.db.name
  }
}

########################################
# Alarmas CPU para TODOS los servicios ECS
########################################
resource "aws_cloudwatch_metric_alarm" "cpu_ultra" {
  for_each            = local.services

  alarm_name          = "${each.key}-cpu-ultra"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = local.evaluation_periods
  period              = local.period_seconds
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  threshold           = local.cpu_threshold
  alarm_description   = "CPU > ${local.cpu_threshold}% en ${each.key}-service durante ${local.period_seconds}s"
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = each.value
  }
  treat_missing_data = local.treat_missing_strategy
  alarm_actions      = [aws_sns_topic.alarms.arn]
  ok_actions         = [aws_sns_topic.alarms.arn]
}
