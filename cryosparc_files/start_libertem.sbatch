#!/bin/bash
#SBATCH --job-name=start_libertem
#SBATCH --partition=cryosparc_master
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --gres=gpu:3g.10gb:2
#SBATCH --mem=64GB
# Set the file for output (stdout)
#SBATCH --output=MyJob-%j.out

#Determine the next free port for LiberTEM
source /mnt/userdata/portchecker/bin/activate
export NEW_BASE_PORT=`port-checker --config /mnt/userdata/cryosparc_files/portchecker-config.yml  --seed=$SLURM_JOB_ID`
echo "LiberTEM can be started on port: $NEW_BASE_PORT"

#Updating the port number in ~/libertem.txt
cat > ~/libertem.txt <<EOF
{
  "port": "${NEW_BASE_PORT}"
}
EOF

srun /mnt/userdata/liberterm-0.10.0/bin/libertem-server -p $NEW_BASE_PORT -d $HOME
