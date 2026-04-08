#!/bin/bash
##############################################################################
# Module-04
# This assignment requires you to destroy the Cloud assets you created
# Remember to set you default output to text in the aws config command
##############################################################################
export AWS_PAGER=""
ltconfigfile="./config.json"

echo "Beginning destroy script for module-04 assessment..."

echo "Finding Launch template configuration file: $ltconfigfile..."
if [ -a $ltconfigfile ]
then
  echo "Deleting Launch template configuration file: $ltconfigfile..."
  rm $ltconfigfile
  echo "Deleted Launch template configuration file: $ltconfigfile..."
else
  echo "Launch template configuration file: $ltconfigfile doesn't exist, moving on..."
fi

echo "Finding autoscaling group names..."
ASGNAMES=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[*].AutoScalingGroupName" --output text)
if [ "$ASGNAMES" != "" ]
  then
    echo "Found AutoScalingGroups: $ASGNAMES..."
    for ASGNAME in $ASGNAMES; do
      echo "Processing Auto Scaling Group: $ASGNAME"

      aws autoscaling update-auto-scaling-group \
        --auto-scaling-group-name $ASGNAME \
        --min-size 0

      aws autoscaling update-auto-scaling-group \
        --auto-scaling-group-name $ASGNAME \
        --desired-capacity 0

      # Collect Instance IDs
      INSTANCEIDS=$(aws ec2 describe-instances --output=text --query 'Reservations[*].Instances[*].InstanceId' --filter "Name=instance-state-name,Values=running,pending")

      if [ "$INSTANCEIDS" != "" ]
        then
          echo "Waiting for all instances to be terminated..."
          aws ec2 wait instance-terminated --instance-ids $INSTANCEIDS
          echo "All instances terminated..."
        else
          echo "No instances to wait for termination..."
      fi

    done
  else
    echo "No AutoScalingGroups Detected. Perhaps check if your create-env.sh script ran properly?"
fi

echo "Finding TARGETARN..."
TARGETARN=$(aws elbv2 describe-target-groups --query "TargetGroups[*].TargetGroupArn" --output text)
if [ "$TARGETARN" != "" ]
  then
    echo "Found TargetARN: $TARGETARN..."
  else
    echo "Could not find any TargetARN. Perhaps check if the create-env.sh ran properly?"
fi

echo "Looking up ELB ARN..."
ELBARN=$(aws elbv2 describe-load-balancers --query "LoadBalancers[*].LoadBalancerArn" --output text)
echo $ELBARN

if [ "$ELBARN" != "" ]
  then
    ELBARNSARRAY=($ELBARN)
    for ELB in ${ELBARNSARRAY[@]};
      do
        echo "Deleting Listener..."
        LISTENERARN=$(aws elbv2 describe-listeners --load-balancer-arn $ELB --query 'Listeners[*].ListenerArn' --output text)
        aws elbv2 delete-listener --listener-arn $LISTENERARN
        echo "Listener deleted..."
      done
fi

if [ "$TARGETARN" = "" ]
  then
    echo "No Target Groups to delete..."
  else
    echo "Deleting target group $TARGETARN..."
    TARGETARNSARRAY=($TARGETARN)
    for TGARN in ${TARGETARNSARRAY[@]};
      do
        aws elbv2 delete-target-group --target-group-arn $TGARN
      done
fi

if [ "$ELBARN" = "" ]
  then
    echo "No ELBs to delete..."
  else
    echo "Issuing Command to delete Load Balancer..."
    aws elbv2 delete-load-balancer --load-balancer-arn $ELBARN
    echo "Load Balancer delete command has been issued..."
    echo "Waiting for ELB: $ELBARN to be deleted..."
    aws elbv2 wait load-balancers-deleted --load-balancer-arns $ELBARN
    echo "ELB: $ELBARN deleted..."
fi

echo "Finding autoscaling groups for deletion..."
ASGNAMES=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[*].AutoScalingGroupName" --output text)
if [ "$ASGNAMES" = "" ]
  then
    echo "No Autoscaling Groups found..."
  else
    echo "Autoscaling Groups: $ASGNAMES found..."
    for ASGNAME in $ASGNAMES;
      do
        echo "Deleting $ASGNAME..."
        aws autoscaling delete-auto-scaling-group --auto-scaling-group-name $ASGNAME --force-delete
        echo "Deleted $ASGNAME..."
      done
fi

echo "Finding launch-templates..."
LAUNCHTEMPLATEIDS=$(aws ec2 describe-launch-templates --query 'LaunchTemplates[].LaunchTemplateName' --output text)
if [ "$LAUNCHTEMPLATEIDS" != "" ]
  then
    echo "Found launch-template: $LAUNCHTEMPLATEIDS..."
    for LAUNCHTEMPLATEID in $LAUNCHTEMPLATEIDS; do
      echo "Deleting launch-template: $LAUNCHTEMPLATEID"
      aws ec2 delete-launch-template --launch-template-name "$LAUNCHTEMPLATEID"
    done
  else
    echo "No launch-templates found. Perhaps you forgot to run the create-env.sh script?"
fi

echo "Destroy complete."