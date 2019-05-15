variable "ecs_cluster" {
  description = "The ECS Cluster to create the eni-scaling ECS Service"
  default     = "default"
}

variable "metrics_cluster_list" {
  description = "Space separated list of ECS Cluster names"
  default     = "default"
}

variable "metrics_max_tasks" {
  description = "Number of awsvpc tasks that can be run on your instance type (Max ENIs - 1)"
  default     = "2"
}

variable "metrics_percent_threshold" {
  description = "Percentage of ENIs consumed in the cluster before alarming"
  default     = "90"
}

variable "metrics_min_number" {
  description = "Minimum number of ENIs that should be available in the cluster, useful for small clusters"
  default     = "1"
}

variable "aws_region" {
  description = "The AWS region to create things in"
  default     = "us-east-1"
}

variable "service_desired" {
  description = "Desired number of Tasks in the eni-scaling ECS Service"
  default     = "1"
}

variable "container_image" {
  description = "Container image"
  default     = "derekdemo/eni-scaling:latest"
}

variable "cw_log_group" {
  description = "A CW Log group to use for eni-metric logs"
  default     = "/ecs/eni-scaling"
}

variable "use_fargate" {
  description = "(optional) Launch Tasks on Fargate, default is to use EC2 (true/false)"
  default     = "false"
}

variable "fargate_security_group" {
  description = "(required if using Fargate) Security Group for use with Fargate, outbound TCP/443 is required"
  default     = ""
}

variable "fargate_subnets" {
  description = "(required if using Fargate) Subnets for use with Fargate, connectivity to the CloudWatch and ECS endpoints is required (can be via VPC endpoints)"
  default     = ""
}

variable "fargate_public_ip" {
  description = "(required if using Fargate) Enable Public IP - choose based on whether Private/Public Subnets and VPC endpoints are used"
  default     = ""
}