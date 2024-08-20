#!/bin/bash
#SBATCH --account=PAS2444
#SBATCH --job-name=gt_gvcfs
#SBATCH --chdir="/users/PAS1286/jignacio/projects/pm"
#SBATCH --output=logs/%x-%A_%a.out
#SBATCH --error=logs/%x-%A_%a.err
#SBATCH --cpus-per-task=2
#SBATCH --time=96:00:00

# Run with:
# sbatch -a 1-281 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh
# sbatch -a 1-281 --export=project_idx=1 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh
# sbatch -a 1-281 --export=project_idx=2 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh
# sbatch -a 1-281 --export=project_idx=3 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh
# sbatch -a 1-281 --export=project_idx=4 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh
# sbatch -a 1-281 --export=project_idx=5 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh
# sbatch -a 1-281 --export=project_idx=6 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh
#
# tail logs/genomics_db_import-32401873.err
# sbatch -a 935 --export=project_idx=0 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh
# sbatch -a 1-935 --export=project_idx=0 --cpus-per-task=2 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh
# failedjobs=277,386-390,392,394,396,398-401,403-410
# sbatch -a 29 --export=project_idx=0 --cpus-per-task=2 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh
# sbatch -a $failedjobs --export=project_idx=0 --cpus-per-task=2 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh
# sbatch -a 412 --export=project_idx=0 --cpus-per-task=2 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh
# failedjobs2=413-421,424,428-434,436-440,442-448,451-455,460-461,463-468,470-471,473-475,478-481,483-484,487,489-497,499,501,503,505-508,510-512,514,516,518-522,525-531,534-535,537-538,540-541,545-548,550,553-561,563-564,566-567,571,575-578,580,582-583,585-586,588-589,592,594-595,598-601,603-604,606-615,618-624,626-631,633-645,648-656,658-662,667-670,674,676-687,689-695,697,699-700,702-704,706-708,710-711,713-718,722,724-732,734-743,745-746,749-750,752-754,756-757,760-764,766,768-769,771-776,778-814,818-843,848-867,874-886,910-913,918-934
# sbatch -a $failedjobs2 --export=project_idx=0 --cpus-per-task=2 /users/PAS1286/jignacio/projects/pm/src/09_genotype_gvcf_gendb.sh

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

indir="${homedir}/data/genomicsdb_935"
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

tmpdir=/fs/scratch/PAS2444/jignacio/tmp/${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}
mkdir -p "$tmpdir/tmp"

# Create the output file
output_file="${tmpdir}/uncalibrated_vcf_list.txt"
> $output_file

#chrnum=($(seq -f "%02g" 0 7))
#idx=$(( $SLURM_ARRAY_TASK_ID - 1))
#j=${chrnum[$idx]}
interval_num=$SLURM_ARRAY_TASK_ID
intervals_file="/users/PAS1286/jignacio/projects/pm/data/843B-2Mbp-intervals.txt"
source <(aenv --no_sniffer --data "${intervals_file}")
#for j in $(seq -f "%02g" 0 7); do \
gdb=${indir}/interval_${interval_num}_gdb
gatk --java-options "-Djava.io.tmpdir=$tmpdir/tmp -Xms${mem} -Xmx${mem} -XX:ParallelGCThreads=$SLURM_CPUS_PER_TASK" GenotypeGVCFs \
  -R "$ref" \
  -V "gendb://$gdb" \
  --tmp-dir "$tmpdir/tmp" \
  -O "${outdir}/interval_${interval_num}.vcf.gz"
  #--max-alternate-alleles 1 \
  #--max-genotype-count 4 \
#done

# end logging
alog --state end  --exit $?