#!/bin/bash

# designed to run as the user
# determines the hostname, updates cryosparc_master config.sh
# starts cryosparc and then connects workers (lanes)

CRYOSPARC_HOME=/mnt/userdata/$USER/cryosparc

#Update config.sh and start master

#Updating the hostname
cd $CRYOSPARC_HOME/cryosparc_master
sed -i 's/export CRYOSPARC_MASTER_HOSTNAME.*/export CRYOSPARC_MASTER_HOSTNAME='"$HOSTNAME"'/g' config.sh

#Updating the port number in ~/cryosparc.txt
sed -i 's/.*"port":.*/  "port": '"$NEW_BASE_PORT"'/g' ~/cryosparc.txt

#Moving location of cryosparc-supervisor.sock as slurm cleans it up from normal /tmp.
# This also allow access outside of the slurm job
#mkdir tmp
#echo "export CRYOSPARC_SUPERVISOR_SOCK_FILE=/mnt/userdata/$USER/cryosparc/cryosparc_master/tmp/cryosparc-supervisor.sock" >> config.sh

#Updating the port and starting cryosparc
echo "New cryosparc port: $NEW_BASE_PORT"
./bin/cryosparcm changeport $NEW_BASE_PORT --yes

#wait for cryosparc to startup
sleep 20s

# Connect the worker (lanes) to cryosparc master
cd $CRYOSPARC_HOME/cryosparc_worker/

# Connect the worker to the master - 10 GB GPU
cd gerp-cluster-10GB
../../cryosparc_master/bin/cryosparcm cluster connect

sleep 10s

# Connect the worker to the master - 20 GB GPU
cd ../gerp-cluster-20GB
../../cryosparc_master/bin/cryosparcm cluster connect

sleep 10s
