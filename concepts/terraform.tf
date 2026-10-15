terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
    }

    # linking the remote backend for state locking and management
    # backend "s3" {
    #     bucket = "state-bucket"
    #     key = "terraform.tfstate"
    #     region = "us-east-2"
    #     dynamodb_table = "state-table"
    # }
}