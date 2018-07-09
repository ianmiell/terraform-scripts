provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = "/Users/miellian/.aws/credentials"
}

resource "aws_vpc" "vpc_tuto" {
  cidr_block = "172.31.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "TestVPC"
  }
}
