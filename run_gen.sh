#!/bin/bash
########
### Assign Variables
########

function json_variable() {
  Param="$(cat $1  | jq $2 )"
  temp="${Param%\"}"
  jsonResult="${temp#\"}"
  echo $jsonResult
}

LVSLEEP=4
LVSENDTXT="No" 
LVMODE="$1"
echo "LVMODE  $LVMODE "

SDBUsername=$(json_variable "parameters$LVMODE.json" ".DBInstance.SourceDB.MasterUsername")
SDBUserPassword=$(json_variable "parameters$LVMODE.json" ".DBInstance.SourceDB.MasterUserPassword")
SDBName=$(json_variable "parameters$LVMODE.json" ".DBInstance.SourceDB.DBName")
SDBEngine=$(json_variable "parameters$LVMODE.json" ".DBInstance.SourceDB.Engine")
SDBServer=$(json_variable "parameters$LVMODE.json" ".DBInstance.SourceDB.Server")
SDBPort=$(json_variable "parameters$LVMODE.json" ".DBInstance.SourceDB.Port")

echo $SDBUsername 
echo $SDBUserPassword
echo $SDBName
echo $LVMODE
echo $SDBServer
echo $SDBPort


echo " {
   \"Subject\": {
       \"Data\": \"Database Migrated To The Cloud\",
       \"Charset\": \"UTF-8\"
   },
   \"Body\": {
       \"Html\": {
           \"Data\": \"Your Insync Cloud database is being generated for the following database <br> Database Name : $SDBName                                                  <br> Database Engine : $SDBEngine                                                  <br> username : $SDBUsername                                                  <br> Server : $SDBServer                                                   <br> Port : $SDBPort                                                   <br> Your connection details will follow shortly. <br> InSync Cloud: <a class=\\\"ulink\\\" href=\\\"http://www.insync.cloud\\\" target=\\\"_blank\\\">InSync Cloud </a>.\",
           \"Charset\": \"UTF-8\"
       }
   }
} " >   ./startemail$LVMODE.txt 

aws ses send-email --from "adam.gladstone@insync.cloud"  \
   --destination file://email.json \
   --source-arn arn:aws:ses:eu-west-1:383641234864:identity/adam.gladstone@insync.cloud \
  --subject "Your InSynCloud Database is Generating" \
  --message  file://startemail$LVMODE.txt \
   --profile inSyncCloudIrelandAPI  > send-message$LVMODE.txt

TDBEC2ID=$(json_variable "parameters$LVMODE.json" ".DBInstance.TargetDB.EC2ID")
TDBUsername=$(json_variable "parameters$LVMODE.json" ".DBInstance.TargetDB.MasterUsername")
TDBUserPassword=$(json_variable "parameters$LVMODE.json" ".DBInstance.TargetDB.MasterUserPassword")
TDBName=$(json_variable "parameters$LVMODE.json" ".DBInstance.TargetDB.DBName")
TDBInstanceClass=$(json_variable "parameters$LVMODE.json" ".DBInstance.TargetDB.DBInstanceClass")
TDBAllocatedStorage=$(json_variable "parameters$LVMODE.json" ".DBInstance.TargetDB.AllocatedStorage")
TDBAZ=$(json_variable "parameters$LVMODE.json" ".DBInstance.TargetDB.SubnetAvailabilityZone")
TDBSGID=$(json_variable "parameters$LVMODE.json" ".DBInstance.TargetDB.SecurityGroupID")
TDBEngine=$(json_variable "parameters$LVMODE.json" ".DBInstance.TargetDB.Engine")
TDBBackupRetentionPeriod=$(json_variable "parameters$LVMODE.json" ".DBInstance.TargetDB.BackupRetentionPeriod")

RIARN="null"
TDBServer="null"
RTARN="null"
TEPSTATUS="null"

echo TDBEC2ID $TDBEC2ID 
echo TDBName $TDBName
echo TDBUsername $TDBUsername
echo TDBUserPassword $TDBUserPassword
echo TDBInstanceClass $TDBInstanceClass
echo TDBAllocatedStorage  $TDBAllocatedStorage 
echo TDBBackupRetentionPeriod $TDBBackupRetentionPeriod
echo TDBEngine $TDBEngine
echo TDBSGID $TDBSGID
echo TDBAZ $TDBAZ
#
# create target Database
#
#
aws ec2 start-instances \
 --instance-ids "$TDBEC2ID" \
 --profile inSyncCloudAPI  > create-db-instance$LVMODE.txt 

