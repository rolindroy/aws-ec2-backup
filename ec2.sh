#!/bin/sh

usage() {
  echo ""
  echo Usage: $0 [instance-id] [ami-name]
  echo "    Note: [instance-id] => The ID of the instance."
  echo "    Note: [ami-name] => The name of the AMI (provided during image creation)"
  echo ""
  exit 1
}

if [ -z "$1" ];
then
  usage
fi

if [ -z "$2" ];
then
  usage
fi

instanceId=$1
imageName=$2

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
    echo $out
fi

echo "creating new ami with the instance-id : "$instanceId
newAmi_id=`aws ec2 create-image --no-reboot --instance-id "$instanceId" --name "$imageName" --output text`

echo $newAmi_id;