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
echo --time:            $6
echo PORT:              $7
echo CONNECT ID:        $8
JOB_NAME=$1
ACCOUNT=$2
PARTITION=$3
NODES=$4
CPUS_PER_TASK=$5
TIME=$6
CLIENT_PORT=$7
CONNECT_ID=$8

VERSION=5.11.2.osmesa.x86_64

# Grab login node hostname
LOGIN_HOST=`/bin/hostname`
LOGIN_PORT=$((CLIENT_PORT+1))

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