aws rds create-db-instance \
 --db-name "$TDBName" \
 --db-instance-identifier "$TDBName" \
 --allocated-storage "$TDBAllocatedStorage"  \
 --availability-zone "$TDBAZ"  \
 --db-instance-class "$TDBInstanceClass" --engine "$TDBEngine" \
 --master-username "$TDBUsername" --master-user-password "$TDBUserPassword" \
 --backup-retention-period "$TDBBackupRetentionPeriod" \
 --vpc-security-group-ids "$TDBSGID" \
 --profile inSyncCloudAPI  > create-db-instance$LVMODE.txt 

TDBARN=$(json_variable "create-db-instance$LVMODE.txt" ".DBInstance.DBInstanceArn")
echo "TDBARN $TDBARN"
echo "TDBServer $TDBServer" 

counter=0

while [ "$TDBServer" == "null" ] && [ "$counter" -le 100 ]
do
  sleep "$LVSLEEP"
  echo "Loop TDBARN $TDBARN"
  TDBARN=$(json_variable "create-db-instance$LVMODE.txt" ".DBInstance.DBInstanceArn")
  aws rds describe-db-instances --db-instance-identifier "$TDBARN" \
 --profile inSyncCloudAPI  > target-db-instance$LVMODE.txt 
  TDBServer=$(json_variable "target-db-instance$LVMODE.txt" ".DBInstances[0].Endpoint.Address")
  TDBPort=$(json_variable "target-db-instance$LVMODE.txt" ".DBInstances[0].Endpoint.Port")
  counter=$(expr $counter + 1)
  echo "counter $counter"
done

echo "Database server $TDBServer" 

if [ "$TDBServer" != "null" ]  
then
 echo "Database created $TDBName" 
 echo "Database created $TDBName" > message$LVMODE.txt

 if [ "$LVSENDTXT" == "Yes" ]  
 then
#
   aws sns publish  --phone-number  +61419152098 \
   --subject "InSynCloud" \
   --message  file://message$LVMODE.txt \
   --profile inSyncCloudAPI  > send-message$LVMODE.txt
 fi
fi

#
#echo "TDBServer" $TDBServer
#echo "TDBPort" $TDBPort
#

#
# create replication instance
#
#
RIID=$(json_variable "parameters$LVMODE.json" ".DBInstance.ReplicationInstance.InstanceIdentifier")
RIAllocatedStorage=$(json_variable "parameters$LVMODE.json" ".DBInstance.ReplicationInstance.AllocatedStorage")
RIClass=$(json_variable "parameters$LVMODE.json" ".DBInstance.ReplicationInstance.RIInstanceClass")

echo "RIID" $RIID
echo "RIAllocatedStorage" $RIAllocatedStorage
echo "RIClass" $RIClass

aws dms create-replication-instance --replication-instance-identifier "$RIID" \
--allocated-storage "$RIAllocatedStorage" \
--replication-instance-class "$RIClass" \
--publicly-accessible \
--profile inSyncCloudAPI > create-RI-instance$LVMODE.txt  


aws dms describe-replication-instances \
--filters Name="replication-instance-id",Values="$RIID" \
--profile inSyncCloudAPI > describe-RI-instance$LVMODE.txt  

RIARN=$(json_variable "describe-RI-instance$LVMODE.txt" ".ReplicationInstances[0].ReplicationInstanceArn")
RISTATUS=$(json_variable "describe-RI-instance$LVMODE.txt" ".ReplicationInstances[0].ReplicationInstanceStatus")

counter=0
echo "RIARN $RIARN"
echo "RISTATUS  $RISTATUS"


while [ "$RISTATUS" == "creating" ] && [ "$counter" -le 100 ]
do
  echo "Loop RIARN $RIARN"
  sleep "$LVSLEEP"

  aws dms describe-replication-instances \
  --filters Name="replication-instance-id",Values="$RIID" \
  --profile inSyncCloudAPI > describe-RI-instance$LVMODE.txt  

  RIARN=$(json_variable "describe-RI-instance$LVMODE.txt" ".ReplicationInstances[0].ReplicationInstanceArn")
  RISTATUS=$(json_variable "describe-RI-instance$LVMODE.txt" ".ReplicationInstances[0].ReplicationInstanceStatus")
  echo "RISTATUS  $RISTATUS"
  counter=$(expr $counter + 1)
  echo "counter $counter"
done

echo "RISTATUS  $RISTATUS"

