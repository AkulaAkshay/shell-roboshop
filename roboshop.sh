#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0a6ae722a96642f1b"

for instance in $*
do
   #aws ec2 run-instances --image-id ami-0220d79f3f480ecf5 --instance-type m3.medium --security-group-ids sg-0a6ae722a96642f1b --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Test}]' --query 'Instances[0].InstanceId' --output text
   # lets take this into a variable 
   INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0220d79f3f480ecf5 --instance-type m3.medium --security-group-ids sg-0a6ae722a96642f1b --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

   # get private ip for non-FE and get public ip for FE
   if [ $instance != "frontend" ]; then
      IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
   else
      IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
   fi

   echo "$instance: $IP"
done