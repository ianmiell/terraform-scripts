# TODO create a specific ecr
# TODO create iam_role for containers

provider "aws" {
  region                  = "us-east-1"
#  shared_credentials_file = "/Users/miellian/.aws/credentials"
}

# Based on inet-facing-simple, but just a public subnet

resource "aws_vpc" "vpc_tuto" {
  cidr_block = "172.31.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "TestVPC"
  }
}

resource "aws_subnet" "public_subnet_us_east_1a" {
  vpc_id = "${aws_vpc.vpc_tuto.id}"
  cidr_block = "172.31.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "subnet UE1a"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc_tuto.id}"
  tags = {
    Name = "IG"
  }
}

resource "aws_route" "internet_access" {
  route_table_id = "${aws_vpc.vpc_tuto.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.gw.id}"
}

resource "aws_eip" "tuto_eip" {
  vpc = true
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = "${aws_eip.tuto_eip.id}"
  subnet_id = "${aws_subnet.public_subnet_us_east_1a.id}"
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_route_table_association" "public_subnet_us_east_1a_association" {
  subnet_id = "${aws_subnet.public_subnet_us_east_1a.id}"
  route_table_id = "${aws_vpc.vpc_tuto.main_route_table_id}"
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
  #iam_role        = "${aws_iam_role.foo.arn}"
  #depends_on      = ["aws_iam_role_policy.foo"]
}



# EC2 instance

# IAM role for EC2 instances
# TODO apply the role to the ec2 instance
resource "aws_iam_role" "ecsInstanceRole2" {
    name               = "ecsInstanceRole2"
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
  role = "${aws_iam_role.ecsInstanceRole2.name}"
}

# TODO - extract security group

resource "aws_security_group" "ecs_security_group" {
    name        = "ecs_security_group"
    description = "default ECS security group"
    vpc_id      = "${aws_vpc.vpc_tuto.id}"

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


resource "aws_instance" "ecs_ec2_host_1" {
    ami                         = "ami-0349a96f1f1841c30"
    availability_zone           = "us-east-1a"
    ebs_optimized               = false
    instance_type               = "t2.micro"
    monitoring                  = false
    subnet_id                   = "${aws_subnet.public_subnet_us_east_1a.id}"
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

    tags {
    }
}