if [ "RISTATUS" == "available" ]  
then
 echo "Replication Instance created [ $RIID ] " 
 echo "Replication Instance created [ $RIID ] " > message"$RIID"$LVMODE.txt
 if [ "$LVSENDTXT" == "Yes" ]  
 then
   aws sns publish  --phone-number  +61419152098 \
   --subject "InSynCloud" \
   --message  file://message"$RIID"$LVMODE.txt \
   --profile inSyncCloudAPI  > send-message"$RIID"$LVMODE.txt  
 fi
fi


#
# create Target Endpoint
#

TEPID=$(json_variable "parameters$LVMODE.json" ".DBInstance.TargetEndPoint.TEPID")

echo "TEPID" $TEPID
echo "TDBEngine" $TDBEngine
echo "TDBName" $TDBName
echo "TDBUsername" $TDBUsername
echo "TDBUserPassword" $TDBUserPassword
echo "TDBServer" $TDBServer
echo "TDBPort" $TDBPort

echo "create-endpoint " $TEPID

aws dms create-endpoint --endpoint-identifier "$TEPID" \
  --endpoint-type target \
  --engine-name "$TDBEngine" \
  --database-name "$TDBName" \
  --username "$TDBUsername" \
  --password "$TDBUserPassword" \
  --server-name   "$TDBServer" \
  --port "$TDBPort" \
  --profile inSyncCloudAPI > create-Target-Endpoint$LVMODE.txt 

  aws dms describe-endpoints \
  --filters Name="endpoint-id",Values="$TEPID" \
   --profile inSyncCloudAPI > describe-Target-Endpoint$LVMODE.txt
TEPARN="null"
TEPARN=$(json_variable "describe-Target-Endpoint$LVMODE.txt" ".Endpoints[0].EndpointArn") 

counter=0

while [ "$TEPARN" == "null" ] && [ "$counter" -le 100 ]
do
  echo "Loop TEPARN $TEPARN "
  sleep "$LVSLEEP"
  aws dms describe-endpoints \
  --filters Name="endpoint-id",Values="$TEPID" \
   --profile inSyncCloudAPI > describe-Target-Endpoint$LVMODE.txt
  TEPARN=$(json_variable "describe-Target-Endpoint$LVMODE.txt" ".Endpoints[0].EndpointArn")
  counter=$(expr $counter + 1)
  echo "counter $counter"
done
echo "TEPARN" $TEPARN

if [ "TEPARN" != "null" ]  
then
 echo "Target End Point created [ $TEPID ] " 
 echo "Target End Point created [ $TEPID ] " > message"$TEPID"$LVMODE.txt
 if [ "$LVSENDTXT" == "Yes" ]  
 then
   aws sns publish  --phone-number  +61419152098 \
   --subject "InSynCloud" \
   --message  file://message"$TEPID"$LVMODE.txt \
   --profile inSyncCloudAPI  > send-message"$TEPID"$LVMODE.txt  
 fi
fi

  aws dms test-connection \
     --endpoint-arn "$TEPARN"  \
     --replication-instance-arn "$RIARN" \
   --profile inSyncCloudAPI > test-Target-Connections$LVMODE.txt
echo "Testing Target End Point Connection " 

counter=0

while [ "$TEPSTATUS" != "successful" ] && [ "$counter" -le 100 ]
do
  sleep "$LVSLEEP"
  echo "Loop TEPSTATUS $TEPSTATUS "
  echo "Target End Point ARN created [ $TEPARN ] " 
  echo "Replication ARN created [ $RIARN ] " 


  aws dms describe-connections \
   --filters Name="endpoint-arn",Values="$TEPARN"  \
             Name="replication-instance-arn",Values="$RIARN" \
   --profile inSyncCloudAPI > describe-Target-Connections$LVMODE.txt

   TEPSTATUS=$(json_variable "describe-Target-Connections$LVMODE.txt" ".Connections[0].Status") 

   echo "Target End Point Connection status [ $TEPSTATUS ] " 
  counter=$(expr $counter + 1)
  echo "counter $counter"
done


if [ "TEPSTATUS" == "successful" ]  
then
 echo "Target End Point Connected [ $TEPSTATUS] " 
 echo "Target End Point Connected [ $TEPSTATUS] " > messageconnection"$TEPID"$LVMODE.txt
 if [ "$LVSENDTXT" == "Yes" ]  
 then
   aws sns publish  --phone-number  +61419152098 \
   --subject "InSynCloud" \
   --message  file://messageconnection"$TEPID"$LVMODE.txt \
   --profile inSyncCloudAPI  > send-messageconnection"$TEPID"$LVMODE.txt  
 fi
