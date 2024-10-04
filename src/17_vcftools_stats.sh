#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=vcftools_stats
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --cpus-per-task=1
#SBATCH --time=00:10:00

# Run with:
# tail logs/genomics_db_import-32401873.err
# sbatch -a 1 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/17_vcftools_stats.sh
# sbatch -a 2-935 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/17_vcftools_stats.sh
# arange -t 2-468 --log mark_dp0_as_missing.log32985220 --summary
# sbatch -a 469-935 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/17_vcftools_stats.sh
# failedjobs=277,386-390,392,394,396,398-401,403-410
# sbatch -a 29 --export=project_idx=0 --cpus-per-task=2 /users/PAS1286/jignacio/projects/pm/src/17_vcftools_stats.sh
# sbatch -a $failedjobs --export=project_idx=0 --cpus-per-task=2 /users/PAS1286/jignacio/projects/pm/src/17_vcftools_stats.sh
# sbatch -a 412 --export=project_idx=0 --cpus-per-task=2 /users/PAS1286/jignacio/projects/pm/src/17_vcftools_stats.sh
# failedjobs2=413-421,424,428-434,436-440,442-448,451-455,460-461,463-468,470-471,473-475,478-481,483-484,487,489-497,499,501,503,505-508,510-512,514,516,518-522,525-531,534-535,537-538,540-541,545-548,550,553-561,563-564,566-567,571,575-578,580,582-583,585-586,588-589,592,594-595,598-601,603-604,606-615,618-624,626-631,633-645,648-656,658-662,667-670,674,676-687,689-695,697,699-700,702-704,706-708,710-711,713-718,722,724-732,734-743,745-746,749-750,752-754,756-757,760-764,766,768-769,771-776,778-814,818-843,848-867,874-886,910-913,918-934
# sbatch -a $failedjobs2 --export=project_idx=0 --cpus-per-task=2 /users/PAS1286/jignacio/projects/pm/src/17_vcftools_stats.sh

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

task_id=$SLURM_ARRAY_TASK_ID

#homedir=/fs/scratch/PAS2444/jignacio/2024/pm/data
indir="${homedir}/data/d15_filtered_high_call_rate_vcf"
outdir="${homedir}/data/d17_filtered_high_call_rate_vcf_stats/interval_${task_id}"
mkdir -p "${outdir}"
cd "$indir"

input=${indir}/interval_${task_id}.vcf.gz

module load vcftools

vcftools --gzvcf "$input" --get-INFO GQ --out "${outdir}/gq_info"
vcftools --gzvcf "$input" --freq --out "${outdir}/maf"
vcftools --gzvcf "$input" --missing-site --out "${outdir}/missing"
vcftools --gzvcf "$input" --hardy --out "${outdir}/hwe"

# end logging
alog --state end  --exit $?