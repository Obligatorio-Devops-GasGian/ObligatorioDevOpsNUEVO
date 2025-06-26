terraform {
  backend "s3" {
    bucket         = "obligatorio-tfstate"        
    key            = "infra/terraform.tfstate"    
    region         = "us-east-1"                            
    encrypt        = true
  }
}