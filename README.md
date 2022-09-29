**National GPU Cluster - GeRP - GPU eResearch Platform**
========================================================

This repository contains the configuration for deploying 2 Slurm clusters inside a single Nectar project/tenancy.

The National GPU Cluster is 2 separate Slurm clusters. Each one based at Monash University and the University of Queensland.

The cluster you use, depends on where your data is located. Globus has(will) been installed to enable movement of your data to the compute.

This service has been configured to provide national access to compute running CryoSPARC. (www.cryosparc.com) To gain access, a user needs to obtain a license key.

`For instructions on user provisioning and Strudel2 configuration, please refer to 'USER_PROVISIONING.md`

## Required NecTAR resources - www.nectar.org.au

In order to deploy this cluster, you require an Nectar project/tennancy with a minimum of hardware.

Suggested machine flavours:
  - t3.xsmall - basion host
  - t3.medium - login host, ideally 2 of these.
  - t3-medium - sql host
  - large machines - compute nodes. The quantity depends on your Requirements

Volume Storage:
  - this could be quite large depending on your requirements. Volume storage is required by the scripts to create 2 volumes.

Advanced Networking:
  - networks: 1 per cluster
  - routers: 1 per cluster
  - floating IPs: 1 per cluster

## Create an new cluster using HPCasCode

