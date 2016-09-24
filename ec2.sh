#!/bin/bash


usage()
{
cat <<"USAGE"

        Usage : ec2.sh [instance-tagName] [ami-name]
          Note: [instance-tagName] => Tag Name of the instance.
          Note: [ami-name] => The name of the AMI (provided during image creation)
          
        --
        @author Rolind Roy <hello@rolindroy.com>
          
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

##Todo
instanceTag="Website"
deletionDate=`date -u -d '-2day' +%Y%m%d`

imageNamePrefix="AMI_"$instanceTag"_"
currentDate=`date -u +%Y%m%d`
imageName=$imageNamePrefix$currentDate


echo $currentDate
echo $deletionDate

echo  "\nINFO:: Initializing Backup Script - Time  :" $(date)
echo  "INFO:: Describing Ec2 Instance with Tag Name $instanceTag !"

instanceId=`aws ec2 describe-instances \
  --filters "Name=tag:Name, Values=$instanceTag" \
  --query 'Reservations[*].Instances[*].[InstanceId]' \
  --output text`

echo  "INFO:: Selecting all AMIs that have the AMI prefix " $imageNamePrefix

desc=`aws ec2 describe-images --owner self \
  --filter Name=name,Values="$imageNamePrefix*" \
  --query 'Images[*].Name' \
  --output text`
  
echo $desc
n=`echo "$desc" | wc -w`
echo  "INFO:: # of images exist with the prefix name of $imageNamePrefix is  :" $n

if [ $n -ge "0" ] ;
then
    for img in $desc
    do
		imagedate=`echo $img |  awk -F_ '{ print $3 }'`
		echo -e $imagedate "\n"
		
		if [ $deletionDate -gt $imagedate ]; 
		then
			expire_ami=`aws ec2 describe-images --owner self \
			  --filter Name=name,Values="$img" \
			  --query 'Images[*].{ID:ImageId}' \
			  --output text`
			
			expire_snap=`aws ec2 describe-images --owner self \
		   --filter Name=name,Values="$imageName" \
		   --query 'Images[*].BlockDeviceMappings[*].Ebs.{ID:SnapshotId}' \
		   --output text`
		   
		   echo  "\e[32;1m WARN:: Removing Expired AMI $expire_ami \e[0m"
		   delete_ami=`aws ec2 deregister-image --image-id "$expire_ami"`
		   echo  "INFO:: AMI $expire_ami removed. Status : $delete_ami"
		  
		   echo  "\e[32;1m WARN:: Removing Expired Snaphost $expire_snap \e[0m"
		   delete_snap=`aws ec2 delete-snapshot --snapshot-id "$expire_snap"`
		   echo  "INFO:: Snapshot $expire_snap removed. Status : $delete_snap"
		   
		fi
    done
fi

echo  "INFO:: Creating new ami with the instance-id  : "$instanceId

newAmi_id=`aws ec2 create-image \
 --no-reboot --instance-id "$instanceId" \
 --name "$imageName" --output text`

echo  "INFO:: New AMI Created, AMI Info  : "$newAmi_id

echo  "INFO:: Success !! $(date)\n"
