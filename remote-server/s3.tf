resource "aws_s3_bucket" "remote_s3" {
    bucket = "state-bucket"

    tags = {
        name = "state-bucket"
    }
}