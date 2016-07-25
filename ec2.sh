#!/bin/sh


usage()
{
cat <<"USAGE"

        Usage : ec2.sh [instance-tagName] [ami-name]
          Note: [instance-tagName] => Tag Name of the instance.
          Note: [ami-name] => The name of the AMI (provided during image creation)
          
USAGE
exit 0
}

## ---- use this option for multiple instances.----
# if [ -z "$1" ];
# then
#   usage
# fi

# if [ -z "$2" ];
# then
#   usage
# fi

# instanceTag=$1
# imageName=$2
##----

instanceTag="Website"
imageName="AMI_Website"

echo  "\nINFO:: Initializing Backup Script - Time                     :" $(date)
echo  "\nINFO:: Describing Ec2 Instance with Tag Name                 : $instanceTag !"

instanceId=`aws ec2 describe-instances \
  --filters "Name=tag:Name, Values=$instanceTag" \
  --query 'Reservations[*].Instances[*].[InstanceId]' \
  --output text`

echo  "\nINFO:: Selecting all AMIs that have the AMI name            :" $imageName

desc=`aws ec2 describe-images --owner self \
  --filter Name=name,Values="$imageName" \
  --query 'Images[*].{ID:ImageId}' \
  --output text`

#echo ImageIds : $desc
n=`echo "$desc" | wc -l`
echo  "\nINFO:: # of images exist with the name of $imageName is     :" $n

if [ ! -z $desc ];
then
    echo  "\nWARN:: Delete the expired AMI                              :" $desc
    out=`aws ec2 deregister-image --image-id "$desc"`
    echo  "\nINFO:: Ami $desc delete status                           : "$out
    
    snapId=`aws ec2 describe-images --owner self \
        --filter Name=name,Values="$imageName" \
        --query 'Images[*].BlockDeviceMappings[*].Ebs[*].{ID:SnapshotId}' \
        --output text`
        
    echo  "\nWARN:: Delete Snapshot                                  :" $snapId
    snapOut=`aws ec2 delete-snapshot --snapshot-id "$snapId"`
    echo  "\nINFO:: Snapshot $snapId delete status                     : "$out
fi

echo  "\nINFO:: Creating new ami with the instance-id                : "$instanceId

newAmi_id=`aws ec2 create-image \
  --no-reboot --instance-id "$instanceId" \
  --name "$imageName" --output text`

echo  "\nINFO:: New AMI Info                                           : "$instanceId

echo -e "\nSUCCESS!!"
