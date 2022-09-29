#!/bin/bash

#designed to run as the user, after their account has been created.
#The host and port that cryosparc will run on needs to be predetermined or set
#at runtime as an environment variable.

#This script will install cryosparc master and worker, then shutdown cryosparc.
#When the user is notified that cryosparc has been installed, cryosparc will be
#restarted when they log back in.

start_time="$(date -u +%s)"

if [ "$#" -ne 5 ]; then
    echo "You must enter exactly 5 command line arguments, in this order"
    echo "LICENSE_ID                - obtained from CryoSPARC"
    echo "CRYOSPARC_HOSTNAME_PORT   - e.g. 39000"
    echo "USER_EMAIL                - user's email address"
    echo "USER_FIRSTNAME            - user's firstname"
    echo "USER_LASTNAME             - user's lastname"
    exit 0
fi

LICENSE_ID="$1"
CRYOSPARC_HOSTNAME_PORT="$2"
USER_EMAIL="$3"
USER_FIRSTNAME="$4"
USER_LASTNAME="$5"

CRYOSPARC_HOME=/mnt/userdata/$USER/cryosparc
CRYOSPARC_HOSTNAME=$HOSTNAME
CRYOSPARC_DB_PATH=/mnt/userdata/$USER/cryosparc/cryosparc_database
CUDA_PATH=/usr/local/cuda-11.2/

mkdir $CRYOSPARC_HOME
cd $CRYOSPARC_HOME

if [ -f "cryosparc_master.tar.gz" ]; then
    echo "cryosparc_master.tar.gz exists."
else
    curl -L https://get.cryosparc.com/download/master-latest/$LICENSE_ID -o cryosparc_master.tar.gz
fi

if [ -f "cryosparc_worker.tar.gz" ]; then
    echo "cryosparc_worker.tar.gz exists."
else
    curl -L https://get.cryosparc.com/download/worker-latest/$LICENSE_ID -o cryosparc_worker.tar.gz
fi

tar -zxvf cryosparc_master.tar.gz

cd cryosparc_master
./install.sh --license $LICENSE_ID \
  --hostname $CRYOSPARC_HOSTNAME \
  --dbpath $CRYOSPARC_DB_PATH \
  --port $CRYOSPARC_HOSTNAME_PORT \
  --yes

#Start and add the user
cd $CRYOSPARC_HOME/cryosparc_master
./bin/cryosparcm start
#wait for cryosparc to startup
sleep 30s

# Generate a user password for crosparc and save it at ~/cryosparc.txt
USER_PASSWORD=`tr -cd '[:alnum:]' < /dev/urandom | fold -w30 | head -n1`
cat > ~/cryosparc.txt <<EOF
{
  "license_id": "${LICENSE_ID}",
  "username": "${USER_EMAIL}",
  "password": "${USER_PASSWORD}",
  "port": "${CRYOSPARC_HOSTNAME_PORT}"
}
EOF

./bin/cryosparcm createuser --email "$USER_EMAIL" \
                           --password "$USER_PASSWORD" \
                           --username $USER \
                           --firstname "$USER_FIRSTNAME" \
                           --lastname "$USER_LASTNAME"

# Install the worker
cd $CRYOSPARC_HOME
tar -zxvf cryosparc_worker.tar.gz

cd cryosparc_worker
./install.sh --license $LICENSE_ID \
             --cudapath $CUDA_PATH \
             --yes

# copying gerp-cluster config ('lanes' in CryoSPARC terminology)
cp -r /mnt/userdata/cryosparc_files/gerp-cluster-* /$CRYOSPARC_HOME/cryosparc_worker/
cd $CRYOSPARC_HOME/cryosparc_worker/

# Connect the worker to the master - 10 GB GPU
cd gerp-cluster-10GB
../../cryosparc_master/bin/cryosparcm cluster connect

sleep 10s

# Connect the worker to the master - 20 GB GPU
cd ../gerp-cluster-20GB
../../cryosparc_master/bin/cryosparcm cluster connect

sleep 10s

cd $CRYOSPARC_HOME/cryosparc_master
./bin/cryosparcm stop

sleep 10s

end_time="$(date -u +%s)"

elapsed="$(($end_time-$start_time))"
echo "Total of $elapsed seconds elapsed for process"
