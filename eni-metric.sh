#!/bin/sh

### Cluster information - overide with environment variables or use defaults
### Override: CLUSTER_LIST, REGION, MAXTASKS, PERCENTTHRESHOLD, MINTHRESHOLD
_CLUSTER_LIST=${CLUSTER_LIST:-default}
_REGION=${REGION:-us-east-1}
### Number of awsvpc tasks that the cluster instance type can launch, used to form the percentage and # of interfaces available
_MAXTASKS=${MAXTASKS:-2}
### % threshold of interface attachments consumed in the cluster to alarm on
_PERCENTTHRESHOLD=${PERCENTTHRESHOLD:-85}
### min # of interface attachments available to alarm on
_MINTHRESHOLD=${MINTHRESHOLD:-1}
### CloudWatch metric name
_CWMETRICSUFFIX=eni-breach
_CWNAMESPACE=ECSENI
### Polling frequency (seconds)
_SLEEP=60

#################################
## Ensure we have some basic the dependencies
echo "Performing initial checks to ensure we have AWS credentials, and jq installed."
aws sts get-caller-identity
if [ $? -ne 0 ]
  then
    echo "Issue authenticating with the aws cli"
    exit 1
fi
jq --version > /dev/null 2>&1
if [ $? -ne 0 ]
  then
    echo "I need jq installed, sorry"
    exit 1
fi

#################################
## Start looping over the interval

## Create an array of the $_CLUSTER_LIST to loop
set $_CLUSTER_LIST

echo "Running."

while true
  do
    for _CLUSTER in $@
      do
        ## Get the container instances in the cluster
        _LIST=$(aws ecs list-container-instances --region $_REGION --cluster $_CLUSTER)
        if [ $? -ne 0 ]
          then
            echo "`date +%FT%TZ` there was an issue listing instances in the cluster ($_CLUSTER)"
            break 1
          else
            _INSTANCES=$(echo $_LIST | jq -r '.containerInstanceArns[]' | cut -d/ -f2- | paste -s -d' ' -)
        fi
        _INSTANCECOUNT=$(echo $_INSTANCES | wc -w | awk '{$1=$1};1')

        ## If there is at least one instance, get attachments, calculate % and count. Otherwise, do nothing.
        if [ $_INSTANCECOUNT -ge 1 ]
          then
            _ATTACHMENTCOUNT=$(aws ecs describe-container-instances --region $_REGION --cluster $_CLUSTER --container-instances `echo $_INSTANCES` | jq '.containerInstances[].attachments[].status' | wc -l)
            _CLUSTERMAX=$(echo "$_MAXTASKS * $_INSTANCECOUNT" | bc)
            _PERCENTUSED=$(echo "scale=1; $_ATTACHMENTCOUNT / $_CLUSTERMAX * 100" | bc -l | cut -d. -f1)
            _REMAINING=$(echo "$_CLUSTERMAX - $_ATTACHMENTCOUNT" | bc)

            if [[ $_PERCENTUSED -ge $_PERCENTTHRESHOLD || $_REMAINING -le $_MINTHRESHOLD ]]
              then
                # Alarm
                _VALUE=1
                echo "`date +%FT%TZ` Sending alarm (1) to $_CWNAMESPACE/$_CLUSTER-$_CWMETRICSUFFIX for a breach of the percentage ($_PERCENTUSED/$_PERCENTTHRESHOLD) of used, or number ($_REMAINING/$_CLUSTERMAX) of remaining ENIs in the cluster."
              else
                _VALUE=0
            fi

            ## Send the metric
            aws cloudwatch put-metric-data --metric-name $_CLUSTER-$_CWMETRICSUFFIX --namespace $_CWNAMESPACE --value $_VALUE --region $_REGION --unit Count --timestamp `date +%FT%TZ`
            if [ $? -ne 0 ]
              then
                echo "`date +%FT%TZ` there was an issue with sending the metric for $_CLUSTER-$_CWMETRICSUFFIX"
                break 1
            fi
        fi
      done
  sleep $_SLEEP
done
