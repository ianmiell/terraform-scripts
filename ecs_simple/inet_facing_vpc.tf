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

# TODO create a specific ecr
# TODO create iam_role for tasks
# TODO create iam_role for containers

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
