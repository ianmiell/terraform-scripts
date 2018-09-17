output "ip_address" {
  value = "${aws_eip.ecs_cluster_eip.public_ip}"
}
