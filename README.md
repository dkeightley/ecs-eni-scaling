# ecs-eni-scaling

A shell script that can be run as a task in an ECS Cluster to push metrics to CloudWatch when a breach in the minimum number of ENIs available (`MIN_AVAIL_THRESHOLD`), or percentage of used ENIs (`PERCENT_USED_THRESHOLD`) are met for your ECS Cluster(s). This is particularly useful when running tasks with awsvpc network mode.

The script sends a value of 0 (OK), or 1 (ALARM) for each metric, the metric can then be configured in a CloudWatch Alarm to contribute to your ASG Simple scaling policies. Additionally, the percentage of used ENIs is also sent as a metric for use in Target Tracking scaling policies.

The Task is Ideally run as a single ECS REPLICA service, a task role is recommended to provide IAM credentials needed for the API calls via the AWS CLI, specificially these permissions are needed:

```
ecs:ListContainerInstances
ecs:DescribeContainerInstances
cloudwatch:PutMetricData
```

Environment variables can be used in the task definition to override the defaults:

```
CLUSTER_LIST - space separated list of cluster names, or a single cluster name
REGION - AWS region to work with
MAX_TASKS - # of awsvpc tasks that can be run on your instance type (Max ENIs - 1) 
PERCENT_USED_THRESHOLD - percentage of ENIs consumed in the cluster before alarming
MIN_AVAIL_THRESHOLD - minimum number of ENIs that should be available in the cluster, useful for small clusters
```

## Usage

* Build the Docker container

`docker build -t ecs-eni-scaling .`

* Push to your registry

Or, you can use the pre-built image: `derekdemo/eni-scaling:latest`

* Configure a task definition with the image, environment variables, task role, and CloudWatch logs
* Monitor the CloudWatch log stream and the metrics for the new 'ECSENI' namespace
* Configure alarms based on the 0 (OK), or 1 (ALARM) values for the breach metrics
* Add to your ASGs for each cluster as a scaling policy

## Deploying with Terraform

```bash
cd terraform
```

Adjust the variables.tf file to update any variables for your environment

```bash
terraform init
terraform plan
terraform apply
```

## Limitations

* The current script has a limit of 100 container instances per cluster as it is using a single describe-container-instances call, it could be modified to workaround this.
* Ideal usage is for a single ASG and Cluster, although the metric/alarm can be used in a scaling policy for multiple multiple ASGs.
* The MAXTASKS is a fixed ENI amount used in the calculations, if you are using varying instance types with different ENI limits this may not work for you as desired.