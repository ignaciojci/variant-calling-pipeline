#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=vcf_merge_marker_filtered
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A.out
#SBATCH --error=logs/%x-%A.err
#SBATCH --cpus-per-task=14
#SBATCH --time=00:59:00

# Run with:
# sbatch --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/28_merge_marker_filtered_three_vcfs.sh
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

indir="${homedir}/data/27_filter_markers_three_vcfs"
outdir="${homedir}/data/28_filtered_markers_merged_three_vcfs"
mkdir -p $outdir

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

# Load necessary modules
module load java/21.0.2
module load bcftools/1.16

input_files=""
for interval in {1..935}; do
    input_files="${input_files} I=${indir}/interval_${interval}.vcf.gz"
done

outfile=${outdir}/merged.vcf.gz
sortedfile=${outdir}/merged_sorted.vcf.gz

java -jar -Xmx${mem} $PICARD GatherVcfs $input_files O="$outfile" \
  MAX_RECORDS_IN_RAM=20000000

bcftools index -t "$outfile"

bcftools sort "$outfile" -o "$sortedfile" -O z
bcftools index -t "$sortedfile"

# # end logging
# alog --state end  --exit $?