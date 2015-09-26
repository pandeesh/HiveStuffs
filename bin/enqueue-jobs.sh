#!/bin/bash
###############################################################################################################################################################################################
#
#Usage: there are 2 mandatory  args and an optional 3rd arg to this script. first arg is list of hqls in comma separated list:hql1,hql2,hql2..
#2nd arg is the cluster in which the scripts need to be run sequentially
#By default, the script assumes the private key files exist under /home/$USER/emr/. if the optional 3rd arg is present, it will look for *.pem,*.json files under that directory
#Just nake sure your elastic-mapreduce installed path is in your PATH
###############################################################################################################################################################################################

shopt -s expand_aliases

fileName=$1_$RANDOM.hql

#region can be changed here based on your configuration 

region=us-west-2

#JobFlowID ofthe cluster in which these HQLs need to be enqueued

jobFlow=$2 

#hive_version can be configured here

hive_version=0.8.1.6

if [ $# -ne 2 -a $# -ne 3 ]
then
echo "Usage: there are 2 mandatory args and  an optional 3rd arg to this script. first arg is list of hqls and the second arg is the jobflow id and 3rd optional arg is the path to private key files"
exit 1;
fi

if  [ $# -eq 2 ]
then
alias emr="elastic-mapreduce --key-pair-file /home/$USER/emr/privateKey.pem  --region $region --credentials /home/$USER/emr/credentials.json"
else
alias emr="elastic-mapreduce --key-pair-file ${3}privateKey.pem --region $region --credentials ${3}credentials.json"
fi


#The below for loop will enqueue all teh hqls into the cluster
for i in `echo $1|sed -e 's/,/ /g'`
do
fileName=$(basename $i)
emr  --put $i --to /tmp/$fileName -j $jobFlow
emr --hive-script /tmp/$fileName --hive-versions $hive_version -j $jobFlow
done

#This part loops and waits for the job to finish. It will alert you by giving you a popup
#if you are on your Redhat system. We may or may not want to keep this loop
sleep 10
keepGoing=true
while [ $keepGoing = "true" ]
do
   emr --describe  $jobFlow | grep -A8 ExecutionStatusDetail | grep RUNNING > /dev/null
   if [[ $? -eq 0 ]]; then
       echo "Still Running"
       sleep 10
   else
       keepGoing=false
       #zenity --info --text='FINISHED'
   fi
done
