variable "env" {
    description = "This is the environment for my infra"
    type = string
}

variable "bucket_name" {
    description = "This is the bucket name for my infra"
    type = string
}

variable "ec2_instance_count" {
    description = "This is the instance count of ec2"
    type = number
}

variable "ec2_instance_type" {
    description = "This is the instance type of ec2"
    type = string
}

variable "ec2_ami_id" {
    description = "This is the instance ami id of ec2"
    type = string
}

variable "hash_key" {
    description = "This is the hash key for my dynamodb table"
    type = string
}