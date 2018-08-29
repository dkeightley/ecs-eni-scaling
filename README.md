# ecs-eni-scaling

A shell script that can be run as a task in an ECS Cluster to push a metric to CloudWatch when a breach in the number of remaining, or percentage of used ENIs are met for your ECS Cluster(s). This is particularly useful when running tasks with awsvpc network mode.

The script sends a metric of 0 (OK), or 1 (ALARM), the metric can then be configured in an alarm to contribute to your ASG scaling policy.

Ideally run as a single ECS replica service, a task role is recommended to provide IAM credentials needed for the following API calls via the AWS CLI:

```
list-container-instances
describe-container-instances
put-metric-data
```

Environment variables can be used in the task definition to override the defaults:

```
CLUSTER_LIST - space separated list of cluster names, or a single cluster name
REGION - AWS region to work with
MAXTASKS - # of tasks that can be run on your instance type
PERCENTTHRESHOLD - percentage of ENIs consumed in the cluster before alarming
MINTHRESHOLD - minimum number of ENIs that should be available in the cluster, useful for small clusters
```

## Usage

* Build the Docker container

`docker build -t ecs-eni-scaling .`

* Push to your registry
* Configure a task definition with the image, environment variables, task role, and CloudWatch logs
* Monitor the CloudWatch log stream and the metrics for the new 'ECSENI' namespace
* Configure alarms based on the 0 (OK), or 1 (ALARM) value
* Add to your ASGs for each cluster as a scaling policy

### Limitations

The current script has a limit of 100 container instances per cluster as it is using a single describe-container-instances call, it could be modified to workaround this.
