resource "aws_dynamo_table" "state_lock_table" {
    name = "${var.env}-infra-app-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = var.hash_key

    attribute {
        name = var.hash_key
        type = "S"
    }

    tags = {
        name = "${var.env}-infra-app-table"
        Environment = var.env
    }
}