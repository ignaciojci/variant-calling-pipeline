#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=sort_sam
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A.out
#SBATCH --error=logs/%x-%A.err
#SBATCH --cpus-per-task=4
#SBATCH --time=24:00:00

# Run with:
# sbatch --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/07_sort_sam.sh
# sbatch --export=project_idx=1 /users/PAS1286/jignacio/projects/pm/src/07_sort_sam.sh
# sbatch --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/07_sort_sam.sh
# sbatch --export=project_idx=3 /users/PAS1286/jignacio/projects/pm/src/07_sort_sam.sh
# sbatch --export=project_idx=4 /users/PAS1286/jignacio/projects/pm/src/07_sort_sam.sh
# sbatch --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/07_sort_sam.sh
#
# tail logs/sort_sam-32401999.err
# tail logs/sort_sam-32402000.err

set -e -u -o pipefail -x

# module load python/2.7-conda5.2

# # start logging
# alog --state start

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

indir="${projectdir}/merged"
outdir="${projectdir}/sorted"
mkdir -p $outdir

# Load necessary modules
module load picard

# SortSam
java -jar -Xmx16g $PICARD SortSam \
    I="${indir}/merged.bam" \
    O="${outdir}/sorted.bam" \
    SORT_ORDER=coordinate

# # end logging
# alog --state end  --exit $?