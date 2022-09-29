**User Provisioning and Strudel v2 Configuration**
==================================================

This document covers user provisioning for the two clusters: QCIF and MeRC.
Deployment and configuration of Strudel v2 is also covered.

## User Provisioning

GeRP uses a new format to record allocations in a human readable yaml file! On the clusters the allocations file is stored in `/mnt/userdata/provisions/config/allocations.yml`. It’s accompanied by `/mnt/userdata/provision/config/config.yml` which tells the  cluster which nodes are responsible for which parts of provisioning. The process is split into two steps, allocating resources and provisioning.

### Allocating Resources

In order to allocate resources you must edit the file called `allocations.yml` in the `gerp-qcif-allocations` or `gerp-merc-allocations` repositories.
- https://gitlab.erc.monash.edu.au/hpc-team/gerp-qcif-allocations
- https://gitlab.erc.monash.edu.au/hpc-team/gerp-merc-allocations

You may edit `allocations.yml` manually, but this is not recommended. Please use the provided python script for doing "default" allocations.

These are explicit instructions assuming you are working on linux with a recent python3 interpreter. Use common sense on git commands. You shouldn't use the example branch name or commit message. Use git pull if you already have a copy etc etc.

1. Obtain a copy of the current allocations and the code to do default allocations
  > git clone git@gitlab.erc.monash.edu.au:hpc-team/gerp-qcif-allocations.git

  > git clone git@gitlab.erc.monash.edu.au:hpc-team/gerp-merc-allocations.git

  > git clone git@gitlab.erc.monash.edu.au:hpc-team/gerp_provisioning.git

  > cd gerp_provisioning

2. Make the allocation (update to gerp-merc-allocations where required).
  > python3 -m allocate --allocations ../gerp-qcif-allocations/allocations.yml --config ../gerp-qcif-allocations/config.yml --email <users email address> -- username <desired username>

3. Push a new branch and merge changes to main branch (update to gerp-merc-allocations where required).
  > cd ../gerp-qcif-allocations

  > git checkout -b "new_allocation"

  > git add allocations.yml

  > git commit -m "I allocated something!"

  > git push origin new_allocation

4. Login to Gitlab and merge the new branch. This will then trigger Gitlab runners to perform two jobs: `provision_authorization` and `provision_cluster`.


### Provisioning

Provisioning is handled automatically by CI (continuous integration) pipelines configured in Gitlab and cronjobs. You shouldn't need to do anything here.

If you need information on this setup:
There is a playbook in the main repository (https://gitlab.erc.monash.edu.au/hpc-team/national-gpu-cluster) that installs the Gitlab runner and configures the cronjobs
  > ansible-playbook -i inventory_$CLUSTER.yml  ./setup_provisioning.yml)

The playbooks requires `var/vars.yml` to contain `gitlab_runner_name` and `var/passwords.yml` to contain `allocations_gitlab_token`. The allocation token is obtained from the Gitlab repository.

The code that performs the provisioning is installed from the repository https://gitlab.erc.monash.edu.au/hpc-team/gerp_provisioning.git
The provision module runs on the login and compute nodes of the cluster, and on the sshauthz server (sshauthz.cloud.cvl.org.au).

The configuration for the provisioning is kept in the two repositories:
  - https://gitlab.erc.monash.edu.au/hpc-team/gerp-qcif-allocations
  - https://gitlab.erc.monash.edu.au/hpc-team/gerp-merc-allocations

The `config.yml` file tells the nodes which parts they should run. The `allocations.yml` file contains all user allocations. `allocations.yml` is maintained by Step 2 under 'Allocation Resources' above.

The repositories `hpc-team/gerp-qcif-allocations.git` and `hpc-team/gerp-merc-allocations.git` both have a `.gitlab-ci.yml` file which tells the nfs server on the cluster and the separate sshauthz server what to do. The nfs server copies the information and a cronjob takes over. The sshauthz server provisions the authorisation information as soon as gitlab-runner detects a change. Setup for sshauthz has been manual (i.e. install the gitlab runner and register manually).


### Debugging

1. Verify that the `allocations.yml` and `config.yml` have been deployed to the cluster NFS server and the sshauthz server.
  - obtain the IP address for the NFS server `inventory_monash.yml` or `inventory_qcif.yml` in this repository.
  - refer to README.md for details on how to login to the cluster.
  - `/mnt/userdata/provisioning/config` contains the files on the cluster.
  - `/opt/provisioning/config` contains the files on sshauthz.cloud.cvl.org.au