fi


#
#
#
# create Source Endpoint
#


SEPID=$(json_variable "parameters$LVMODE.json" ".DBInstance.SourceEndPoint.SEPID")
echo $SEPID

aws dms create-endpoint --endpoint-identifier "$SEPID" \
  --endpoint-type source \
  --engine-name "$SDBEngine" \
  --database-name "$SDBName" \
  --username "$SDBUsername" \
  --password "$SDBUserPassword" \
  --server-name   "$SDBServer" \
  --port "$SDBPort" \
  --profile inSyncCloudAPI > create-Source-Endpoint$LVMODE.txt 

  aws dms describe-endpoints \
  --filters Name="endpoint-id",Values="$SEPID" \
   --profile inSyncCloudAPI > describe-Source-Endpoint$LVMODE.txt

SEPARN=$(json_variable "describe-Source-Endpoint$LVMODE.txt" ".Endpoints[0].EndpointArn")

counter=0

while [ "$SEPARN" == "null" ] && [ "$counter" -le 100 ]
do
  echo "Loop SEPARN $SEPARN "
  sleep "$LVSLEEP"
  aws dms describe-endpoints \
  --filters Name="endpoint-id",Values="$SEPID" \
   --profile inSyncCloudAPI > describe-Source-Endpoint$LVMODE.txt
  SEPARN=$(json_variable "describe-Source-Endpoint$LVMODE.txt" ".Endpoints[0].EndpointArn")
  counter=$(expr $counter + 1)
  echo "counter $counter"
done

echo "SEPARN" $SEPARN

if [ "SEPARN" != "null" ]  
then
 echo "Source End Point created [ $SEPID ] " 
 echo "Source End Point created [ $SEPID ] " > message"$SEPID"$LVMODE.txt
 if [ "$LVSENDTXT" == "Yes" ]  
 then
   aws sns publish  --phone-number  +61419152098 \
   --subject "InSynCloud" \
   --message  file://message"$SEPID"$LVMODE.txt \
   --profile inSyncCloudAPI  > send-message"$SEPID"$LVMODE.txt  
 fi
fi

  aws dms test-connection \
     --endpoint-arn "$SEPARN"  \
     --replication-instance-arn "$RIARN" \
   --profile inSyncCloudAPI > test-Target-Connections$LVMODE.txt

echo "Testing Source End Point Connection " 

counter=0

while [ "$SEPSTATUS" != "successful" ] && [ "$counter" -le 100 ]
do
  echo "Loop SEPSTATUS $SEPSTATUS "
  sleep "$LVSLEEP"

  aws dms describe-connections \
   --filters Name="endpoint-arn",Values="$SEPARN"  \
             Name="replication-instance-arn",Values="$RIARN" \
   --profile inSyncCloudAPI > describe-Target-Connections$LVMODE.txt

   SEPSTATUS=$(json_variable "describe-Target-Connections$LVMODE.txt" ".Connections[0].Status") 

   echo "Source End Point Connection status [ $SEPSTATUS ] " 
  counter=$(expr $counter + 1)
  echo "counter $counter"
done

echo "Source End Point Connection status [ $SEPSTATUS ] " 

if [ "SEPSTATUS" == "successful" ]  
then
 echo "Source End Point Connected [ $SEPSTATUS] " 
 echo "Source End Point Connected [ $SEPSTATUS] " > messageconnection$SEPID$LVMODE.txt
 if [ "$LVSENDTXT" == "Yes" ]  
 then
   aws sns publish  --phone-number  +61419152098 \
   --subject "InSynCloud" \
   --message  file://messageconnection$SEPID$LVMODE.txt \
   --profile inSyncCloudAPI  > send-messageconnection$SEPID$LVMODE.txt  
 fi
fi

RTID=$(json_variable "parameters$LVMODE.json" ".DBInstance.ReplicationTask.Name")
RepTaskMigrationType=$(json_variable "parameters$LVMODE.json" ".DBInstance.ReplicationTask.MigrationType")
RepTableMapping=$(json_variable "parameters$LVMODE.json" ".DBInstance.ReplicationTask.TableMapping")

echo "RTID $RTID"
echo "TEPARN $TEPARN" 
echo "SEPARN $SEPARN" 
echo "RIARN $RIARN" 
echo "RepTaskMigrationType $RepTaskMigrationType" 
echo "RepTableMapping $RepTableMapping" 

