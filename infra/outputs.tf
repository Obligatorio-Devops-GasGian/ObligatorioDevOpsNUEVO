output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecr_vote_url" {
  value = aws_ecr_repository.vote.repository_url
}