HPCasCode is a repository of ansible scripts and a CI/CD pipeline which is used to build the clusters maintained by the Monash eResearch Centre HPC team, M3 and MonARCH. Learn more in the README in the git repository (https://gitlab.erc.monash.edu.au/hpc-team/HPCasCode).

1. Log into your preferred repository:
    - Gitlab: https://gitlab.erc.monash.edu.au/
    - GitHub: https://github.com/
2. Create a new repository in where appropriate.
3. Clone the repository you just created to your local machine. Change into the directory. e.g.
    > cd national-gpu-cluster

4. Add the HPCasCode repository as a submodule (more on submodules https://www.adoclib.com/blog/git-fork-vs-submodules-vs-subtree.html.)
    > git submodule add git@gitlab.erc.monash.edu.au:hpc-team/HPCasCode.git

5. Commit the changes you just made and push them.
    > git add HPCasCode

    > git commit -m "adding submodule"

    > git push origin

6. You’ll need to create some folders and some symlinks to the HPCasCode submodule, and copy some files across too. Choose an appropriate cluster name. e.g. qcif or monash.
    > export CLUSTER=clusterName

    > mkdir files_$CLUSTER

    > mkdir vars_$CLUSTER

    > mkdir plays

    > mkdir ansible-ops

    > cd plays

    > ##we can’t symlink the plays directory. We need each file.

    > ln -s ../HPCasCode/CICD/plays/*.yml .

    > cd ../

    > ln -s ./HPCasCode/CICD/master_playbook.yml  .

    > ln -s ./HPCasCode/CICD/pre_templates .

    > cp ./HPCasCode/CICD/ansible.cfg ./ansible-ops/ansible_$CLUSTER.cfg

    .. note::

        Edit ./ansible-ops/ansible_$CLUSTER.cfg
          –Before
            [ssh_connection]
            ssh_args = -F ./ssh.cfg

          —After
          [ssh_connection]
          ssh_args = -F ./ansible-ops/ssh_clusterName.cfg
          e.g.
          ssh_args = -F ./ansible-ops/ssh_qcif.cfg

    > cp HPCasCode/CICD/infra/os_create.yml os_create_$CLUSTER.yml

    > cp HPCasCode/CICD/infra/os_delete.yml os_delete_$CLUSTER.yml

    > cp HPCasCode/CICD/infra/os_vars.yml.j2 os_vars_$CLUSTER.yml

7. Set up an SSH key for managing the cluster.
    a. You can use the existing keys by copying the cert-authority line in /local_home/ec2-user/.ssh/authorized_keys on m3-login1.
    b. For MLeRP we created new keys and stored them in /local_home/ec2-user/mlerp_keys on m3-login1 - if you create your own just make sure you don’t push them to git or anything crazy (and ask for help if you’re unsure what “crazy” means.)
    c. Copy this line to use when editing the os_vars_$CLUSTER.yml file.

8. Activate a Python environment which contains ansible, python-openstackclient, python-novaclient, joblib and ssossh installed.
    > python3 -m venv python_venv

    > source python_venv/bin/activate

    > pip install ansible python-openstackclient python-novaclient joblib ssossh

9. Now you’ll need to edit the os_vars_$CLUSTER.yml file, paying particular attention to:
    a. *clustername* If the cluster is to be deployed at multiple Nectar sites, consider including the site name as this makes identifying instances easier. e.g. gerp-qcif, gerp-monash.

      .. note::

        If you need to separate the words, use a ‘-’, not ‘_’ as this causes issues with the ansible scripts when trying to setup /etc/hosts on the nodes.

    b. *ssh public key* From step 7, mlerp uses /home/ec2-user/mlerp_keys/adminca.pub
    c. *Ext-network* gerp-qcif uses QRIScloud. To determine the network available to you run:
      > openstack network list

    d. *Availability zone* gerp-qcif uses QRIScloud. To determine the availability zone run:
      > openstack availability zone list

10. Edit os_create_$CLUSTER.yml for the virtual machine flavours you’ll use and adjust the storage sizes accordingly. If required, also adjust the size of the storage volumes to be created. You can find flavours with
  > openstack flavor list

11. Ensure you have access to a NecTAR tenancy and the Openstack RC file, and ensure you have sourced the file before running the following commands. https://tutorials.rc.nectar.org.au/openstack-cli/04-credentials
  > source National_CryoSPARC_Service-openrc.sh

12. Edit the file 'setcluster_gerp.sh' adding support for your selected clusterName. e.g. 'qcif', 'monash'

13. Source setcluster_gerp.sh, to configure your bash session ready for deployment of your cluster. This will setup the required symbolic links that support using a multi cluster deployment of this repository.
  > source setcluster_gerp.sh qcif

14. Run the ansible playbook to create your instances:
  > ansible-playbook os_create_$CLUSTER.yml

15. Create the inventory file which will contain a list of all the VMs you just created
  > python HPCasCode/scripts/make_inventory.py <clusterName> > inventory_$CLUSTER.yml

  > python HPCasCode/scripts/make_inventory.py gerp-qcif > inventory_$CLUSTER.yml

16. Create your own copy of the versions.yml file.
  > cp ./HPCasCode/CICD/vars/versions.yml ./vars_$CLUSTER/versions.yml

17. Using the recently created inventory_$CLUSTER.yml file, create the remaining files.
  > python HPCasCode/CICD/make_files.py inventory_$CLUSTER.yml os_vars_$CLUSTER.yml ./vars_$CLUSTER/versions.yml

  > python HPCasCode/CICD/make_files.py inventory_qcif.yml os_vars_qcif.yml vars_qcif/versions.yml

18. Create a customised ssh.cfg file.
  > mv ssh.cfg ansible-ops/ssh_$CLUSTER.cfg

  ..note ::

    Edit ansible-ops/ssh_$CLUSTER.cfg Update the ‘UserKnownHostsFile’ to this path. e.g  UserKnownHostsFile ./known_hosts_qcif

19. Use ansible vault to encrypt the passwords file. You will need to choose a strong password for this cluster
  > ansible-vault encrypt vars/passwords.yml

20. Use ssossh to authenticate, to login. This part may be optional depending on the key used on step 7.
  > ssossh

21. ssh into the bastion node to ensure everything works as expected. Open the file inventory_$CLUSTER.yml to obtain the allocated IP.
  > ssh -F ansible-ops/ssh_$CLUSTER.cfg ubuntu@192.168.0.XX

22. Ping all your instances to check you can access those too.
  > ansible -i inventory_$CLUSTER.yml -m ping all

23. Complete the symbolic links to the vars and files folders.
  > cd plays ; ln -s ../vars ; ln -s ../files

24. Deploy your cluster. Enjoy!!
  > ansible-playbook -i inventory_$CLUSTER.yml ./master_playbook.yml

Git add, git commit and git push the work you’ve just done to the remote repository!


## Prepare you bash session for maintaining your cluster.

1. Change to folder of your repository.
  > cd national-gpu-cluster

2. Activate your python virtual environment.
  > source python_venv/bin/activate

3. Source your Nectar Openstack RC file.
  > source National_CryoSPARC_Service-openrc.sh

4. Set your cluster. e.g.
  > source setcluster_gerp.sh qcif

Now you are setup and ready to run your Ansible scripts.

## Clone this repository to maintain your cluster.

1. Clone this repository
  > git clone --recurse-submodules https://gitlab.erc.monash.edu.au/hpc-team/national-gpu-cluster.git

2. Change to folder of your repository.
  > cd national-gpu-cluster

3. Create a python virtual enviroment.
  > python3 -m venv python_venv

4. Activate your python virtual environment.
  > source python_venv/bin/activate

5. Install python packages
  > pip install ansible python-openstackclient python-novaclient joblib ssossh

6. Source your Nectar Openstack RC file.
  > source National_CryoSPARC_Service-openrc.sh

7. Set your cluster to 'monash' or 'qcif'
  > source setcluster_gerp.sh qcif
  > source setcluster_gerp.sh monash

8. Sign in as administrator
  > ssossh

Now you are ready to run Ansible to maintain your cluster.

## Redeploying your cluster.

###Warning this is destructive.
###All storage and virtual machines will be deleted/destroyed.

1. Change to folder of your repository.
  > cd national-gpu-cluster

2. Activate your python virtual environment.
  > source python_venv/bin/activate

3. Source your Nectar Openstack RC file.
  > source National_CryoSPARC_Service-openrc.sh

4. Set your cluster. e.g.
  > source setcluster_gerp.sh qcif

5. Destroy the cluster.

  > ansible-playbook os_delete_$CLUSTER.yml

6. Recreate your instances:
  > ansible-playbook os_create_$CLUSTER.yml

7. Recreate the inventory file which will contain a list of all the VMs you just created
  > python HPCasCode/scripts/make_inventory.py <clusterName> > inventory_$CLUSTER.yml

  > python HPCasCode/scripts/make_inventory.py gerp-qcif > inventory_$CLUSTER.yml

8. Recreate the remaining files. The existing passwords file will need to be deleted.
  > rm vars/passwords.yml

  > python HPCasCode/CICD/make_files.py inventory_$CLUSTER.yml os_vars_$CLUSTER.yml ./vars_$CLUSTER/versions.yml

  > python HPCasCode/CICD/make_files.py inventory_qcif.yml os_vars_qcif.yml vars_qcif/versions.yml

9. Recreate the customised ssh.cfg file.
  > vi ansible-ops/ssh_$CLUSTER.cfg

  ..note ::

    Edit ansible-ops/ssh_$CLUSTER.cfg Update the ‘UserKnownHostsFile’ to this path. e.g  UserKnownHostsFile ./known_hosts_qcif. A backup file containing previous settings may be found at 'ansible-ops/ssh_$CLUSTER-BAK.cfg

10. Delete the existing 'known_hosts' file, as this will cause SSH warnings when the new cluster is deployed.
  > rm known_hosts_$CLUSTER

11. The GERP cluster has some special settings required for deployment that are over written by Step 8. Use the '-BAK' files to restore these special settings.
  > cp ansible-ops/gres-BAK.conf files/gres.conf
  > cp ansible-ops/job_container-BAK-$CLUSTER.conf files/job_container.conf
  > cp ansible-ops/mig_config-BAK.yml files/mig_config.yml
  > cp ansible-ops/slurm-BAK-$CLUSTER.conf files/slurm.conf

12. Use ansible vault to encrypt the passwords file. You will need to choose a strong password for this cluster
  > ansible-vault encrypt vars/passwords.yml

13. Use ssossh to authenticate, to login. This part may be optional depending on the key used on step 7, when setting up the cluster originally.
  > ssossh

14. ssh into the bastion node to ensure everything works as expected. Open the file inventory_$CLUSTER.yml to obtain the allocated IP.
  > ssh -F ansible-ops/ssh_$CLUSTER.cfg ubuntu@192.168.0.XX

15. Ping all your instances to check you can access those too.
  > ansible -i inventory_$CLUSTER.yml -m ping all  

16. ReDeploy your cluster. Enjoy!!
  > ansible-playbook -i inventory_$CLUSTER.yml ./master_playbook.yml

Git add, git commit and git push the work you’ve just done to the remote repository!  

## Setup CryoSPARC:

  Ensure the requirements are setup to run CryoSPARC on the cluster.

  > ansible-playbook -i inventory_$CLUSTER.yml  ./cryosparc.yml

## Setup Globus:

  Globus was manually configured. Please refer to the files for details:

  - Globus Install GERP MONASH.txt
  - Globus Install GERP QCIF.txt

## A few sample commands to assist:

  > ansible-playbook -i inventory_$CLUSTER.yml


After updating node settings, slurm may need to be restarted.

  > ansible -i inventory_$CLUSTER.yml -l ComputeNodes -m shell -a "systemctl restart slurmd" all --become

  > ansible -i inventory_$CLUSTER.yml -l LoginNodes -m shell -a "systemctl restart slurmctld" all --become


Destroy all virtual machines and volume storage to redeploy the whole slurm cluster.
  > ansible-playbook os_delete_$CLUSTER.yml