aws dms create-replication-task --replication-task-identifier "$RTID" \
--target-endpoint-arn "$TEPARN" \
--source-endpoint-arn "$SEPARN" \
--replication-instance-arn "$RIARN" \
--migration-type "$RepTaskMigrationType" \
--table-mappings "$RepTableMapping" \
--profile inSyncCloudAPI > create-replication-task$LVMODE.txt 

aws dms describe-replication-tasks \
--filters Name="replication-instance-arn",Values="$RIARN" \
         Name="endpoint-arn",Values="$TEPARN" \
--profile inSyncCloudAPI > describe-replication-tasks$LVMODE.txt

#replication-instance-arn
#--filters Name="replication-task-id",Values="$RTID" \


RTARN=$(json_variable "describe-replication-tasks$LVMODE.txt" ".ReplicationTasks[0].ReplicationTaskArn")
RTSTATUS=$(json_variable "describe-replication-tasks$LVMODE.txt" ".ReplicationTasks[0].Status")

if [ -z "$RTARN" ]
then
 RTARN="null"
fi

counter=0

while [ "$RTARN" == "null" ] && [ "$counter" -le 100 ]
do
  echo "Loop RTARN $RTARN "
  echo "Loop RTID $RTID "
  sleep "$LVSLEEP"
  aws dms describe-replication-tasks \
    --filters Name="replication-instance-arn",Values="$RIARN" \
              Name="endpoint-arn",Values="$TEPARN" \
   --profile inSyncCloudAPI > describe-replication-tasks$LVMODE.txt

  RTARN=$(json_variable "describe-replication-tasks$LVMODE.txt" ".ReplicationTasks[0].ReplicationTaskArn")
  RTSTATUS=$(json_variable "describe-replication-tasks$LVMODE.txt" ".ReplicationTasks[0].Status")

  if [ -z "$RTARN" ]
  then
   RTARN="null"
  fi

  counter=$(expr $counter + 1)
  echo "counter $counter"
done

echo "RTARN" $RTARN

if [ "RTARN" != "null" ]  
then
 echo "Replication Task created [ $RTID ] " 
 echo "Replication Task created [ $RTID ] "  > message"$RTID"$LVMODE.txt
 if [ "$LVSENDTXT" == "Yes" ]  
 then
   aws sns publish  --phone-number  +61419152098 \
   --subject "InSynCloud" \
   --message  file://message"$RTID"$LVMODE.txt \
   --profile inSyncCloudAPI  > send-message"$RTID"$LVMODE.txt  
 fi
fi

counter=0

while true 
do

  if [ "$RTSTATUS" = "ready" ] 
  then 
   echo "Loop RTARN $RTARN ready"
   break
  elif [ "$RTSTATUS" = "running" ]
   then
   echo "Loop RTARN $RTARN running"
   break
  elif [ "$RTSTATUS" = "stopped" ]
   then
   echo "Loop RTARN $RTARN stopped"
   break
  elif [ "$counter" -eq 100 ]
   then
   break
  fi

  echo "Loop RTARN $RTARN $RTSTATUS $RTID "
  sleep "$LVSLEEP"
  aws dms describe-replication-tasks \
    --filters Name="replication-instance-arn",Values="$RIARN" \
              Name="endpoint-arn",Values="$TEPARN" \
   --profile inSyncCloudAPI > describe-replication-tasks$LVMODE.txt
  RTSTATUS=$(json_variable "describe-replication-tasks$LVMODE.txt" ".ReplicationTasks[0].Status")
  counter=$(expr $counter + 1)
  echo "counter $counter"
done

if [ "RTSTATUS" == "ready" ]  
then
 echo "Replication Task ready [ $RTSTATUS ] " 
 echo "Replication Task ready [ $RTSTATUS ] "  > message"$RTID"$LVMODE.txt
 if [ "$LVSENDTXT" == "Yes" ]  
 then
   aws sns publish  --phone-number  +61419152098 \
   --subject "InSynCloud" \
   --message  file://message"$RTID"$LVMODE.txt \
   --profile inSyncCloudAPI  > send-message"$RTID"$LVMODE.txt  
 fi
fi

#
# Start Replication Task
#

if [ "$RTSTATUS" = "stopped" ] 
then
  echo "Replication Task reload-target [ $RTSTATUS ] " 
  aws dms start-replication-task --replication-task-arn "$RTARN" \
  --start-replication-task-type reload-target \
  --profile inSyncCloudAPI > start-replication-tasks$LVMODE.txt
