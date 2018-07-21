# TODO create a specific ecr?
# TODO create iam_role for tasks?

provider "aws" {
  region                  = "us-east-1"
#  shared_credentials_file = "/Users/miellian/.aws/credentials"
}

# Based on inet-facing-simple, but just a public subnet

resource "aws_vpc" "vpc_ecs_cluster" {
  cidr_block = "${var.vpc_cidr_range}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.vpc_name}"
  }
}


resource "aws_security_group" "ecs_security_group" {
    name        = "ecs_security_group"
    description = "default ECS security group"
    vpc_id      = "${aws_vpc.vpc_ecs_cluster.id}"
    ingress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_subnet" "ecs_public_subnet" {
  vpc_id = "${aws_vpc.vpc_ecs_cluster.id}"
  cidr_block = "${var.subnet_cidr_range}"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet UE1a"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc_ecs_cluster.id}"
  tags = {
    Name = "IG"
  }
}

resource "aws_route" "internet_access" {
  route_table_id = "${aws_vpc.vpc_ecs_cluster.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.gw.id}"
}

resource "aws_eip" "ecs_cluster_eip" {
  vpc = true
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.ecs_cluster_eip.id}"
  subnet_id = "${aws_subnet.ecs_public_subnet.id}"
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_route_table_association" "ecs_public_subnet_association" {
  subnet_id = "${aws_subnet.ecs_public_subnet.id}"
  route_table_id = "${aws_vpc.vpc_ecs_cluster.main_route_table_id}"
}

resource "aws_ecs_cluster" "tfcluster1" {
  name = "tfcluster1"
}

# TODO look at adding volumes and placement constraints
resource "aws_ecs_task_definition" "mytask" {
  family                = "mytask"
  container_definitions = "${file("task-definitions/mytask.json")}"

  #volume {
  #  name      = "service-storage"
  #  host_path = "/ecs/service-storage"
  #}

  #placement_constraints {
  #  type       = "memberOf"
  #  expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  #}
}

resource "aws_ecs_service" "nginx" {
  name            = "nginx"
  cluster         = "${aws_ecs_cluster.tfcluster1.id}"
  task_definition = "${aws_ecs_task_definition.mytask.arn}"
  desired_count   = 1
}



# EC2 instance
# IAM role for EC2 instances
resource "aws_iam_role" "ecsInstanceRole" {
    name               = "ecsInstanceRole"
    path               = "/"
    assume_role_policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_instance_profile" "ecs_profile_1" {
  name = "ec2_profile_1"
  role = "${aws_iam_role.ecsInstanceRole.name}"
}

resource "aws_iam_policy_attachment" "AmazonEC2ContainerServiceforEC2Role-policy-attachment" {
    name       = "AmazonEC2ContainerServiceforEC2Role-policy-attachment"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    groups     = []
    users      = []
    roles      = ["ecsInstanceRole"]
    depends_on = ["aws_iam_role.ecsInstanceRole"]
}


resource "aws_instance" "ecs_ec2_host_1" {
    ami                         = "ami-0349a96f1f1841c30"
    availability_zone           = "us-east-1a"
    ebs_optimized               = false
    instance_type               = "t2.micro"
    monitoring                  = false
    subnet_id                   = "${aws_subnet.ecs_public_subnet.id}"
    vpc_security_group_ids      = ["${aws_security_group.ecs_security_group.id}"]
    associate_public_ip_address = true
    source_dest_check           = true
    iam_instance_profile        = "${aws_iam_instance_profile.ecs_profile_1.id}"
    root_block_device {
        volume_type           = "gp2"
        volume_size           = 8
        delete_on_termination = true
    }
    ebs_block_device {
        device_name           = "/dev/xvdcz"
        volume_type           = "gp2"
        volume_size           = 22
        delete_on_termination = true
    }
    tags {}
    user_data = <<USER_DATA
#!/bin/bash
echo "ECS_CLUSTER=tfcluster1" >> /etc/ecs/ecs.config
USER_DATA
}
