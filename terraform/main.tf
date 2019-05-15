# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

data "template_file" "task_definition" {
  template = "${file("${path.module}/task-definition.json")}"

  vars {
    container_image           = "${var.container_image}"
    container_name            = "eni-scaling"
    aws_region                = "${var.aws_region}"
    cw_log_group              = "${aws_cloudwatch_log_group.ecs.name}"
    metrics_cluster_list      = "${var.metrics_cluster_list}"
    metrics_max_tasks         = "${var.metrics_max_tasks}"
    metrics_percent_threshold = "${var.metrics_percent_threshold}"
    metrics_min_number        = "${var.metrics_min_number}"
  }
}

resource "aws_ecs_task_definition" "ecs-fargate" {
  count                 = "${var.use_fargate == "true" ? 1 : 0}"
  family                = "eni-scaling"
  task_role_arn         = "${aws_iam_role.task-role.arn}"
  execution_role_arn    = "${aws_iam_role.task-exec-role.arn}"
  requires_compatibilities = ["FARGATE"]
  network_mode          = "awsvpc"
  cpu                   = "256"
  memory                = "512"
  container_definitions = "${data.template_file.task_definition.rendered}"
}

resource "aws_ecs_task_definition" "ecs-ec2" {
  count                 = "${var.use_fargate == "true" ? 0 : 1}"
  family                = "eni-scaling"
  task_role_arn         = "${aws_iam_role.task-role.arn}"
  container_definitions = "${data.template_file.task_definition.rendered}"
}

resource "aws_ecs_service" "ecs-fargate" {
  count           = "${var.use_fargate == "true" ? 1 : 0}"
  launch_type     = "FARGATE"
  name            = "eni-scaling"
  cluster         = "${var.ecs_cluster}"
  task_definition = "${aws_ecs_task_definition.ecs-fargate.arn}"
  desired_count   = "${var.service_desired}"

  network_configuration {
    security_groups  = ["${var.fargate_security_group}"]
    subnets          = ["${var.fargate_subnets}"]
    assign_public_ip = "${var.fargate_public_ip == "true" ? true : false}"
  }

  depends_on = [
      "aws_iam_role_policy.task-role",
      "aws_iam_role_policy.task-exec-role",
      "aws_cloudwatch_log_group.ecs",
      "aws_ecs_task_definition.ecs-fargate"
  ]
}
resource "aws_ecs_service" "ecs-ec2" {
  count           = "${var.use_fargate == "true" ? 0 : 1}"
  launch_type     = "EC2"
  name            = "eni-scaling"
  cluster         = "${var.ecs_cluster}"
  task_definition = "${aws_ecs_task_definition.ecs-ec2.arn}"
  desired_count   = "${var.service_desired}"

  depends_on = [
      "aws_iam_role_policy.task-role",
      "aws_cloudwatch_log_group.ecs",
      "aws_ecs_task_definition.ecs-ec2"
  ]
}

resource "aws_cloudwatch_log_group" "ecs" {
  name = "${var.cw_log_group}"
}

resource "aws_iam_role" "task-role" {
  name = "eni-scaling-role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "task-role" {
  name = "eni-scaling-policy"
  role = "${aws_iam_role.task-role.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "ecs:ListContainerInstances",
          "ecs:DescribeContainerInstances",
          "cloudwatch:PutMetricData"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "task-exec-role" {
  count = "${var.use_fargate == "true" ? 1 : 0}"
  name = "eni-scaling-task-exec-role"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "task-exec-role" {
  count = "${var.use_fargate == "true" ? 1 : 0}"
  name = "eni-scaling-task-exec-policy"
  role = "${aws_iam_role.task-exec-role.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}