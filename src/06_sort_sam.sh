#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=sort_sam
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --cpus-per-task=2
#SBATCH --time=06:00:00

# Run with:
# sbatch -a 1-201 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
# sbatch -a 1-254 --export=project_idx=1 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
# sbatch -a 1-403 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
# sbatch -a 1-309 --export=project_idx=3 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
# sbatch -a 1-15 --export=project_idx=4 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
# sbatch -a 1-662 --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
# sbatch -a 1-859 --export=project_idx=6 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
#
# arange -t 1-201 --log sort_sam.log30679951 --summary
# sbatch -a 1 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
# tail logs/sort_sam-30679204_1.err
# sbatch -a 1-859 --export=project_idx=6 -t 00:10:00 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
# sbatch -a 1 --export=project_idx=6 -t 00:10:00 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
# arange -t 1-254 --log sort_sam.log32405339 --summary
# arange -t 1-15 --log sort_sam.log32417687 
# sbatch -a 516 --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
# arange -t 516 --log sort_sam.log32420819
# sbatch -a 1-515,518-662 --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
# arange -t 1-515,518-662 --log sort_sam.log32434409 --summary
# sbatch -a 234-246 --export=project_idx=5 -t 24:00:00 /users/PAS1286/jignacio/projects/pm/src/06_sort_sam.sh
# arange -t 234-246 --log sort_sam.log32444688 --summary
set -e -u -o pipefail -x

module load python/2.7-conda5.2

# start logging
alog --state start

source /users/PAS1286/jignacio/projects/pm/src/config.sh

if [ -z ${project_idx+0} ]; then
  echo "The environment variable project_idx does not exist or is empty." >&2
else
  echo "The environment variable project_idx exists and its value is: ${project_idx}." >&2
fi

# Define project path
project="${projects[${project_idx}]}"
projectdir="${homedir}/data/${project}"
seq_type="${projects_seq_type[${project_idx}]}"

# Define env variables 'acc' in aenv_src_file
aenv_src_file="${projectdir}/SraAccList.csv.tmp"
aenv_src_file="${projectdir}/SraAccList.csv"
#head -n 3 "${projectdir}/SraAccList.csv" > "${aenv_src_file}"
source <(aenv --no_sniffer --data "${aenv_src_file}")
sample_name="${acc}"

indir="${projectdir}/bam_with_read_groups"
outdir="${projectdir}/sorted"
mkdir -p $outdir

# Load necessary modules
module load picard

# SortSam
# Detect memory
if [ -z ${SLURM_MEM_PER_CPU+0} ]; then
  echo "The environment variable SLURM_MEM_PER_CPU does not exist or is empty." >&2
  if [ -z ${SLURM_MEM_PER_NODE+0} ]; then
    echo "The environment variable SLURM_MEM_PER_NODE does not exist or is empty." >&2
  else
    echo "The environment variable SLURM_MEM_PER_NODE exists and its value is: ${SLURM_MEM_PER_NODE}." >&2
    mem=$SLURM_MEM_PER_NODE
  fi
else
  echo "The environment variable SLURM_MEM_PER_CPU exists and its value is: ${SLURM_MEM_PER_CPU}." >&2
  mempercpu=${SLURM_MEM_PER_CPU%m}
  totalmem=$((mempercpu * $SLURM_CPUS_PER_TASK))
  mem="${totalmem}m"
fi
java -jar -Xmx${mem} $PICARD SortSam \
    I="${indir}/${sample_name}.bam" \
    O="${outdir}/${sample_name}.bam" \
    SORT_ORDER=coordinate

# end logging
alog --state end  --exit $?