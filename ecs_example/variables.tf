variable "ecs_cluster_name" {
    type = "string"
    default = "tfcluster"
}

variable "vpc_cidr_range" {
    type = "string"
    default = "172.31.0.0/16"
}

variable "subnet_cidr_range" {
    type = "string"
    default = "172.31.1.0/24"
}

variable "vpc_name" {
    type = "string"
    default = "ECSVPC"
}

variable "ecs_public_subnet_name" {
    type = "string"
    default = "ecs_public_subnet"
}

variable "ecs_igw_name" {
    type = "string"
    default = "ecs_igw"
}

variable "ecs_az_1" {
    type = "string"
    default = "us-east-1a"
}

variable "ecs_region" {
    type = "string"
    default = "us-east-1"
}

variable "ecs_ec2_ami" {
    type = "string"
    default = "ami-0349a96f1f1841c30"
}

variable "ec2_instance_type" {
    type = "string"
    default = "t2.micro"
}

variable "ec2_keypair_name" {
    type = "string"
    default = "20180622mac"
}
