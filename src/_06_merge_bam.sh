#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=merge_bam
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A.out
#SBATCH --error=logs/%x-%A.err
#SBATCH --mem=32G
#SBATCH --time=48:00:00

# Run with:
# sbatch --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/06_merge_bam.sh
# sbatch --export=project_idx=1 /users/PAS1286/jignacio/projects/pm/src/06_merge_bam.sh
# sbatch --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/06_merge_bam.sh
# sbatch --export=project_idx=3 /users/PAS1286/jignacio/projects/pm/src/06_merge_bam.sh
# sbatch --export=project_idx=4 /users/PAS1286/jignacio/projects/pm/src/06_merge_bam.sh
# sbatch --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/06_merge_bam.sh
#
# tail logs/merge_bam-32401873.err

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

indir="${projectdir}/bam_with_read_groups"
outdir="${projectdir}/merged"
mkdir -p $outdir

# Prepare the list of BAM files to merge
bamrglist="${projectdir}/bam_with_read_groups_list.txt"
ls -d ${indir}/*.bam > $bamrglist

# Generate INPUT=... syntax for each BAM file
input_args=$(cat $bamrglist | awk '{print "INPUT=" $0}' | tr '\n' ' ')

# Load necessary modules
module load picard

# Merge  files using Picard
java -jar -Xmx32g $PICARD MergeSamFiles \
    $input_args \
    OUTPUT="${outdir}/merged.bam" \
    USE_THREADING=true \
    MAX_RECORDS_IN_RAM=10000000

# # end logging
# alog --state end  --exit $?