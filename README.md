# ecs-eni-scaling

A shell script that can be run as a task in an ECS Cluster to push a metric to CloudWatch when a breach in the number of remaining, or percentage of used ENIs are met for your ECS Cluster(s). This is particularly useful when running tasks with awsvpc network mode.

The script sends a metric of 0 (OK), or (1) ALARM, the metric can then be configured in an alarm to contribute to your ASG scaling policy.

Ideally run as a single ECS replica service, a task role is recommended to provide IAM credentials needed for the following API calls via the AWS CLI:

```
list-container-instances
describe-container-instances
put-metric-data
```

Environment variables can be used in the task definition to override the defaults:

```
CLUSTER_LIST REGION
MAXTASKS
PERCENTTHRESHOLD - percentage of ENIs consumed in the cluster before alarming (1)
MINTHRESHOLD - minimum number of ENIs that should be availabile in the cluster
``` 
