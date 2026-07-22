#!/bin/bash

#creating ec2-instance and updating the route53 record
#-----------------------------------------------------

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0a6ae722a96642f1b"
HOSTED_ZONE_ID="Z02237942WL8S6DN4RI1T"
DOMAIN_NAME="akshaysunny.space" #akshaysunny.space

for instance in $*
do
   #aws ec2 run-instances --image-id ami-0220d79f3f480ecf5 --instance-type m3.medium --security-group-ids sg-0a6ae722a96642f1b --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Test}]' --query 'Instances[0].InstanceId' --output text
   # lets take this into a variable 
   INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type m3.medium --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

   # get private ip for non-FE and get public ip for FE
   if [ $instance != "frontend" ]; then
      IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
      RECORD_NAME="$instance.$DOMAIN_NAME" #mongodb.akshaysunny.space
   else
      IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
      RECORD_NAME="$DOMAIN_NAME" #akshaysunny.space
   fi

   echo "$instance: $IP"


   aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID2 \
  --change-batch '
  {
    "Comment": "updating route53 record"
    ,"Changes": [{
      "Action"              : "UPSERT" #similar to UPDATE
      ,"ResourceRecordSet"  : {
        "Name"              : "'$RECORD_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "'$IP'"
        }]
      }
    }]
  }
done