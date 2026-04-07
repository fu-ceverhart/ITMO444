#!/bin/bash
##############################################################################
# Module-02 Assessement
# This assignment requires you to launch 3 EC2 instances from the commandline
# Of type t2.micro using the keypair and securitygroup ID you created 
# 
# You will need to define these variables in a text file named: arguments.txt
# Located in your Vagrant Box home directory
# 1 image-id
# 2 instance-type
# 3 key-name
# 4 security-group-ids
# 5 count
# 6 user-data install-env.sh is provided for you 
# 7 Tag (use the name: module2-tag)
##############################################################################

if [ $# = 0 ]
then
  echo 'You do not have enough variable in your arugments.txt, perhaps you forgot to run: bash ./create-env.sh $(< ~/arguments.txt)'
  exit 1
else
echo "Beginning to launch $5 EC2 instances..."

aws ec2 run-instances \
  --image-id $1 \
  --instance-type $2 \
  --key-name $3 \
  --security-group-ids $4 \
  --count $5 \
  --user-data file://$6 \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$7}]"

echo "Waiting until instances are in RUNNING state..."

INSTANCEIDS=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$7" "Name=instance-state-name,Values=pending,running" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

echo $INSTANCEIDS

if [ "$INSTANCEIDS" != "" ]
  then
    aws ec2 wait instance-running --instance-ids $INSTANCEIDS
    echo "Finished launching instances..."
  else
    echo 'There are no running or pending values in $INSTANCEIDS to wait for...'
fi

fi