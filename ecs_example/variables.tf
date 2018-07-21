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
