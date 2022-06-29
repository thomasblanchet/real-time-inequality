#!/bin/bash
#SBATCH --job-name=transport 
#SBATCH --mail-type=ALL
#SBATCH --mail-user=thomas.blanchet@berkeley.edu
#SBATCH -o transport.%a.out.txt
#SBATCH -e transport.%a.err.txt
#SBATCH -a 1975-2020%1
python transport.py $SLURM_ARRAY_TASK_ID
