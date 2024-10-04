#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=structure
#SBATCH --chdir=/users/PAS1286/jignacio/projects/pm
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --cpus-per-task=1
#SBATCH --time=48:00:00

# Run using:
# sbatch -a 1-10 /users/PAS1286/jignacio/projects/pm/src/13_run_structure.sh

set -u -o pipefail -x

module load python/2.7-conda5.2

# start logging
alog --state start

task_id=${SLURM_ARRAY_TASK_ID}
k=$task_id
input_dir="/users/PAS1286/jignacio/projects/pm/data/12_merged_vcf/tmp"
input="vcf6_maf0.1"

cd /users/PAS1286/jignacio/projects/pm/data/12_merged_vcf/tmp
mkdir -p "$input"

singularity exec --bind "$HOME:$HOME" --bind "/fs:/fs" \
  /users/PAS1286/jignacio/projects/pm/lib/fs_again.sif \
  /usr/local/bin/python2.7 \
  /users/PAS1286/jignacio/projects/pm/lib/fastStructure/structure.py \
  -K ${k} \
  --input="${input_dir}/${input}" \
  --output="${input_dir}/${input}/${input}"

# singularity exec --bind "$HOME:$HOME" --bind "/fs:/fs" \
#   /users/PAS1286/jignacio/projects/pm/lib/fs_again.sif \
#   /usr/local/bin/python2.7 \
#   /users/PAS1286/jignacio/projects/pm/lib/fastStructure/chooseK.py \
#   --input="${input_dir}/${input}/${input}"


singularity shell --bind "/users:/users" --bind "/fs:/fs" \
  /users/PAS1286/jignacio/projects/pm/lib/fs_again.sif

cd /users/PAS1286/jignacio/projects/pm/data/12_merged_vcf/tmp
pip install matplotlib
input_dir="/users/PAS1286/jignacio/projects/pm/data/12_merged_vcf/tmp"
input="vcf6_maf0.1"

for k in 5 6 7 8 9; do \
/usr/local/bin/python2.7 \
  /users/PAS1286/jignacio/projects/pm/lib/fastStructure/distruct.py \
  -K $k \
  --input="${input_dir}/${input}/${input}" \
  --output="${input_dir}/${input}_structure_k${k}.svg" \
  --popfile="${input_dir}/pop_names_1674.txt"; done



# end logging
alog --state end  --exit $?