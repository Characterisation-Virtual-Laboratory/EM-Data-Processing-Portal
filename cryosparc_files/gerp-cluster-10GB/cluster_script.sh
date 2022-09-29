#!/bin/bash
#SBATCH --job-name=cryosparc_{{ project_uid }}_{{ job_uid }}
#SBATCH --partition=cryosparc_worker
#SBATCH --output={{ job_log_path_abs }}
#SBATCH --error={{ job_log_path_abs }}
#SBATCH --nodes=1
#SBATCH --mem={{ (ram_gb*1000)|int }}M
#SBATCH --ntasks={{ num_cpu }}
#SBATCH --cpus-per-task=1
#SBATCH --threads-per-core=1
#SBATCH --gres=gpu:2g.10gb:{{ num_gpu }}
#SBATCH --gres-flags=enforce-binding

{{ run_cmd }}
