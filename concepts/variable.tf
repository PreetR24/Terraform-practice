variable "ec2_instance_type" {
    default = "t2.micro"
    type = string
}

variable "ec2_default_root_instance_size" {
    default = 15
    type = number
}

variable "ec2_ami_id" {
    default = ""
    type = string
}

variable "env" {
    default = "prd"
    type = string
}