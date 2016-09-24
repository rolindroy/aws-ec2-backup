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
    IFS=' ' read -r -a imageArray <<< "$desc"
	
    for img in $desc
    do
		imagedate=`echo $img | aws -F'_' '{ print $3 }'`
		echo -e $imagedate "\n"
    done
fi

    #echo  "WARN:: Delete the expired AMI, AMI Ids	  :" $desc
    #echo  "WARN:: Delete the expired AMI, AMI Ids  :" $desc
  #  out=`aws ec2 deregister-image --image-id "$desc"`
    #echo  "INFO:: Ami $desc delete status  : "$out
    
   # snapId=`aws ec2 describe-images --owner self \
    #    --filter Name=name,Values="$imageName" \
     #   --query 'Images[*].BlockDeviceMappings[*].Ebs.{ID:SnapshotId}' \
      #  --output text`
        
  #  echo  "WARN:: Delete Snapshot, Snapshot Id  :" $snapId
 #   snapOut=`aws ec2 delete-snapshot --snapshot-id "$snapId"`
 #   echo  "INFO:: Snapshot $snapId delete status  : "$out
 

# echo  "INFO:: Creating new ami with the instance-id  : "$instanceId

# newAmi_id=`aws ec2 create-image \
 # --no-reboot --instance-id "$instanceId" \
 # --name "$imageName" --output text`

# echo  "INFO:: New AMI Created, AMI Info  : "$newAmi_id

# echo  "INFO:: Success !! $(date)\n"
