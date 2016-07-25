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


instanceId=`aws ec2 describe-instances \
  --filters "Name=tag:Name, Values=$instanceTag" \
  --query 'Reservations[*].Instances[*].[InstanceId]' \
  --output text`

echo "Selecting all AMIs that have the AMI name :" $imageName

desc=`aws ec2 describe-images --owner self \
  --filter Name=name,Values="$imageName" \
  --query 'Images[*].{ID:ImageId}' \
  --output text`

echo ImageIds : $desc
n=`echo "$desc" | wc -l`
echo "# of images exist with the name of $imageName is " : $n

if [ ! -z $desc ];
then
    echo "Delete the expired images"
    out=`aws ec2 deregister-image --image-id "$desc"`
    
    snapId=`aws ec2 describe-images --owner self \
        --filter Name=name,Values="$imageName" \
        --query 'Images[*].BlockDeviceMappings[*].Ebs[*].{ID:SnapshotId}' \
        --output text`
    echo $snapId  
    echo "Ami $desc delete status : "$out
fi

echo "creating new ami with the instance-id : "$instanceId
newAmi_id=`aws ec2 create-image \
  --no-reboot --instance-id "$instanceId" \
  --name "$imageName" --output text`

echo $newAmi_id;

echo "success !!"
