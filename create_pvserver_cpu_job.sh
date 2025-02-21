#!/bin/bash
# modified from: 
# http://www.paraview.org/Wiki/ParaView:Server_Configuration
# and with ideas from:
# https://github.com/burlen/pvserver-configs

# paraview client on remote workstation launches an xterm which
# ssh reverse-tunnels into login node and executes this script.
# This script accepts args from ssh, submits a job, then once
# the job is active, starts a new reverse ssh tunnel to the
# lead compute node.

#set -x

# Grab args passed over tunnel. The exported ones are used by the
# qsub script. The non-exported are used by the qsub command line.
echo "Args recieved from ParaView client/xterm/ssh: "
echo --job-name:        $1 
echo --mail-user:       $2 
echo --account:         $3 
echo --partition:       $4 
echo --nodes:           $5 
echo --ntasks-per-node: $6 
echo --time:            $7 
echo PORT:              $8
echo CONNECT ID:        $9
JOB_NAME=$1
MAIL_USER=$2
ACCOUNT=$3
PARTITION=$4
NODES=$5
NTASKS_PER_NODE=$6
TIME=$7
CLIENT_PORT=$8
CONNECT_ID=$9

if [[ "$PARTITION" == "cpu" ]]; then
        VERSION=5.11.2.osmesa.x86_64
else
        VERSION=5.11.2.egl.cuda
fi

let NP=$(( NODES * NTASKS_PER_NODE ))

# Grab login node hostname
LOGIN_HOST=`/bin/hostname`
let TMP=$((CLIENT_PORT+1))
LOGIN_PORT=$TMP

now=`date +%Y-%m-%d-%H.%M.%S`
PVSERVER_JOB=$HOME/pvserver-job-$now.sbatch

# Create job file to submit
(
cat <<EOF
#!/bin/bash
#SBATCH --account=$ACCOUNT
#SBATCH --mail-user=$MAIL_USER
#SBATCH --partition=$PARTITION
#SBATCH --nodes=$NODES
#SBATCH --ntasks-per-node=$NTASKS_PER_NODE
#SBATCH --time=$TIME

hostname
module load paraview/$VERSION
which mpiexec

mpiexec -n $NP pvserver --reverse-connection --server-port=$LOGIN_PORT --connect-id=$CONNECT_ID --force-offscreen-rendering
EOF
) > $PVSERVER_JOB


RUNNING=false

if [ -f "$PVSERVER_JOB" ]; then
        JOB_ID=$(sbatch $PVSERVER_JOB | cut -d' ' -f4)
        ERRNO=$?
        if [[ $ERRNO == 0 ]]; then
                echo "Job submitted."
                # could I change this to while job in queue?
                while :
                do
                        if [[ $RUNNING == "false" ]]; then
                                echo "waiting for job to start..."
                        fi
                        RUNSTATUS=$(squeue -j $JOB_ID --noheader --format="%t")
                        if [[ "$RUNSTATUS" == "R" && $RUNNING == "false" ]]; then
                                echo "sleeping 20 ..."
                                sleep 20
                                # this doesn't resolve multiple nodes correctly
                                COMPUTENODE=$(squeue -j $JOB_ID --noheader --format="%N")
                                ssh -t -N -R $LOGIN_PORT:localhost:$CLIENT_PORT $COMPUTENODE &
                                RUNNING=true
                        fi
                        sleep 10
                        # need to capture this output somehow and switch from running
                        squeue -j $JOB_ID
                done
        else
                echo "ERROR $ERRNO: in job submission, job not submitted."
        fi
else
        echo "problem creating job file: \"$PVSERVER_JOB\""
fi


echo "Exiting from $0."
exit 0
