variable "aws_region" {
  description = "Región de AWS para desplegar la infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil de AWS CLI a usar (configurado en ~/.aws/credentials)"
  type        = string
  default     = "default"
}

variable "ecs_task_execution_role_arn" {
  description = "ARN del rol IAM ya existente para ejecución de tareas ECS"
  type        = string
  default     = "arn:aws:iam::216973958514:role/LabRole"
}
