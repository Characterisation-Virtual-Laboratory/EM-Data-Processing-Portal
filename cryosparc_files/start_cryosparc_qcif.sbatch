#!/bin/bash
#SBATCH --job-name=start-cryosparc
#SBATCH --account=cryosparc
#SBATCH --partition=cryosparc_master
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --mem=64GB
# Set the file for output (stdout)
#SBATCH --output=/mnt/userdata/%u/MyJob-%j.out
#SBATCH --time=14-00:00:00
#SBATCH --signal=B:USR1@120

stop_cryosparc() {
  echo "Stopping CryoSPARC $(date)" >> /mnt/userdata/$USER/Cryosparc_Stopped.out
  /mnt/userdata/$USER/cryosparc/cryosparc_master/bin/cryosparcm stop
}

trap 'stop_cryosparc' USR1

srun hostname

#Determine the next free port for CryoSPARC
source /mnt/userdata/portchecker/bin/activate
export NEW_BASE_PORT=`port-checker --config /mnt/userdata/cryosparc_files/portchecker-config.yml  --site=qcif`
echo "CryoSPARC can be started on port: $NEW_BASE_PORT"

/mnt/userdata/cryosparc_files/start_cryosparc.sh

#Obtain the PID of the cryosparc_database and wait.
PID=`ps -u $USER -o pid,command | grep cryosparc_database | head -n 1 | awk '{print $1}'`
echo "PID: $PID"

#Unable to use 'wait' as this is not a child process of the shell
#wait $PID
while [ -e /proc/$PID ]; do sleep 30s ; done
