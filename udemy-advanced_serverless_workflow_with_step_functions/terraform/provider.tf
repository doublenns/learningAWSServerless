provider "aws" {
    region = "us-west-2"
    profile = "default"
}

terraform {
    backend "s3" {

    }
}