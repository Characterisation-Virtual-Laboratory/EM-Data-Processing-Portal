#!/bin/bash
. /etc/profile
PATH=/opt/slurm-latest/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
cd /mnt/userdata/provisioning/src/gerp_provisioning
python3 -m provision --allocations ../../config/allocations.yml --config ../../config/config.yml
