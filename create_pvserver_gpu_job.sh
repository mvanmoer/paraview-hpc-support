#!/bin/bash

# ParaView client on remote workstation uses delta-cpu.pvsc to configure a
# client-server reverse connection. ParaView then:
# 1. searches for installed terminal and ssh applications
# 2. connects over ssh and executes this script

# This script:
# 1. submits a SLURM job based on the configuration variables received over ssh
# 2. checks squeue every 10 seconds for the job status.
# 3. once running it makes a reverse ssh tunnel to the compute node

# The SLURM job is created as a HEREDOC which loads the correct paraview
# module and launches pvserver with mpiexec.

# uncomment next line for debugging.
#set -x

echo "Args recieved from ParaView client: "
echo --job-name:        $1
echo --account:         $2
echo --partition:       $3
echo --nodes:           $4
echo --cpus-per-task:   $5
echo --gpus-per-node:   $6
echo --time:            $7
echo PORT:              $8
echo CONNECT ID:        $9
JOB_NAME=$1
ACCOUNT=$2
PARTITION=$3
NODES=$4
CPUS_PER_TASK=$5
GPUS_PER_NODE=$6
TIME=$7
CLIENT_PORT=$8
CONNECT_ID=$9

VERSION=5.11.2.egl.cuda

# Grab login node hostname
LOGIN_HOST=`/bin/hostname`
echo "connected to: $LOGIN_HOST"
LOGIN_PORT=$((CLIENT_PORT+1))

now=`date +%Y-%m-%d-%H.%M.%S`
PVSERVER_JOB=$HOME/$JOB_NAME-$now.sbatch

# Create job file to submit
(
cat <<EOF
#!/bin/bash
#SBATCH --account=$ACCOUNT
#SBATCH --partition=$PARTITION
#SBATCH --nodes=$NODES
#SBATCH --cpus-per-task=$CPUS_PER_TASK
#SBATCH --gpus-per-node=$GPUS_PER_NODE
#SBATCH --time=$TIME

hostname
module load paraview/$VERSION
which mpiexec

mpiexec -n $NODES pvserver --reverse-connection --server-port=$LOGIN_PORT --connect-id=$CONNECT_ID --force-offscreen-rendering
EOF
) > $PVSERVER_JOB


RUNNING=false

if [ -f "$PVSERVER_JOB" ]; then
    JOB_ID=$(sbatch $PVSERVER_JOB | cut -d' ' -f4)
    ERRNO=$?
    if [[ $ERRNO == 0 ]]; then
        echo "Job submitted, waiting to start..."
        squeue -j $JOB_ID

        while :
        do
            RUNSTATUS=$(squeue -j $JOB_ID --noheader --format="%t")

            if [[ $RUNSTATUS == "R" && $RUNNING == "false" ]]; then
                echo "job started, waiting for pvserver to start ..."
                # sleep is to make sure pvserver has started before trying to connect
                sleep 20
                # single node jobs look like gpua###
                # multi-node jobs look like gpua[###,...,###] 
                COMPUTENODE=$(squeue -j $JOB_ID --noheader --format="%N" | tr -d '[' | cut -c1-7)
                ssh -t -N -R $LOGIN_PORT:localhost:$CLIENT_PORT $COMPUTENODE &
                RUNNING=true
            fi
            sleep 5
            if [[ ! $RUNSTATUS ]]; then
                echo "job no longer running"
                break
            fi
        done
    else
        echo "ERROR $ERRNO: in job submission, job not submitted."
    fi
else
    echo "problem creating job file: \"$PVSERVER_JOB\""
fi

echo "Exiting from $0."
exit 0
