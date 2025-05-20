terraform {
  #backend "s3" {
  #  bucket         = "my-terraform-state-bucket"
  #  key            = "terraform/state"
  #  region         = "us-west-2"
  #  dynamodb_table = "terraform-lock-table"
  #  encrypt        = true
  #}
  backend "local" {
    
  }
}