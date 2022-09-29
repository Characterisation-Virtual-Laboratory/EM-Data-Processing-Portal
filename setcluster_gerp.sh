#!/bin/bash

if [ $# -lt 1 ]
then
        echo "Usage : source ./hpc/setcluster_gerp {qcif|monash}"
        exit
fi

case "$1" in

'qcif')  export CLUSTER=$1
    ;;
'monash')  export CLUSTER=$1
    ;;

*) echo "Cluster $1 not recognized exiting"
   return 130
   ;;
esac

[ -L ./ansible.cfg ] && unlink ./ansible.cfg
ln -s ./ansible-ops/ansible_$CLUSTER.cfg ./ansible.cfg

[ -L ./ssh.cfg ] && unlink ./ssh.cfg
ln -s ./ansible-ops/ssh_$CLUSTER.cfg ./ssh.cfg

[ -L ./vars ] && unlink ./vars
[ -d "./vars_$CLUSTER" ] && ln -s ./vars_$CLUSTER ./vars
[ -L ./files ] && unlink ./files
[ -d "./files_$CLUSTER" ] && ln -s ./files_$CLUSTER ./files

[ -L ./os_vars.yml ] && unlink ./os_vars.yml
ln -s ./os_vars_$CLUSTER.yml ./os_vars.yml

#create this file if it does not exist.
export ANSIBLE_VAULT_PASSWORD_FILE=~/.ssh/vaultgerp$CLUSTER
