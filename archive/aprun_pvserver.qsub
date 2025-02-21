#!/bin/bash
#PBS -S /bin/bash
#PBS -j eo
#PBS -V
#PBS -M $EMAIL
#PBS -m abe

#set -x

MOM_HOST=`/bin/hostname`
let MOM_PORT=$((LOGIN_PORT+1))

NCAT=/sw/xe/paraview/thirdparty/ncat/6.47/bin/ncat

$NCAT -l $MOM_HOST $MOM_PORT --sh-exec="$NCAT $LOGIN_HOST $LOGIN_PORT" &

. /opt/modules/default/init/bash
module load paraview/$PV_VERSION

if [ $PV_VERSION = ".5.6.0-interactive" ] || [ $PV_VERSION = "5.6.0" ]; then
    aprun -n $NP pvserver --reverse-connection --force-offscreen-rendering --server-port=$MOM_PORT --client-host=$MOM_HOST --connect-id=$CONNECT_ID
else
    aprun -n $NP pvserver --reverse-connection --use-offscreen-rendering --server-port=$MOM_PORT --client-host=$MOM_HOST --connect-id=$CONNECT_ID
fi
