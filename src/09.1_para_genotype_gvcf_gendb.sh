#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=para_gt_gvcfs
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --gpus-per-node=2
#SBATCH --cpus-per-task=24
#SBATCH --time=01:00:00

# Run with:
# sbatch -a 1-281 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/09.1_para_genotype_gvcf_gendb.sh
# sbatch -a 1-281 --export=project_idx=1 /users/PAS1286/jignacio/projects/pm/src/09.1_para_genotype_gvcf_gendb.sh
# sbatch -a 1-281 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/09.1_para_genotype_gvcf_gendb.sh
# sbatch -a 1-281 --export=project_idx=3 /users/PAS1286/jignacio/projects/pm/src/09.1_para_genotype_gvcf_gendb.sh
# sbatch -a 1-281 --export=project_idx=4 /users/PAS1286/jignacio/projects/pm/src/09.1_para_genotype_gvcf_gendb.sh
# sbatch -a 1-281 --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/09.1_para_genotype_gvcf_gendb.sh
# sbatch -a 1-281 --export=project_idx=6 /users/PAS1286/jignacio/projects/pm/src/09.1_para_genotype_gvcf_gendb.sh
#
# tail logs/genomics_db_import-32401873.err
# sbatch -a 1 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/09.1_para_genotype_gvcf_gendb.sh

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

indir="${homedir}/data/genomicsdb"
outdir="${homedir}/data/09_output_vcf_uncalibrated"
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

# # Prepare the list of BAM files to merge
# inputlist="${projectdir}/uncalibrated_vcf_list.txt"
# ls -d ${indir}/*.vcf.gz > $inputlist
# # Generate INPUT=... syntax for each BAM file
# input_args=$(cat $inputlist | awk '{print "-V " $0}' | sed 's/$/\\/g')

# Load necessary modules
module load gatk/4.4.0.0

tmpdir=/fs/scratch/PAS2444/jignacio/tmp/${SLURM_JOBID}_${SLURM_ARRAY_TASK_ID}
mkdir -p "$tmpdir/tmp"

# Create the output file
output_file="${tmpdir}/uncalibrated_vcf_list.txt"
> $output_file

#chrnum=($(seq -f "%02g" 0 7))
#idx=$(( $SLURM_ARRAY_TASK_ID - 1))
#j=${chrnum[$idx]}
interval_num=$SLURM_ARRAY_TASK_ID
intervals_file="/users/PAS1286/jignacio/projects/pm/data/843B-300-intervals.txt"
source <(aenv --no_sniffer --data "${intervals_file}")
#for j in $(seq -f "%02g" 0 7); do \
gdb=${indir}/interval_${interval_num}_gdb

APPTAINER_IMAGE=/users/PAS1286/jignacio/projects/pm/lib/clara-parabricks_4.3.1-1.sif

apptainer run \
  --nv \
  --bind '/fs:/fs' \
  --bind '/home:/home' \
  --bind '/users:/users' \
  $APPTAINER_IMAGE \
  pbrun genotypegvcf \
    --ref "$ref" \
    --in-gvcf "gendb://$gdb" \
    --out-vcf "${outdir}/interval_${interval_num}.vcf.gz"

# end logging
alog --state end  --exit $?