Creates a complete VPC and ECS cluster with an EC2 instance ready to run a simple task.

It:

- Creates VPC
- Creates security group and attaches to VPC
- Creates public subnet
- Associates subnet to main route table
- Creates Internet gateway (GW)
- Routes GW to internet
- Allocates an elastic IP (EIP) to the VPC
- Associates EIP to NAT Gateway


- Creates ECS Cluster
- Creates ECS task
- Creates ECS service
- Creates ECS IAM role for EC2
- Creates EC2 instance profile
- Attaches ECS EC2 policy to ECS IAM role for EC2
- Creates EC2 instance in ECS cluster

Files:


