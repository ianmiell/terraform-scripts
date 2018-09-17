output "ip_address" {
  value = "${aws_instance.ecs_ec2_host_1.public_ip}"
}
