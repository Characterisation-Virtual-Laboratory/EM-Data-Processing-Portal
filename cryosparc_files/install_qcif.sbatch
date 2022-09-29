#!/bin/bash
#SBATCH --job-name=install-cryosparc
#SBATCH --account=cryosparc
#SBATCH --partition=cryosparc_master
#SBATCH --ntasks=4
#SBATCH --cpus-per-task=1
#SBATCH --gres=gpu:1
#SBATCH --mem=64GB
# Set the file for output (stdout)
#SBATCH --output=/mnt/userdata/%u/MyJob-%j.out

srun hostname

#Determine the next free port for CryoSPARC
source /mnt/userdata/portchecker/bin/activate
export CRYOSPARC_HOSTNAME_PORT=`port-checker --config /mnt/userdata/cryosparc_files/portchecker-config.yml  --site=qcif`
echo "CryoSPARC can be started on port: $CRYOSPARC_HOSTNAME_PORT"
USER_EMAIL=$( cd /mnt/userdata/provisioning/src/gerp_provisioning ; python3 -m get_email --config ../../config/config.yml --allocations ../../config/allocations.yml --username $USER)

srun /mnt/userdata/cryosparc_files/install_cryosparc.sh "$LICENSE_ID" "$CRYOSPARC_HOSTNAME_PORT" "$USER_EMAIL" "$USER_FIRSTNAME" "$USER_LASTNAME"