2. If the `allocations.yml` and `config.yml` are not current, check the Gitlab repository (gerp-merc-allocations or gerp-qcif-allocations). Ensure they are committed correctly.
3. Check the logs for the pipeline to see what failed.
4. Check out the contents of the cronjob on the login or compute nodes. (e.g. /etc/cron.d/provision_users).
5. Run it manually and see if there are python errors. Do this on login nodes and compute nodes.
6. Repeat on sshauthz


## Strudel v2 Integration

In this example we will add the Monash GeRP cluster to Strudel2 (presented as https://gerp.rc.edu.au) as a second login option.

### Configuring the Certificate Authority

Since we have a different list of users for Monash and QCIF we have a different certificate authority as well.

1. Login to `ubuntu@sshauthz.cloud.cvl.org.au`
2. `cd /opt/pysshauthz/etc`
3. Generate a key without a passphrase: `ssh-keygen -f gerp_monash_ca -t ecdsa`
4. `vim gerp_monash_usermap.yml`, put in your email address and username on GeRP (use ubuntu if you haven't configured any users yet)
5. Verify that gerp_monash_ca has the correct ownership and permissions (look at the other files in the same directory)
6. In the repo national-gpu-cluster: copy `gerp_monash_ca.pub` to `national_gpu_cluster/files_monash/user_ssh_ca.pub`
7. This runs the role `user_ssh_ca` and copies user_ssh_ca.pub to the required nodes on the cluster.
  > ansible-playbook -i inventory_$CLUSTER.yml -t authentication ./master_playbook.yml

8. Run this command to obtain the fingerprint for later use.
  > ssh-keygen -l -f gerp_monash_ca.pub


### Verify the CA is setup correctly

Assuming you've already installed ssossh (https://gitlab.erc.monash.edu.au/hpc-team/ssossh) you should have a file called `.authservers.json` in your home directory or similar.

1. Edit `.authservers.json` Copy an existing block (for example for GeRP qcif)
2. Change the value for 'sign'. It needs to be 'gerp_monash' in between 'sign' and 'api'
  > "sign": "https://sshauthz.cloud.cvl.org.au/pysshauthz/sign/gerp_monash/api/v1/sign_key"

3. Change the value for "name" so it doesn't conflict.
  > "name": "EM Data Processing Portal - MeRC"

4. Change the value for cafingerprint (recorded in step 7 above).
5. Open a new clean terminal window/tab and run `ssossh` and select the new entry.
6. Login. It should work, if not, double check previous steps.
  > ssh username@login node IP address OR DNS

### Install barebones Strudel2 tools on the cluster

    Note that <some shared directory> is `/mnt/userdata/strudel2` for the deployment of GeRP.

1. ssh ubuntu@<login node>
2. sudo mkdir <some shared directory>
3. sudo chown ubuntu <some shared directory>
4. cd <some shared directory>
5. git clone https://gitlab.erc.monash.edu.au/hpc-team/strudel2_cluster.git
6. cd strudel2_cluster/scripts
7. Copy the block that you created in `.authservers.json` in step "Verify the CA is setup correctly".
8. Put it in a file called authinfo.json
9. Run `./make_strudel2_go.sh`
10. Do what make_strudel2_go tells you to do as the last step
11. Download the json file it creates.


### Verifying your barebones Strudel2 Setup

    Note: This step is for testing purposes to ensure the data fields are correct.

1. Open a web browser and go to https://gerp.rc.edu.au
2. DON'T LOGIN
3. select settings -> load config
4. Provide the json file downloaded above
6. A new option should appear for the new cluster, log into this one instead.
7. You should only have the option "account info" and when you click on it it should say "welcome to <login node name>".


### Install applications and create apps.json

    Note: This section is informational as the required tasks are performed under Provisioning above by the playbook setup_provisioning.yml

We need to edit the json file describing GeRP monash to run a command that returns this json data.

For testing its probably best that you set "appCatalogCmd" to "cat ~/.strudel2/apps.json" and make sure you put the apps.json in that directory on the cluster. For production can you either include the json data directly into the appCatalog field, OR you can use the getapps script (installed in gerp qci on /mnt/userdata/strudel/getapps which combines a system wide apps.json with the data in the users home directory. (Note: getapps is installed under Provisioning above by the playbook setup_provisioning.yml)


### Send it to Production

Using the file from step 10, above for ‘Install barebones Strudel2 tools on the cluster’. Below is an example:

```
{
    "authz": [
        {
            "authorise": "https://sshauthz.cloud.cvl.org.au/pysshauthz/oauth2/oauth/authorize/choose",
            "base": "https://sshauthz.cloud.cvl.org.au/pysshauthz/oauth2/",
            "cafingerprint": "SHA256:pmCg",
            "client_id": "Q96kt2",
            "desc": "<div>EM Data Processing Portal - MeRC</div>",
            "icon": null,
            "logout": "https://sshauthz.cloud.cvl.org.au/pysshauthz/oauth2/logout",
            "name": "EM Data Processing Portal - MeRC",
            "scope": "user:email",
            "sign": "https://sshauthz.cloud.cvl.org.au/pysshauthz/sign/gerp_monash/api/v1/sign_key"
        }
    ],
    "computesites": [
        {
            "appCatalog": [
                {
                    "appactions": [],
                    "applist": null,
                    "desc": "<br/>This application runs a VNC server and uses novnc to connect to it<br/>",
                    "instactions": [
                        {
                            "client": {
                                "cmd": null,
                                "redir": "vnc.html?resize=remote&password={password}"
                            },
                            "name": "Connect",
                            "paramscmd": "/mnt/userdata/strudel2/strudel2_cluster/scripts/desktop/params.py {jobid}",
                            "states": [
                                "RUNNING"
                            ]
                        },
                        {
                            "client": {
                                "cmd": null,
                                "redir": "?token={token}"
                            },
                            "name": "View log",
                            "paramscmd": "/mnt/userdata/strudel2/strudel2_cluster/miniconda3/envs/s2_cluster/bin/wstool  cat \"\"",
                            "states": [
                                "RUNNING",
                                "Finished"
                            ]
                        },
                        {
                            "client": {
                                "cmd": null,
                                "redir": "?token={token}"
                            },
                            "name": "View Usage",
                            "paramscmd": "/mnt/userdata/strudel2/strudel2_cluster/miniconda3/envs/s2_cluster/bin/wstool sacct -j {jobid}",
                            "states": [
                                "Finished"
                            ]
                        },
                        {
                            "client": null,
                            "name": "Remove log",
                            "notunnel": true,
                            "paramscmd": "rm  ; echo []",
                            "states": [
                                "Finished"
                            ]
                        }
                    ],
                    "localbind": true,
                    "name": "Desktop",
                    "startscript": "#!/bin/bash\n/mnt/userdata/strudel2/strudel2_cluster/scripts/desktop/start.sh\n ",
                    "url": null
                }
            ],
            "appCatalogCmd": null,
            "cacheturis": [],
            "cafingerprint": "SHA256:pmCgm",
            "cancelcmd": "/mnt/userdata/strudel2/strudel2_cluster/miniconda3/envs/s2_cluster/bin/s2cancel.sh {jobid}",
            "contact": "help@massive.org.au",
            "host": "gerp-monash-login0.gerp.rc.edu.au",
            "name": "GeRP - MeRC",
            "statcmd": "/mnt/userdata/strudel2/strudel2_cluster/miniconda3/envs/s2_cluster/bin/s2stat.sh",
            "submitcmdprefix": "/mnt/userdata/strudel2/strudel2_cluster/miniconda3/envs/s2_cluster/bin/",
            "url": "https://strudel2-api-dev.cloud.cvl.org.au/generic/",
            "userhealth": "/mnt/userdata/strudel2/strudel2_cluster/miniconda3/envs/s2_cluster/bin/uijson"
        }
    ]
}
```


1. Edit: https://gitlab.erc.monash.edu.au/hpc-team/strudelv2_spa/-/blob/gerp/src/deployments/gerp/assets/config/authservers.json
2. Add the above from 'authz' highlighted to authservers.json
3. Edit https://gitlab.erc.monash.edu.au/hpc-team/strudelv2_spa/-/blob/gerp/src/deployments/gerp/assets/config/computesites.json
4. Add the above from 'computesites' highlighted to computesites.json. Ensure you set the "appCatalogCmd": "/mnt/userdata/strudel2/getapps".

```
Note: The two files `authservers.json` and `computesutes.json` effectively split the json file that you've been working with above. 
Note: Changes to gerp branch will automatically deploy to gerp.rc.edu.au due to the configured pipelines on the repository.
```


### Editing the account info

In the `computesites.json` file the field `userhealth` controls what information the `account info` option returns. A barebones example has been provided which returns the welcome message, but we can see from M3 that it can do a lot more including creating tables and highlighting rows in different colours as well as blocks of text etc etc. Getting this right is left as future work ;-)
