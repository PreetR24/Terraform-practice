# Below things to change in this file before applying
# 1. aws public key
# 2. aws ec2 instance ami id


# key-pair (login)
resource aws_key_pair my_key {
    key_name = "terra-key-ec2"
    public_key = ""
}

# VPC & Security groups
resource aws_default_vpc default {

}

resource aws_security_group my_security_group {
    name = "automate-sg"
    description = "this will add a TF generated security group"
    vpc_id = aws_default_vpc.default.id         # interpolation

    # inbound rules

    # 1. opening port for SSH
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "SSH open"
    }
    
    # 2. opening another port for HTTP
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP open"
    }
    
    # 3. opening another port for Personal Project
    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Flask app"
    }

    # outbound rules
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"                      # for all the port ranges
        cidr_blocks = ["0.0.0.0/0"]
        description = "all access open outbound"
    }

    tags = {
        name = "automate-sg"
    }
}

# ec2 instance
resource aws_instance my_instance {    
    key_name = aws_key_pair.my_key.key_name
    security_groups = [aws_security_group.my_security_group.name]
    instance_type = var.ec2_instance_type
    ami = var.ec2_ami_id            # enter your ami id of your OS based on the region you choose
    user_data = file("install_nginx.sh")    # runs this file while creation
    
    root_block_device {
        volume_size = var.env == "prd" ? 20 : var.ec2_default_root_instance_size
        volume_type = "gp3"
    }   

    tags = {
        name = "terraform-server"
    }
}

resource aws_instance meta_arg_instance {
    # count = 2

    # for_each = tomap({
    #     Terraform-micro = "t2.micro",
    #     Terraform-medium = "t2.medium"
    # })
    
    # depends_on = [ aws_security_group.my_security_group, aws_key_pair.my_key ]

    key_name = aws_key_pair.my_key.key_name
    security_groups = [aws_security_group.my_security_group.name]
    instance_type = each.value
    ami = var.ec2_ami_id            # enter your ami id of your OS based on the region you choose
    user_data = file("install_nginx.sh")    # runs this file while creation
    
    root_block_device {
        volume_size = var.ec2_default_root_instance_size
        volume_type = "gp3"
    }   

    tags = {
        name = each.key
    }
}