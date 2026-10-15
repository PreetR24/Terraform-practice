resource "aws_dynamo_table" "state_lock_table" {
    name = "state-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"

    attribute {
        name = "LockID"
        type = "S"
    }

    tags = {
        name = "state-table"
    }
}