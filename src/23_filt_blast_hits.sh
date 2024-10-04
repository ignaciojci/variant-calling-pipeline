#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=filt_blast_hits
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00

# Run with:
# sbatch -a 1-800 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/23_filt_blast_hits.sh
#
# tail logs/merge_bam-32401873.err

set -u -o pipefail -x

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

indir="${homedir}/data/d20_blast_flanks"
outdir="${homedir}/data/d22_unique_blast_hits"
mkdir -p "$outdir"

# Load necessary modules
module load R/4.4.0-gnu11.2

Rscript "${homedir}/src/23_filt_blast_hits.R" 

# end logging
alog --state end  --exit $?