elif [ "$RTSTATUS" = "running" ] 
then
  echo "Replication Task already running [ $RTSTATUS ] " 
elif [ "$RTSTATUS" = "ready" ] 
then
  echo "Replication Task start-replicatio [ $RTSTATUS ] " 
  aws dms start-replication-task --replication-task-arn "$RTARN" \
  --start-replication-task-type start-replication \
  --profile inSyncCloudAPI > start-replication-tasks$LVMODE.txt
else
  echo "Replication Task status [ $RTSTATUS ] " 
fi

RTSTATUS="null"
counter=0

while [ "$RTSTATUS" != "stopped" ] && [ "$counter" -le 500 ]
do
  sleep "$LVSLEEP"
  aws dms describe-replication-tasks \
    --filters Name="replication-instance-arn",Values="$RIARN" \
              Name="endpoint-arn",Values="$TEPARN" \
   --profile inSyncCloudAPI > describe-replication-tasks$LVMODE.txt

  RTSTATUS=$(json_variable "describe-replication-tasks$LVMODE.txt" ".ReplicationTasks[0].Status")
  RTTablesLoading=$(json_variable "describe-replication-tasks$LVMODE.txt" ".ReplicationTasks[0].ReplicationTaskStats.TablesLoading")
  RTFullLoadProgressPercent=$(json_variable "describe-replication-tasks$LVMODE.txt" ".ReplicationTasks[0].ReplicationTaskStats.FullLoadProgressPercent")
  RTTablesQueued=$(json_variable "describe-replication-tasks$LVMODE.txt" ".ReplicationTasks[0].ReplicationTaskStats.TablesQueued")
  RTTablesLoaded=$(json_variable "describe-replication-tasks$LVMODE.txt" ".ReplicationTasks[0].ReplicationTaskStats.TablesLoaded")

  echo "counter [ $counter ] RTARN  [ $RTARN ] Status [ $RTSTATUS  ] Tables Loading [ $RTTablesLoading ] Progress Percent [ $RTFullLoadProgressPercent ] Tables Queued [ $RTTablesQueued ] Tables Loaded [ $RTTablesLoaded ]"

  counter=$(expr $counter + 1)
  echo 
done

if [ "RTSTATUS" == "Load completed" ]  
then
 echo "Replication Task Completed [ $RTSTATUS ] " 
 echo "Replication Task Completed [ $RTSTATUS ] "  > message"$RTID"$LVMODE.txt
 if [ "$LVSENDTXT" == "Yes" ]  
 then
   aws sns publish  --phone-number  +61419152098 \
   --subject "InSynCloud" \
   --message  file://message"$RTID"$LVMODE.txt \
   --profile inSyncCloudAPI  > send-message"$RTID"$LVMODE.txt  
 fi
fi


echo " {
   \"Subject\": {
       \"Data\": \"Database Migrated To The Cloud\",
       \"Charset\": \"UTF-8\"
   },
   \"Body\": {
       \"Html\": {
           \"Data\": \" Congratulations your database database has been archived into the cloud. Your connection details are as follows : $TDBUsername <br>                    Database Name : $TDBName <br>                  Database Engine : $TDBEngine <br>                         username : $TDBUsername <br>                         password : $TDBUserPassword <br>                    InstanceClass : $TDBInstanceClass <br>                 AllocatedStorage : $TDBAllocatedStorage <br>            BackupRetentionPeriod : $TDBBackupRetentionPeriod <br>                           Server : $TDBServer <br>                             counter [ $counter ] RTARN  [ $RTARN ] Status [ $RTSTATUS  ] Tables Loading [ $RTTablesLoading ] Progress Percent [ $RTFullLoadProgressPercent ] Tables Queued [ $RTTablesQueued ] Tables Loaded [ $RTTablesLoaded ] Port : $TDBPort <br> InSync Cloud: <a class=\\\"ulink\\\" href=\\\"http://www.insync.cloud\\\" target=\\\"_blank\\\">InSync Cloud </a>.\",
           \"Charset\": \"UTF-8\"
       }
   }
} " >   ./endemail$LVMODE.txt 


aws ses send-email --from "adam.gladstone@insync.cloud"  \
   --destination file://email.json \
   --source-arn arn:aws:ses:eu-west-1:383641234864:identity/adam.gladstone@insync.cloud \
  --subject "Your InSynCloud Database is Ready" \
  --message  file://endemail$LVMODE.txt \
   --profile inSyncCloudIrelandAPI  > send-message$$LVMODE.txt

