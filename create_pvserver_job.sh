#!/bin/bash
# modified from: 
# http://www.paraview.org/Wiki/ParaView:Server_Configuration
# and with ideas from:
# https://github.com/burlen/pvserver-configs

# paraview client on remote workstation launches an xterm which
# ssh reverse-tunnels into login node and executes this script.
# This script accepts args from ssh, starts ncat listening for 
# a connection from a MOM node and submits a job. 
#
# The job is created with a combination command line/job script file,
# so that the MOM node can supply some networking information to
# the compute node.
# 
# The end result is that the network traffic is ncat'd from compute node
# to mom node to login and back to the workstation.

#set -x

# Grab args passed over tunnel. The exported ones are used by the
# qsub script. The non-exported are used by the qsub command line.
echo "Args recieved from ParaView client/xterm/ssh: "
echo JOB_NAME:   $1 
echo EMAIL:      $2 
echo GROUP:      $3 
echo QUEUE:      $4 
echo NODES:      $5 
echo PPN:        $6 
echo WALLTIME:   $7 
echo PV_VERSION: $8 
echo PORT:       $9
echo CONNECT ID: ${10}
JOB_NAME=$1
EMAIL=$2
GROUP=$3
QUEUE=$4
NODES=$5
PPN=$6
WALLTIME=$7
PV_VERSION=$8
CLIENT_PORT=$9
CONNECT_ID=${10}

let NP=$NODES*$PPN

# Grab login node info and set up port listening.
LOGIN_HOST=`/bin/hostname`
let TMP=$((CLIENT_PORT+1))
LOGIN_PORT=$TMP

echo "Redirecting ports with ncat..."
NCAT=/sw/xe/paraview/thirdparty/ncat/6.47/bin/ncat
$NCAT -l $LOGIN_HOST $LOGIN_PORT --sh-exec="$NCAT localhost $CLIENT_PORT" &

# Create job
echo "Submitting aprun_pvserver.qsub with:"
echo "-N $JOB_NAME"
echo "-A $GROUP"
echo "-q $QUEUE"
echo "-l nodes=$NODES:ppn=$PPN:xe"
echo "-l walltime=$WALLTIME"
JOB_ID=`qsub -v EMAIL=$EMAIL,PV_VERSION=$PV_VERSION,CLIENT_PORT=$CLIENT_PORT,CONNECT_ID=$CONNECT_ID,LOGIN_HOST=$LOGIN_HOST,LOGIN_PORT=$LOGIN_PORT,NP=$NP -N $JOB_NAME -A $GROUP -q $QUEUE -l nodes=$NODES:ppn=$PPN:xe -l walltime=$WALLTIME /sw/xe/paraview/aprun_pvserver.qsub`
ERRNO=$?
if [ $ERRNO == 0 ]
then
  echo "Job submitted."
  while :
  do
    qstat | grep $JOB_NAME
    echo "Enter Q/q to call \"qdel $JOB_ID\" and exit."
    echo -n "$ "
    read -n 1 quit
    case $quit in 
      Q|q)
      echo 
      echo "qdel $JOB_ID"
      qdel $JOB_ID
      echo "Quitting..."
      break
      ;;
    esac
  done
else
  echo "ERROR $ERRNO: in job submission, job not submitted."
fi

echo "Exiting from $0."
exit 0
